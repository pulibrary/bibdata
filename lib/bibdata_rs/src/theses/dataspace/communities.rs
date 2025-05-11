use magnus::exception;
use serde::Deserialize;

#[derive(Debug, Default, Deserialize)]
pub struct Community {
    pub id: Option<u32>,
    pub handle: String
}


fn magnus_err_from_reqwest_err(value: &reqwest::Error) -> magnus::Error {
    magnus::Error::new(exception::runtime_error(), value.to_string())
}

pub fn delete_me_api_collection_ids_for_magnus(server: String, community_handle: String) -> Result<Option<u32>, magnus::Error> {
    get_collection_ids(server, community_handle.as_ref()).map_err( |value| magnus::Error::new(exception::runtime_error(), value.to_string()))
}

/// The DSpace id of the community we're fetching content for.
/// E.g., for handle '88435/dsp019c67wm88m', the DSpace id is 267
pub fn get_collection_ids(server: impl Into<String>, community_handle: &str) -> Result<Option<u32>, reqwest::Error> {
    let communities: Vec<Community> = reqwest::blocking::get(format!("{}/communities/", server.into()))?
        .json()?;
    let theses_community = communities.iter().find(|community| community.handle == community_handle );
    // TODO!  Handle the case in which the json does not contain the community handle
    Ok(theses_community.unwrap().id)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_gets_the_id_for_the_theses_community_from_the_api() {
        let mut server = mockito::Server::new();
        let mock = server.mock("GET", "/communities/")
            .with_status(200)
            .with_body_from_file("../../spec/fixtures/files/theses/communities.json")
            .create();

        let id = get_collection_ids(server.url(), "88435/dsp019c67wm88m").unwrap().unwrap();
        assert_eq!(id, 267);

        mock.assert();
    }
}
