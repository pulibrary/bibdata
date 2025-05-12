// This module is responsible for interacting with Dataspace collections
// using the Dataspace JSON API

use std::{
    fs::File,
    io::{BufWriter, Write},
};

use crate::theses::{
    config,
    dataspace::{community, document::DataspaceDocument},
    solr::SolrDocument,
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

pub fn collections_as_solr(
    server: String,
    community_handle: String,
    rest_limit: u32,
) -> Result<(), magnus::Error> {
    env_logger::init();
    let documents: Vec<DataspaceDocument> = get_document_list(
        &server,
        &community_handle,
        rest_limit,
        |server, handle| {
            community::get_collection_list(server, handle, community::get_community_id)
        },
    )
    .map_err(|e| magnus_err_from_anyhow_err(&e))?;
    let file = File::create(theses_cache_path())
        .map_err(|value| magnus_err_from_anyhow_err(&anyhow!(value)))?;
    let mut writer = BufWriter::new(file);
    serde_json::to_writer_pretty(
        &mut writer,
        &documents
            .par_iter()
            .map(|doc| SolrDocument::from(doc.clone()))
            .collect::<Vec<SolrDocument>>(),
    )
    .map_err(|e| magnus_err_from_serde_err(&e))?;
    writer
        .flush()
        .map_err(|value| magnus_err_from_anyhow_err(&anyhow!(value)))?;
    Ok(())
}

pub fn get_document_list<T>(
    server: &str,
    community_handle: &str,
    rest_limit: u32,
    id_selector: T,
) -> Result<Vec<DataspaceDocument>>
where
    T: Fn(&str, &str) -> Result<Vec<u32>, reqwest::Error>,
{
    let collection_ids = id_selector(server, community_handle)?;
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
    reqwest::blocking::get(url)?.json().map_err(|e| anyhow!(e))
}

#[cfg(test)]
mod tests {
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

        let id_selector = |_server: &str, _handle: &str| Ok(vec![361u32]);
        let docs =
            get_document_list(&server.url(), "88435/dsp019c67wm88m", 100, id_selector).unwrap();
        assert_eq!(docs.len(), 1);
        assert_eq!(
            docs.clone()[0].title.clone().unwrap(),
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

        let id_selector = |_server: &str, _handle: &str| Ok(vec![361u32]);
        let docs =
            get_document_list(&server.url(), "88435/dsp019c67wm88m", 100, id_selector);
        assert!(docs.is_err());

        mock_page1.assert();
    }
}
