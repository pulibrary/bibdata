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
    temp_theses_cache_path,
};
use anyhow::{anyhow, Result};
use log::debug;
use magnus::exception;
use rayon::prelude::*;
use serde::Deserialize;

#[derive(Clone, Debug, Default, Deserialize)]
pub struct SearchResponse {
    pub _embedded: SearchEmbedded,
}

#[derive(Clone, Debug, Default, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct SearchEmbedded {
    pub search_result: SearchResult,
}

#[derive(Clone, Debug, Default, Deserialize)]
pub struct SearchResult {
    pub _embedded: ResultEmbedded,
    pub page: Page,
}

#[derive(Clone, Debug, Default, Deserialize)]
pub struct ResultEmbedded {
    pub objects: Vec<Item>,
}

#[derive(Clone, Debug, Default, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Page {
    number: i32,
    total_pages: i32,
}

#[derive(Clone, Debug, Default, Deserialize)]
pub struct Item {
    pub _embedded: ItemEmbedded,
}

#[derive(Clone, Debug, Default, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct ItemEmbedded {
    pub indexable_object: DataspaceDocument,
}

pub fn collection_url(server: &str, scope: &str, page_size: &str, page: &str) -> String {
    format!(
        "{}/discover/search/objects?scope={}&size={}&page={}",
        server, scope, page_size, page
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
    let file = File::create(temp_theses_cache_path())
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

type CollectionIdsSelector = fn(&str, &str) -> Result<Vec<String>>;
pub fn get_document_list(
    server: &str,
    community_id: &str,
    rest_limit: u32,
    ids_selector: CollectionIdsSelector, // a closure that returns a Vec of dspace collection ids
) -> Result<Vec<DataspaceDocument>> {
    let collection_ids = ids_selector(server, community_id)?;
    let documents = collection_ids
        .par_iter()
        .try_fold(Vec::new, |mut accumulator, collection_id| {
            get_documents_in_collection(
                &mut accumulator,
                server,
                collection_id.clone(),
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
    scope: String,
    page_size: u32,
    page: u32,
    attempt: u8,
) -> Result<Vec<DataspaceDocument>> {
    let url = collection_url(server, &scope, &page_size.to_string(), &page.to_string());
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
    let search_response = get_url_as_json(&url);
    let pagination: Page;

    let mut new_documents = match search_response {
        Ok(docs) => {
            pagination = docs.clone()._embedded.search_result.page;
            Ok(map_search_result_to_vec(docs))
        }
        Err(e) => {
            // If there was an error, increment the count of attempts and recurse
            pagination = Page {
                number: 0,
                total_pages: 0,
            };
            if attempt < config::THESES_RETRY_ATTEMPTS {
                get_documents_in_collection(
                    documents,
                    server,
                    scope.clone(),
                    page_size,
                    page,
                    attempt + 1,
                )
            } else {
                Err(e)
            }
        }
    }?;
    if !new_documents.is_empty() {
        documents.append(&mut new_documents);
    }
    // If the current page is not the last page get the next page of documents
    if pagination.number + 1 < pagination.total_pages {
        get_documents_in_collection(documents, server, scope, page_size, page + 1, 0)?;
    }
    Ok(vec![])
}

fn get_url_as_json(url: &str) -> Result<SearchResponse> {
    reqwest::blocking::get(url)?
        .json()
        .map_err(|e| anyhow!("Could not parse json at {url}: {e:?}"))
}

fn map_search_result_to_vec(search_response: SearchResponse) -> Vec<DataspaceDocument> {
    search_response
        ._embedded
        .search_result
        ._embedded
        .objects
        .iter()
        .map(|obj| obj.clone()._embedded.indexable_object)
        .collect()
}

#[cfg(test)]
mod tests {
    use rb_sys_test_helpers::ruby_test;

    use super::*;

    #[test]
    fn it_creates_a_collection_url() {
        assert_eq!(collection_url(
            "https://theses-dissertations.princeton.edu/server/api",
            "d98b1985-fc36-47ce-b11a-62386b505e85",
            "100",
            "10"
        ),
        "https://theses-dissertations.princeton.edu/server/api/discover/search/objects?scope=d98b1985-fc36-47ce-b11a-62386b505e85&size=100&page=10");
    }

    #[test]
    fn it_fetches_the_documents_from_the_community() {
        let mut server = mockito::Server::new();
        let mock_page0 = server
            .mock(
                "GET",
                "/discover/search/objects?scope=ace6dfbf-4f73-4558-acd0-1c4e5fd94baa&size=20&page=0",
            )
            .with_status(200)
            .with_body_from_file("../../spec/fixtures/files/theses/api_client_search.json")
            .create();

        let ids_selector: CollectionIdsSelector = |_server: &str, _handle: &str| {
            Ok(vec!["ace6dfbf-4f73-4558-acd0-1c4e5fd94baa".to_string()])
        };
        let docs = get_document_list(
            &server.url(),
            "c5839e02-b833-4db1-a92f-92a1ffd286b9",
            20,
            ids_selector,
        )
        .unwrap();
        assert_eq!(docs.len(), 20);
        assert_eq!(
            docs[0].title.clone().unwrap(),
            vec![
                "Charging Ahead, Left Behind?\nBalancing Local Labor Market Trade-Offs of Recent U.S. Power Plant Retirements and Renewable Energy Expansion"
                    .to_owned()
            ]
        );

        mock_page0.assert();
    }

    #[test]
    fn requests_past_pagination_limit_return_no_results() {
        let mut server = mockito::Server::new();
        let mock_page1 = server
            .mock(
                "GET",
                "/discover/search/objects?scope=ace6dfbf-4f73-4558-acd0-1c4e5fd94baa&size=20&page=1",
            )
            .with_status(200)
            .with_body_from_file("../../spec/fixtures/files/theses/api_client_search_page_1.json")
            .create();

        let mut docs: Vec<DataspaceDocument> = vec![];
        let _ = get_documents_in_collection(
            &mut docs,
            &server.url(),
            "ace6dfbf-4f73-4558-acd0-1c4e5fd94baa".to_string(),
            20,
            1,
            0,
        );

        assert_eq!(docs.len(), 0);
        mock_page1.assert();
    }

    #[test]
    fn it_retries_requests_when_500_errors() {
        let mut server = mockito::Server::new();
        let mock_page1 = server
            .mock(
                "GET",
                "/discover/search/objects?scope=d98b1985-fc36-47ce-b11a-62386b505e85&size=100&page=0",
            )
            .with_status(500)
            .expect(4) // The initial request + 3 retries
            .create();

        let ids_selector: CollectionIdsSelector = |_server: &str, _handle: &str| {
            Ok(vec!["d98b1985-fc36-47ce-b11a-62386b505e85".to_string()])
        };
        let docs = get_document_list(&server.url(), "88435/dsp019c67wm88m", 100, ids_selector);
        assert!(docs.is_err());

        mock_page1.assert();
    }

    #[ruby_test]
    fn it_notifies_ruby_of_errors() {
        let mut server = mockito::Server::new();
        let mock_bad_response = server
            .mock("GET", "/core/communities/")
            .with_status(500)
            .create();

        assert!(collections_as_solr(server.url(), "88435/dsp019c67wm88m".to_owned(), 100).is_err());
        mock_bad_response.assert();
    }
}
