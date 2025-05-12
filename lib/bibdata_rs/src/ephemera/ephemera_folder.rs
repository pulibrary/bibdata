use super::{ephemera_item::ItemResponse, CatalogClient};
use serde::Deserialize;
use std::path::PathBuf;

#[derive(Deserialize, Debug)]
pub struct FolderResponse {
    pub data: Vec<EphemeraFolder>,
}

#[derive(Deserialize, Debug)]
pub struct EphemeraFolder {
    id: String,
    links: Links,
}

#[derive(Deserialize, Debug)]
pub struct Links {
    #[serde(rename = "self")]
    url: String,
}
pub async fn read_ephemera_folders() -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let client = CatalogClient::default();
    let response = client.get_folder_data().await?;

    let ids: Vec<String> = response
        .data
        .into_iter()
        .map(|item| item.links.url)
        .collect();
    Ok(ids)
}

pub async fn ephemera_folders_iterator() -> Result<Vec<Vec<ItemResponse>>, Box<dyn std::error::Error>> {
    let data: Vec<String> = read_ephemera_folders().await?;
    let chunk_size = 1000;
    let mut result: Vec<Vec<ItemResponse>> = Vec::new();
    for chunk in data.chunks(chunk_size) {
      let chunk_vec: Vec<String> = chunk.to_vec().clone();
    // println!("Chunk_vec: {:?}", chunk_vec);
      let responses = chunk_read_url(chunk_vec).await?;
      result.push(responses);
    }
    Ok(result)
}

pub async fn chunk_read_url(urls: Vec<String>) -> Result<Vec<ItemResponse>, Box<dyn std::error::Error>> {
    let mut responses = Vec::new();
    for url in urls {
        let client = CatalogClient { url };
        let response = client.get_item_data().await?;
        responses.push(response);
    }
    Ok(responses)
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    use crate::{
        ephemera::ephemera_folder::read_ephemera_folders, testing_support::preserving_envvar_async,
    };

    #[tokio::test]
    async fn test_read_ephemera_folders() {
        preserving_envvar_async("FIGGY_BORN_DIGITAL_EPHEMERA_URL", || async {
            let mut server = mockito::Server::new_async().await;
            std::env::set_var("FIGGY_BORN_DIGITAL_EPHEMERA_URL", &server.url());

            let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
            d.push("../../spec/fixtures/files/ephemera/ephemera_folders.json");

            let mock = server
                .mock("GET", "/")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file(d.to_string_lossy().to_string())
                .create_async()
                .await;

            let result = read_ephemera_folders().await.unwrap();
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
        preserving_envvar_async("FIGGY_BORN_DIGITAL_EPHEMERA_URL", || async {
            let mut server = mockito::Server::new_async().await;
            std::env::set_var("FIGGY_BORN_DIGITAL_EPHEMERA_URL", &server.url());
            let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
            d.push("../../spec/fixtures/files/ephemera/ephemera_folders.json");
            let mock = server.mock("GET", "/")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file(d.to_string_lossy().to_string())
                .create_async().await;

        let mock1_url = mockito::server_url();
        

        let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        d.push("../../spec/fixtures/files/ephemera/ephemera_folders.json");
        let mock1 = mock("GET", "/")
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body_from_file(d.to_string_lossy().to_string())
            .create();

        let mut d1 = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        d1.push("../../spec/fixtures/files/ephemera/ephemera1.json");
   
        let mock2 = mock("GET", "https://figgy-staging.princeton.edu/catalog/af4a941d-96a4-463e-9043-cfa511e5eddd")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file(d1.to_string_lossy().to_string())
                //.with_body(r#"{ "data": { "id": "test", "attributes": { "title": ["test"] } } }"#)
                .create();
        let data = read_ephemera_folders().await.unwrap();
        let chunk_size = 3;
        let mut result: Vec<Vec<ItemResponse>> = Vec::new();
        for chunk in data.chunks(chunk_size) {
            let chunk_vec: Vec<String> = chunk.to_vec();
            let responses = chunk_read_url(chunk_vec).await.unwrap();
            result.push(responses);
        }  
            // let result = ephemera_folders_iterator().await.unwrap();
            assert!(!result.is_empty());
            // Assuming your ephemera_folders.json has 1 item
            assert_eq!(result.len(), 1); // Total chunks should be 1

            mock1.assert();
            mock2.assert();
        
    }
        }).await;
    }
}
