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

pub fn collection_url(server: String, id: String, rest_limit: String, offset: String) -> String {
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
    let documents = get_document_list(
        server,
        community_handle.as_ref(),
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

pub fn get_document_list<'a, T, U>(
    server: U,
    community_handle: &'a str,
    rest_limit: u32,
    id_selector: T,
) -> Result<Vec<DataspaceDocument>>
where
    T: Fn(U, &'a str) -> Result<Vec<u32>, reqwest::Error>,
    U: Into<String> + Clone + Sync,
{
    let collection_ids = id_selector(server.clone(), community_handle)?;
    let documents = collection_ids
        .par_iter()
        .try_fold(Vec::new, |mut accumulator, collection_id| {
            get_documents_in_collection(
                &mut accumulator,
                server.clone(),
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

fn get_documents_in_collection(
    documents: &mut Vec<DataspaceDocument>,
    server: impl Into<String>,
    collection_id: u32,
    rest_limit: u32,
    offset: u32,
    attempt: u8,
) -> Result<Vec<DataspaceDocument>> {
    let server_string = server.into();
    let url = collection_url(
        server_string.clone(),
        collection_id.to_string(),
        rest_limit.to_string(),
        offset.to_string(),
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
                    server_string.clone(),
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
            server_string,
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
            "https://dataspace-dev.princeton.edu/rest".to_owned(),
            "402".to_owned(),
            "100".to_owned(),
            "1000".to_owned()
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

        let id_selector = |_server, _handle| Ok(vec![361u32]);
        let docs =
            get_document_list(server.url(), "88435/dsp019c67wm88m", 100, id_selector).unwrap();
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
}
