// This module is responsible for interacting with Dataspace collections
// using the Dataspace JSON API

use crate::theses::legacy_dataspace::community;
use crate::theses::{
    config, legacy_dataspace::document::DataspaceDocument, temp_legacy_theses_cache_path,
};
use crate::{solr::SolrDocument, theses::errors::ThesesError};
use anyhow::{Result, anyhow};
use log::debug;
use magnus::Ruby;
use rayon::prelude::*;
use std::sync::RwLock;
use std::{
    fs::File,
    io::{BufWriter, Write},
    path::Path,
    sync::Arc,
    sync::Mutex,
};

pub fn collection_url(server: &str, id: &str, rest_limit: &str, offset: &str) -> String {
    format!(
        "{}/collections/{}/items?limit={}&offset={}&expand=metadata",
        server, id, rest_limit, offset
    )
}

fn magnus_err_from_anyhow_err(ruby: &Ruby, value: &anyhow::Error) -> magnus::Error {
    magnus::Error::new(ruby.exception_runtime_error(), value.to_string())
}

// The main function for thesis caching, to be called from Ruby
pub fn legacy_collections_as_solr(
    ruby: &Ruby,
    server: String,
    community_handle: String,
    rest_limit: u32,
) -> Result<(), magnus::Error> {
    let _ = env_logger::try_init();
    let writer = buf_writer(temp_legacy_theses_cache_path()).map_err(|err| err.to_magnus(ruby))?;
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
        .map_err(|value| magnus_err_from_anyhow_err(ruby, &anyhow!(value)))?;
    Ok(())
}

fn buf_writer(path: impl AsRef<Path>) -> Result<BufWriter<impl Write>, ThesesError> {
    let file = File::create(path).map_err(|_| ThesesError::CouldNotOpenFileForWriting)?;
    Ok(BufWriter::new(file))
}

fn write_buffer(writer: &mut BufWriter<impl Write>, buffer: &[u8]) -> Result<(), ThesesError> {
    writer
        .write_all(buffer)
        .map_err(|_| ThesesError::CouldNotWriteToFile)
}

type CollectionIdsSelector = fn(&str, &str) -> Result<Vec<u32>>;

pub fn write_documents(
    server: &str,
    community_handle: &str,
    rest_limit: u32,
    ids_selector: CollectionIdsSelector, // a closure that returns a Vec of dspace collection ids
    writer: Arc<Mutex<BufWriter<impl Write + Send>>>,
    first: Arc<RwLock<bool>>,
) -> Result<()> {
    let collection_ids = ids_selector(server, community_handle)?;
    collection_ids.par_iter().try_for_each(|collection_id| {
        get_documents_in_collection(
            server,
            *collection_id,
            rest_limit,
            0,
            0,
            writer.clone(),
            first.clone(),
        )
    })
}

// This function recursively fetches paginated API results and retries on error
fn get_documents_in_collection(
    server: &str,
    collection_id: u32,
    rest_limit: u32,
    offset: u32,
    attempt: u8,
    writer: Arc<Mutex<BufWriter<impl Write + Send>>>,
    first: Arc<RwLock<bool>>,
) -> Result<()> {
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
        Ok(docs) => docs,
        Err(e) => {
            // If there was an error, increment the count of attempts and recurse
            return if attempt < config::THESES_RETRY_ATTEMPTS {
                get_documents_in_collection(
                    server,
                    collection_id,
                    rest_limit,
                    offset,
                    attempt + 1,
                    writer,
                    first,
                )
            } else {
                Err(e)
            };
        }
    };
    if new_documents.is_empty() {
        Ok(())
    } else {
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
        // If we didn't get an empty JSON, there are still more pages of data to fetch, so
        // recurse with a higher offset (i.e. fetch the next page)
        get_documents_in_collection(
            server,
            collection_id,
            rest_limit,
            offset + rest_limit,
            0,
            writer,
            first,
        )
    }
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
        assert_eq!(
            collection_url(
                "https://dataspace-dev.princeton.edu/rest",
                "402",
                "100",
                "1000"
            ),
            "https://dataspace-dev.princeton.edu/rest/collections/402/items?limit=100&offset=1000&expand=metadata"
        )
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
            .with_body_from_file("../../spec/fixtures/files/theses/api_client_get_legacy.json")
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
        let writer = Arc::new(Mutex::new(BufWriter::new(Vec::new())));

        write_buffer(&mut writer.lock().unwrap(), b"[").unwrap();
        write_documents(
            &server.url(),
            "88435/dsp019c67wm88m",
            100,
            ids_selector,
            Arc::clone(&writer),
            Arc::new(RwLock::new(true)),
        )
        .unwrap();
        write_buffer(&mut writer.lock().unwrap(), b"]").unwrap();

        let docs = docs_from_writer(writer);
        assert_eq!(docs.len(), 1);
        assert_eq!(
            docs[0].title_display.clone().unwrap(),
            "Calibration of the Princeton University Subsonic Instructional Wind Tunnel"
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
            .mock("GET", "/communities/")
            .with_status(500)
            .create();
        let ruby = unsafe { Ruby::get_unchecked() };

        assert!(
            legacy_collections_as_solr(&ruby, server.url(), "88435/dsp019c67wm88m".to_owned(), 100)
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
