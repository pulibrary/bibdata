use super::CatalogClient;
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

pub async fn ephemera_folders_iterator() -> Vec<Vec<String>> {
    let data = read_ephemera_folders().await.unwrap();
    data.chunks(1000)
        .map(|chunk| chunk.to_vec())
        .collect::<Vec<Vec<String>>>()
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;

    use crate::{ephemera::ephemera_folder::read_ephemera_folders, testing_support::preserving_envvar_async};

    #[tokio::test]
    async fn test_read_ephemera_folders() {
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
    
            let result = read_ephemera_folders().await.unwrap();
            assert!(!result.is_empty());
            assert!(result.contains(
                &"https://figgy-staging.princeton.edu/catalog/af4a941d-96a4-463e-9043-cfa511e5eddd"
                    .to_string()
            ));
    
            mock.assert_async().await;
        }).await;

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
    
            let data = read_ephemera_folders().await.unwrap();
            assert!(!data.is_empty());
            let chunk_size = 3;
            let mut result: Vec<Vec<String>> = Vec::new();
            for chunk in data.chunks(chunk_size) {
                result.push(chunk.to_vec());
            }
    
            assert!(!result.is_empty());
            assert_eq!(result.len(), 4); // Total chunks should be 4
            assert_eq!(result[0].len(), 3); // First chunk should have 3 items
            assert_eq!(result[1].len(), 3); // Second chunk should have 3 items
            assert_eq!(result[2].len(), 3); // Third chunk should have 3 items
            assert_eq!(result[3].len(), 3); // Forth chunk should have 3 items
            assert_eq!(
                result[1],
                [
                    "https://figgy-staging.princeton.edu/catalog/602ebba6-1bae-4ba0-9266-0360c27537fe",
                    "https://figgy-staging.princeton.edu/catalog/af4a941d-96a4-463e-9055-cfa512e5eddd",
                    "https://figgy-staging.princeton.edu/catalog/33fc03db-3bca-4388-84gg-6b48092199d6"
                ]
            );
            mock.assert_async().await;
        }).await;
    }
}
