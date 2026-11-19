// This module is responsible for interacting with Dataspace collections
// using the Dataspace JSON API

use std::{
    error::Error,
    fs::File,
    io::{BufWriter, Write},
    path::Path,
    sync::{Arc, Mutex, RwLock},
};

use crate::theses::{
    config,
    dataspace::{community, document::DataspaceDocument},
    temp_theses_cache_path,
};
use crate::{solr::SolrDocument, theses::errors::ThesesError};
use anyhow::{Result, anyhow};
use log::debug;
use magnus::Ruby;
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

#[derive(Clone, Copy, Debug, Default, Deserialize)]
#[serde(rename_all = "camelCase")]
pub struct Page {
    /// The page number (starting from 0)
    number: u32,
    total_pages: u32,
    /// The number of results per page
    size: Option<u32>,
}

impl Page {
    pub fn is_last_page(&self) -> bool {
        self.number >= (self.total_pages - 1)
    }

    pub fn next(&self) -> Self {
        Self {
            number: self.number + 1,
            total_pages: self.total_pages,
            size: self.size,
        }
    }

    pub fn page_size(&self) -> u32 {
        self.size.unwrap_or(100)
    }
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

pub fn collection_url(server: &str, scope: &str, page: Page) -> String {
    format!(
        "{server}/discover/search/objects?scope={scope}&size={}&page={}",
        page.page_size(),
        page.number
    )
}

fn magnus_err_from_anyhow_err(ruby: &Ruby, value: &anyhow::Error) -> magnus::Error {
    magnus::Error::new(ruby.exception_runtime_error(), value.to_string())
}

fn magnus_err(ruby: &Ruby, value: impl Error) -> magnus::Error {
    magnus::Error::new(ruby.exception_runtime_error(), value.to_string())
}

fn buf_writer(path: impl AsRef<Path>) -> Result<BufWriter<impl Write>, ThesesError> {
    let file = File::create(path).map_err(|_| ThesesError::CouldNotOpenFileForWriting)?;
    Ok(BufWriter::new(file))
}

/// Cache theses to a file on disk, to be called from Ruby
pub fn collections_as_solr(
    ruby: &Ruby,
    server: String,
    community_handle: String,
    rest_limit: u32,
) -> Result<(), magnus::Error> {
    let _ = env_logger::try_init();
    let writer = buf_writer(temp_theses_cache_path()).map_err(|err| err.to_magnus(ruby))?;
    let threadsafe_writer = Arc::new(Mutex::new(writer));
    let first = true;

    write_buffer(&mut threadsafe_writer.lock().unwrap(), b"[")
        .map_err(|err| err.to_magnus(ruby))?;
    write_documents(
        &server,
        &community_handle,
        rest_limit,
        |server, handle| {
            community::get_collection_list(server, handle, community::get_community_id)
        },
        Arc::clone(&threadsafe_writer),
        Arc::new(RwLock::new(first)),
    )
    .map_err(|e| magnus_err_from_anyhow_err(ruby, &e))?;
    write_buffer(&mut threadsafe_writer.lock().unwrap(), b"]")
        .map_err(|err| err.to_magnus(ruby))?;
    threadsafe_writer
        .lock()
        .unwrap()
        .flush()
        .map_err(|value| magnus_err(ruby, value))?;
    Ok(())
}

fn write_buffer(writer: &mut BufWriter<impl Write>, buffer: &[u8]) -> Result<(), ThesesError> {
    writer
        .write_all(buffer)
        .map_err(|_| ThesesError::CouldNotWriteToFile)
}

type CollectionIdsSelector = fn(&str, &str) -> Result<Vec<String>>;

pub fn write_documents(
    server: &str,
    community_id: &str,
    rest_limit: u32,
    ids_selector: CollectionIdsSelector, // a closure that returns a Vec of dspace collection ids
    writer: Arc<Mutex<BufWriter<impl Write + Send>>>,
    first: Arc<RwLock<bool>>,
) -> Result<()> {
    let collection_ids = ids_selector(server, community_id)?;
    collection_ids.par_iter().try_for_each(|collection_id| {
        get_documents_in_collection(
            server,
            collection_id,
            Page {
                size: Some(rest_limit),
                ..Default::default()
            },
            0,
            writer.clone(),
            first.clone(),
        )
    })
}

// This function recursively fetches paginated API results and retries on error
fn get_documents_in_collection(
    server: &str,
    scope: &str,
    page: Page,
    attempt: u8,
    writer: Arc<Mutex<BufWriter<impl Write + Send>>>,
    first: Arc<RwLock<bool>>,
) -> Result<()> {
    let url = collection_url(server, scope, page);
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

    let (page, new_documents) = match search_response {
        Ok(docs) => {
            let page = docs.clone()._embedded.search_result.page;
            (page, map_search_result_to_vec(docs))
        }
        Err(e) => {
            // If there was an error, increment the count of attempts and recurse
            return if attempt < config::THESES_RETRY_ATTEMPTS {
                get_documents_in_collection(server, scope, page, attempt + 1, writer, first)
            } else {
                Err(e)
            };
        }
    };
    if !new_documents.is_empty() {
        for document in new_documents {
            let any_documents_written = !*first.read().unwrap();
            let mut writer = writer.lock().unwrap();
            if any_documents_written {
                write_buffer(&mut writer, b",")?;
                serde_json::to_writer_pretty(&mut *writer, &SolrDocument::from(&document))?;
            } else {
                serde_json::to_writer_pretty(&mut *writer, &SolrDocument::from(&document))?;
                let mut first = first.write().unwrap();
                *first = false;
            }
        }
    }
    if !page.is_last_page() {
        get_documents_in_collection(server, scope, page.next(), 0, writer, first)
    } else {
        Ok(())
    }
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
    use super::*;
    use rb_sys_test_helpers::ruby_test;

    #[test]
    fn it_creates_a_collection_url() {
        assert_eq!(
            collection_url(
                "https://theses-dissertations.princeton.edu/server/api",
                "d98b1985-fc36-47ce-b11a-62386b505e85",
                Page {
                    number: 10,
                    ..Default::default()
                }
            ),
            "https://theses-dissertations.princeton.edu/server/api/discover/search/objects?scope=d98b1985-fc36-47ce-b11a-62386b505e85&size=100&page=10"
        );
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
        let writer = Arc::new(Mutex::new(BufWriter::new(Vec::new())));
        write_buffer(&mut writer.lock().unwrap(), b"[").unwrap();
        write_documents(
            &server.url(),
            "c5839e02-b833-4db1-a92f-92a1ffd286b9",
            20,
            ids_selector,
            Arc::clone(&writer),
            Arc::new(RwLock::new(true)),
        )
        .unwrap();
        write_buffer(&mut writer.lock().unwrap(), b"]").unwrap();

        let docs = docs_from_writer(writer);
        assert_eq!(docs.len(), 20);
        assert_eq!(
            docs[0].title_display.clone().unwrap(),
            "Charging Ahead, Left Behind?\nBalancing Local Labor Market Trade-Offs of Recent U.S. Power Plant Retirements and Renewable Energy Expansion"
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

        let writer = Arc::new(Mutex::new(BufWriter::new(Vec::new())));
        write_buffer(&mut writer.lock().unwrap(), b"[").unwrap();
        get_documents_in_collection(
            &server.url(),
            "ace6dfbf-4f73-4558-acd0-1c4e5fd94baa",
            Page {
                size: Some(20),
                number: 1,
                ..Default::default()
            },
            0,
            writer.clone(),
            Arc::new(RwLock::new(true)),
        )
        .unwrap();
        write_buffer(&mut writer.lock().unwrap(), b"]").unwrap();

        let docs = docs_from_writer(writer);
        assert_eq!(docs.len(), 0);
        mock_page1.assert();
    }

    #[test]
    fn it_fetches_all_pages_when_there_are_more_pages() {
        let mut server = mockito::Server::new();
        let mock_page0 = server
            .mock(
                "GET",
                "/discover/search/objects?scope=ace6dfbf-4f73-4558-acd0-1c4e5fd94baa&size=1&page=0",
            )
            .with_status(200)
            .with_body_from_file(
                "../../spec/fixtures/files/theses/api_client_search_multipage_0.json",
            )
            .create();
        let mock_page1 = server
            .mock(
                "GET",
                "/discover/search/objects?scope=ace6dfbf-4f73-4558-acd0-1c4e5fd94baa&size=1&page=1",
            )
            .with_status(200)
            .with_body_from_file(
                "../../spec/fixtures/files/theses/api_client_search_multipage_1.json",
            )
            .create();

        let writer = Arc::new(Mutex::new(BufWriter::new(Vec::new())));
        write_buffer(&mut writer.lock().unwrap(), b"[").unwrap();
        get_documents_in_collection(
            &server.url(),
            "ace6dfbf-4f73-4558-acd0-1c4e5fd94baa",
            Page {
                size: Some(1),
                number: 0,
                ..Default::default()
            },
            0,
            writer.clone(),
            Arc::new(RwLock::new(true)),
        )
        .unwrap();
        write_buffer(&mut writer.lock().unwrap(), b"]").unwrap();

        let docs = docs_from_writer(writer);
        assert_eq!(docs.len(), 2);
        let ids: Vec<_> = docs.iter().map(|doc| doc.id.clone()).collect();
        assert!(ids.contains(&"dsp01multipage1".to_string()));
        assert!(ids.contains(&"dsp01multipage2".to_string()));

        mock_page0.assert();
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
        let writer = Arc::new(Mutex::new(BufWriter::new(Vec::new())));
        let result = write_documents(
            &server.url(),
            "88435/dsp019c67wm88m",
            100,
            ids_selector,
            Arc::clone(&writer),
            Arc::new(RwLock::new(true)),
        );
        assert!(result.is_err());

        mock_page1.assert();
    }

    #[ruby_test]
    fn it_notifies_ruby_of_errors() {
        let mut server = mockito::Server::new();
        let mock_bad_response = server
            .mock("GET", "/core/communities/")
            .with_status(500)
            .create();
        let ruby = unsafe { Ruby::get_unchecked() };

        assert!(
            collections_as_solr(&ruby, server.url(), "88435/dsp019c67wm88m".to_owned(), 100)
                .is_err()
        );
        mock_bad_response.assert();
    }

    fn docs_from_writer(writer: Arc<Mutex<BufWriter<Vec<u8>>>>) -> Vec<SolrDocument> {
        let bytes = Arc::try_unwrap(writer)
            .unwrap()
            .into_inner()
            .unwrap()
            .into_inner()
            .unwrap();
        let content = String::from_utf8(bytes).unwrap();
        serde_json::from_str(&content).unwrap()
    }
}
