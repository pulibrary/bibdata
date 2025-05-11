use log::debug;
use magnus::exception;
use crate::theses::{dataspace::{communities, document::DataspaceDocument}, solr::SolrDocument};
use anyhow::Result;

pub fn collection_url(server: String, id: String, rest_limit: String, offset: String) -> String {
    format!(
        "{}/collections/{}/items?limit={}&offset={}&expand=metadata",
        server, id, rest_limit, offset
    )
}


fn magnus_err_from_reqwest_err(value: &reqwest::Error) -> magnus::Error {
    magnus::Error::new(exception::runtime_error(), value.to_string())
}

fn magnus_err_from_serde_err(value: &serde_json::Error) -> magnus::Error {
    magnus::Error::new(exception::runtime_error(), value.to_string())
}

fn magnus_err_from_anyhow_err(value: &anyhow::Error) -> magnus::Error {
    magnus::Error::new(exception::runtime_error(), value.to_string())
}

pub fn collections_as_solr(server: String, community_handle: String, rest_limit: u32) -> Result<String, magnus::Error> {
    let documents =
        get_document_list(
            server,
            community_handle.as_ref(),
            rest_limit,
            |server, handle| communities::get_collection_list(server, handle, communities::get_community_id),
        ).map_err(|e| magnus_err_from_anyhow_err(&e))?;
    Ok(serde_json::to_string(&documents.iter().map(|doc| SolrDocument::from(doc.clone())).collect::<Vec<SolrDocument>>()).map_err(|e| magnus_err_from_serde_err(&e))?)
}

pub fn get_document_list<'a, T, U>(
    server: U,
    community_handle: &'a str,
    rest_limit: u32,
    id_selector: T,
) -> Result<Vec<DataspaceDocument>>
where
    T: Fn(U, &'a str) -> Result<Vec<u32>, reqwest::Error>,
    U: Into<String> + Clone,
{
    // TODO: this should be moved earlier in the process, once it is in Rust
    env_logger::init();
    let collection_ids = id_selector(server.clone(), community_handle)?;
    let mut documents: Vec<DataspaceDocument> = Vec::new();
    for collection_id in collection_ids {
        get_documents_in_collection(&mut documents, server.clone(), collection_id, rest_limit, 0)?;
    }
    
    Ok(documents)
}

fn get_documents_in_collection(documents: &mut Vec<DataspaceDocument>, server: impl Into<String>, collection_id: u32, rest_limit: u32, offset: u32) -> Result<Vec<DataspaceDocument>> {
    let server_string = server.into();
    let url = collection_url(server_string.clone(), collection_id.to_string(), rest_limit.to_string(), offset.to_string());
    debug!("Querying {} for the collections", url);
    let new_documents: Vec<DataspaceDocument> = reqwest::blocking::get(&url)?
        .json()?;
    if !new_documents.is_empty() {
        documents.extend(new_documents);
        get_documents_in_collection(documents, server_string, collection_id, rest_limit, offset + rest_limit)?;
    }
    Ok(vec![])
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
        let mock_page1 = server.mock("GET", "/collections/361/items?limit=100&offset=0&expand=metadata")
        .with_status(200)
        .with_body_from_file("../../spec/fixtures/files/theses/api_client_get.json")
        .create();
        let mock_page2 = server.mock("GET", "/collections/361/items?limit=100&offset=100&expand=metadata")
        .with_status(200)
        .with_body("[]")
        .create();


        let id_selector = |_server, _handle| Ok(vec![361u32]);
        let docs = get_document_list(server.url(), "88435/dsp019c67wm88m", 100, id_selector).unwrap();
        assert_eq!(docs.clone()[0].title.clone().unwrap(), vec!["Calibration of the Princeton University Subsonic Instructional Wind Tunnel".to_owned()]);

        mock_page1.assert();
        mock_page2.assert();
    }
}
