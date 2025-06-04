use crate::solr::SolrDocument;

use super::CatalogClient;
use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct FoldersResponse {
    pub data: Vec<EphemeraFolders>,
}

#[derive(Deserialize, Debug)]
pub struct EphemeraFolders {
    id: String,
    links: Links,
}

#[derive(Deserialize, Debug)]
pub struct Links {
    #[serde(rename = "self")]
    url: String,
}
pub async fn read_ephemera_folders(
    url: impl Into<String>,
) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let client = CatalogClient::new(url.into());
    let response = client.get_folder_data().await?;

    let ids: Vec<String> = response.data.into_iter().map(|item| item.id).collect();
    Ok(ids)
}

pub async fn ephemera_folders_iterator(
    url: &str,
    chunk_size: usize,
) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let data: Vec<String> = read_ephemera_folders(url).await?;
    let mut result: Vec<String> = Vec::new();
    for chunk in data.chunks(chunk_size) {
        let chunk_vec: Vec<String> = chunk.to_vec().clone();
        let responses = chunk_read_id(chunk_vec, url).await?;
        result.push(responses);
    }
    Ok(result)
}

pub async fn chunk_read_id(
    ids: Vec<String>,
    url: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let mut responses = Vec::new();
    for id in ids {
        let client = CatalogClient::new(url.to_owned());
        let response = client.get_item_data(&id).await?;
        responses.push(SolrDocument::from(&response));
    }
    Ok(serde_json::to_string(&responses)?)
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    use crate::{
        ephemera::ephemera_folders::{ephemera_folders_iterator, read_ephemera_folders},
        testing_support::preserving_envvar_async,
    };

    #[ignore]
    #[tokio::test]
    async fn test_read_ephemera_folders() {
        preserving_envvar_async("FIGGY_BORN_DIGITAL_EPHEMERA_URL", || async {
            let mut server = mockito::Server::new_async().await;

            let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
            d.push("../../spec/fixtures/files/ephemera/ephemera_folders.json");
            let path = "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%2C+%26+Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=";
            // let path = std::env::var("FIGGY_BORN_DIGITAL_EPHEMERA_URL").unwrap();
            let mock = server
                .mock("GET", path)
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file(d.to_string_lossy().to_string())
                .create_async()
                .await;

            let result = read_ephemera_folders(server.url()).await.unwrap();
            assert!(!result.is_empty());
            assert!(result.contains(
                &"https://figgy-staging.princeton.edu/catalog/af4a941d-96a4-463e-9043-cfa511e5eddd"
                    .to_string()
            ));

            mock.assert_async().await;
        })
        .await;
    }

    #[tokio::test]
    async fn test_ephemera_folders_iterator() {
        let mut server = mockito::Server::new_async().await;

        let mock1 = server
                .mock("GET", "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%2C+%26+Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera_folders.json")
                .create();

        let mock2 = server
            .mock(
                "GET",
                mockito::Matcher::Regex(
                    r"^/catalog/[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}.jsonld$"
                        .to_string(),
                ),
            )
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera1.json")
            .expect(12)
            .create();

        let chunk_size = 3;

        let result = ephemera_folders_iterator(&server.url(), chunk_size)
            .await
            .unwrap();
        assert!(!result.is_empty());

        assert_eq!(result.len(), 4);

        mock1.assert();
        mock2.assert();
    }
}
