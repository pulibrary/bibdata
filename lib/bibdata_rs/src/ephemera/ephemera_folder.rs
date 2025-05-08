use std::path::PathBuf;

use mockito::mock;
use serde::Deserialize;

use super::CatalogClient;

#[derive(Deserialize, Debug)]
pub struct FolderResponse {
    pub data: Vec<EphemeraFolder>,
}

#[derive(Deserialize, Debug)]
pub struct EphemeraFolder {
    id: String,
}

pub async fn read_ephemera_folders() -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let client = CatalogClient::default();
    let response = client.get_folder_data().await?;

    let ids: Vec<String> = response.data.into_iter().map(|item| item.id).collect();
    Ok(ids)
}

#[tokio::test]
async fn test_read_ephemera_folders() {
    let mock_url = mockito::server_url();
    std::env::set_var("FIGGY_BORN_DIGITAL_EPHEMERA_URL", &mock_url);

    let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
    d.push("../../spec/fixtures/files/ephemera/ephemera_folders.json");

    let mock = mock("GET", "/")
        .with_status(200)
        .with_header("content-type", "application/json")
        .with_body_from_file(d.to_string_lossy().to_string())
        .create();

    let result = read_ephemera_folders().await.unwrap();
    assert!(!result.is_empty());
    assert!(result.contains(&"33fc03db-3bca-4388-84d3-6b48092199d6".to_string()));
    assert!(result.contains(&"2f555300-9cba-4467-a80c-f8893e9b1379".to_string()));

    mock.assert();
}
