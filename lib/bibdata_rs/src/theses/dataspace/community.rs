// This module is responsible for interacting with Dataspace communities.
// using the Dataspace JSON API.  Our Dataspace has a single community dedicated
// to senior theses.

use anyhow::{anyhow, Result};
use log::info;
use serde::Deserialize;

#[derive(Debug, Default, Deserialize)]
struct Community {
    pub id: Option<u32>,
    pub handle: String,
}

#[derive(Debug, Default, Deserialize)]
struct Collection {
    pub id: Option<u32>,
}

/// The DSpace id of the community we're fetching content for.
/// E.g., for handle '88435/dsp019c67wm88m', the DSpace id is 267
pub fn get_community_id(server: &str, community_handle: &str) -> Result<Option<u32>> {
    let communities: Vec<Community> =
        reqwest::blocking::get(format!("{}/communities/", server))?.json()?;
    let theses_community = communities
        .iter()
        .find(|community| community.handle == community_handle)
        .ok_or(anyhow!(format!(
            "The senior theses handle {} is not available at {}",
            community_handle, server
        )))?;
    Ok(theses_community.id)
}

pub fn get_collection_list<T>(
    server: &str,
    community_handle: &str,
    id_selector: T, // A closure that returns the ID of the dspace community that contains the collections we need
) -> Result<Vec<u32>>
where
    T: Fn(&str, &str) -> Result<Option<u32>>,
{
    let url = format!(
        "{}/communities/{}/collections",
        server,
        id_selector(server, community_handle)?.unwrap_or_default()
    );
    info!("Querying {} for the collections", url);
    let collections: Vec<Collection> = reqwest::blocking::get(url)?.json()?;
    Ok(collections
        .iter()
        .filter_map(|collection| collection.id)
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_gets_the_id_for_the_theses_community_from_the_api() {
        let mut server = mockito::Server::new();
        let mock = server
            .mock("GET", "/communities/")
            .with_status(200)
            .with_body_from_file("../../spec/fixtures/files/theses/communities.json")
            .create();

        let id = get_community_id(&server.url(), "88435/dsp019c67wm88m")
            .unwrap()
            .unwrap();
        assert_eq!(id, 267);

        mock.assert();
    }

    #[test]
    fn it_returns_error_if_the_api_does_not_return_the_id_for_the_theses_community() {
        let mut server = mockito::Server::new();
        let mock = server
            .mock("GET", "/communities/")
            .with_status(200)
            .with_body(r#"[{"id":1,"handle":"bad-bad-bad"}]"#)
            .create();
        assert!(get_community_id(&server.url(), "88435/dsp019c67wm88m").is_err());
        mock.assert();
    }

    #[test]
    fn it_fetches_the_list_of_collections_in_the_community() {
        let mut server = mockito::Server::new();
        let mock = server
            .mock("GET", "/communities/267/collections")
            .with_status(200)
            .with_body_from_file("../../spec/fixtures/files/theses/api_collections.json")
            .create();

        let id_selector = |_server: &str, _handle: &str| Ok(Some(267u32));
        let ids = get_collection_list(&server.url(), "88435/dsp019c67wm88m", id_selector).unwrap();
        assert_eq!(ids, vec![361]);

        mock.assert();
    }
}
