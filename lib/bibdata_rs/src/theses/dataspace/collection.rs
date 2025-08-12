// This module is responsible for interacting with Dataspace collections
// using the Dataspace JSON API

use std::{
    fs::File,
    io::{BufWriter, Write},
};

use crate::solr::SolrDocument;
use crate::theses::{
    config,
    dataspace::{community, document::DataspaceDocument},
    theses_cache_path,
};
use anyhow::{anyhow, Result};
use log::debug;
use magnus::exception;
use rayon::prelude::*;

pub fn collection_url(server: &str, id: &str, rest_limit: &str, offset: &str) -> String {
    format!(
        "{}/collections/{}/items?limit={}&offset={}&expand=metadata",
        server, id, rest_limit, offset
    )
}

fn magnus_err_from_serde_err(value: &serde_json::Error) -> magnus::Error {
    magnus::Error::new(exception::runtime_error(), value.to_string())
}

fn magnus_err_from_anyhow_err(value: &anyhow::Error) -> magnus::Error {
    magnus::Error::new(exception::runtime_error(), value.to_string())
}

// The main function for thesis caching, to be called from Ruby
pub fn collections_as_solr(
    server: String,
    community_handle: String,
    rest_limit: u32,
) -> Result<(), magnus::Error> {
    env_logger::init();
    let documents: Vec<DataspaceDocument> =
        get_document_list(&server, &community_handle, rest_limit, |server, handle| {
            community::get_collection_list(server, handle, community::get_community_id)
        })
        .map_err(|e| magnus_err_from_anyhow_err(&e))?;
    let file = File::create(theses_cache_path())
        .map_err(|value| magnus_err_from_anyhow_err(&anyhow!(value)))?;
    let mut writer = BufWriter::new(file);
    serde_json::to_writer_pretty(
        &mut writer,
        &documents
            .iter()
            .map(SolrDocument::from)
            .collect::<Vec<SolrDocument>>(),
    )
    .map_err(|e| magnus_err_from_serde_err(&e))?;
    writer
        .flush()
        .map_err(|value| magnus_err_from_anyhow_err(&anyhow!(value)))?;
    Ok(())
}

type CollectionIdsSelector = fn(&str, &str) -> Result<Vec<u32>>;
pub fn get_document_list(
    server: &str,
    community_handle: &str,
    rest_limit: u32,
    ids_selector: CollectionIdsSelector, // a closure that returns a Vec of dspace collection ids
) -> Result<Vec<DataspaceDocument>> {
    let collection_ids = ids_selector(server, community_handle)?;
    let documents = collection_ids
        .par_iter()
        .try_fold(Vec::new, |mut accumulator, collection_id| {
            get_documents_in_collection(
                &mut accumulator,
                server,
                *collection_id,
                rest_limit,
                0,
                0,
            )?;
            Ok::<Vec<DataspaceDocument>, anyhow::Error>(accumulator)
        })
        .try_reduce(Vec::new, |mut a, b| {
            a.extend(b);
            Ok(a)
        })?;

    Ok(documents)
}

// This function recursively fetches paginated API results and retries on error
fn get_documents_in_collection(
    documents: &mut Vec<DataspaceDocument>,
    server: &str,
    collection_id: u32,
    rest_limit: u32,
    offset: u32,
    attempt: u8,
) -> Result<Vec<DataspaceDocument>> {
    let url = collection_url(
        server,
        &collection_id.to_string(),
        &rest_limit.to_string(),
        &offset.to_string(),
    );
    if attempt == 0 {
        debug!("Querying for the DSpace Collection at {}", url)
    } else {
        debug!(
            "Retrying query {}, attempt {} of {}",
            url,
            attempt,
            config::THESES_RETRY_ATTEMPTS
        );
    }
    let new_documents = match get_url_as_json(&url) {
        Ok(docs) => Ok(docs),
        Err(e) => {
            // If there was an error, increment the count of attempts and recurse
            if attempt < config::THESES_RETRY_ATTEMPTS {
                get_documents_in_collection(
                    documents,
                    server,
                    collection_id,
                    rest_limit,
                    offset,
                    attempt + 1,
                )
            } else {
                Err(e)
            }
        }
    }?;
    // If we didn't get an empty JSON, there are still more pages of data to fetch, so
    // recurse with a higher offset (i.e. fetch the next page)
    if !new_documents.is_empty() {
        documents.extend(new_documents);
        get_documents_in_collection(
            documents,
            server,
            collection_id,
            rest_limit,
            offset + rest_limit,
            0,
        )?;
    }
    Ok(vec![])
}

fn get_url_as_json(url: &str) -> Result<Vec<DataspaceDocument>> {
    reqwest::blocking::get(url)?
        .json()
        .map_err(|e| anyhow!("Could not parse json at {url}: {e:?}"))
}

#[cfg(test)]
mod tests {
    use rb_sys_test_helpers::ruby_test;

    use super::*;

    #[test]
    fn it_creates_a_collection_url() {
        assert_eq!(collection_url(
            "https://dataspace-dev.princeton.edu/rest",
            "402",
            "100",
            "1000"
        ),
    "https://dataspace-dev.princeton.edu/rest/collections/402/items?limit=100&offset=1000&expand=metadata")
    }

    #[test]
    fn it_fetches_the_documents_from_the_community() {
        let mut server = mockito::Server::new();
        let mock_page1 = server
            .mock(
                "GET",
                "/collections/361/items?limit=100&offset=0&expand=metadata",
            )
            .with_status(200)
            .with_body_from_file("../../spec/fixtures/files/theses/api_client_get.json")
            .create();
        let mock_page2 = server
            .mock(
                "GET",
                "/collections/361/items?limit=100&offset=100&expand=metadata",
            )
            .with_status(200)
            .with_body("[]")
            .create();

        let ids_selector: CollectionIdsSelector = |_server: &str, _handle: &str| Ok(vec![361u32]);
        let docs =
            get_document_list(&server.url(), "88435/dsp019c67wm88m", 100, ids_selector).unwrap();
        assert_eq!(docs.len(), 1);
        assert_eq!(
            docs[0].title.clone().unwrap(),
            vec![
                "Calibration of the Princeton University Subsonic Instructional Wind Tunnel"
                    .to_owned()
            ]
        );

        mock_page1.assert();
        mock_page2.assert();
    }

    #[test]
    fn it_retries_requests_when_500_errors() {
        let mut server = mockito::Server::new();
        let mock_page1 = server
            .mock(
                "GET",
                "/collections/361/items?limit=100&offset=0&expand=metadata",
            )
            .with_status(500)
            .expect(4) // The initial request + 3 retries
            .create();

        let ids_selector: CollectionIdsSelector = |_server: &str, _handle: &str| Ok(vec![361u32]);
        let docs = get_document_list(&server.url(), "88435/dsp019c67wm88m", 100, ids_selector);
        assert!(docs.is_err());

        mock_page1.assert();
    }

    #[ruby_test]
    fn it_notifies_ruby_of_errors() {
        let mut server = mockito::Server::new();
        let mock_bad_response = server
            .mock("GET", "/communities/")
            .with_status(500)
            .create();

        assert!(collections_as_solr(server.url(), "88435/dsp019c67wm88m".to_owned(), 100).is_err());
        mock_bad_response.assert();
    }
}
