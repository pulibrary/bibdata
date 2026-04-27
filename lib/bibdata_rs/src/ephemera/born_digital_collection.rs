use super::CatalogClient;
use crate::solr::SolrDocument;
use serde::Deserialize;

#[derive(Deserialize, Debug)]
pub struct FoldersResponse {
    pub data: Vec<BornDigitalCollection>,
    pub meta: Option<Meta>,
}

#[derive(Deserialize, Debug)]
pub struct Meta {
    pub pages: Pages,
}

#[derive(Deserialize, Debug)]
pub struct Pages {
    // pub current_page: Option<u32>,
    // pub next_page: Option<u32>,
    // pub prev_page: Option<u32>,
    pub total_pages: u32,
    // pub limit_value: Option<u32>,
    // pub offset_value: Option<u32>,
    // pub total_count: Option<u32>,
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
pub struct BornDigitalCollection {
    id: String,
    links: Links,
}

#[allow(dead_code)]
#[derive(Deserialize, Debug)]
pub struct Links {
    #[serde(rename = "self")]
    url: String,
}
pub async fn read_ephemera_folders(
    url: impl Into<String>,
) -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let client = CatalogClient::new(url.into());

    let mut all_ids: Vec<String> = Vec::new();
    let mut page_number = 1;
    // call the first page page=1 to get the responce meta info, total_pages etc.
    let response = client.get_folder_data(page_number).await?;
    let total_pages = response
        .meta
        .as_ref()
        .map(|m| m.pages.total_pages)
        .unwrap_or(1);

    all_ids.extend(response.data.into_iter().map(|item| item.id));

    while page_number < total_pages {
        page_number += 1;

        let response = client.get_folder_data(page_number).await?;
        all_ids.extend(response.data.into_iter().map(|item| item.id));
    }
    Ok(all_ids)
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
        let mut response = client.get_item_data(&id).await?;
        if let Ok(thumbnail) = response.fetch_thumbnail(url, &id).await {
            response.thumbnail = thumbnail;
        }
        responses.push(SolrDocument::from(&response));
    }
    Ok(serde_json::to_string(&responses)?)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    use crate::{
        ephemera::born_digital_collection::{ephemera_folders_iterator, read_ephemera_folders},
        testing_support::preserving_envvar_async,
    };

    #[ignore]
    #[tokio::test]
    async fn test_read_ephemera_folders() {
        preserving_envvar_async("FIGGY_BORN_DIGITAL_EPHEMERA_URL", || async {
            let mut server = mockito::Server::new_async().await;

            // fixture for page 1
            let mut d1 = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
            d1.push("../../spec/fixtures/files/ephemera/ephemera_folders.json");
            // fixture for page 2 
            let mut d2 = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
            d2.push("../../spec/fixtures/files/ephemera/ephemera_folders_page2.json");

            let mock1 = server
                .mock("GET", "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographic+Reports+and+Papers&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&page=1&q=")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file(d1.to_string_lossy().to_string())
                .create_async()
                .await;

            let mock2 = server
                .mock("GET", "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographic+Reports+and+Papers&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&page=2&q=")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file(d2.to_string_lossy().to_string())
                .create_async()
                .await;

            let result = read_ephemera_folders(server.url()).await.unwrap();
            assert!(!result.is_empty());
            // Id from fixture page 1
            assert!(result.contains(&"https://figgy-staging.princeton.edu/catalog/af4a941d-96a4-463e-9043-cfa511e5eddd".to_string()));
            // Id from fixture page 2
            assert!(result.contains(&"https://figgy-staging.princeton.edu/catalog/5d4305d2-8650-46fa-9849-d6ea7775b38b".to_string()));

            mock1.assert_async().await;
            mock2.assert_async().await;
        })
        .await;
    }

    #[tokio::test]
    async fn test_ephemera_folders_iterator() {
        let mut server = mockito::Server::new_async().await;

        let mock1 = server
                .mock("GET", "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographic+Reports+and+Papers&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&page=1&q=")
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
    #[tokio::test]
    async fn test_chunk_read_id_sets_thumbnail() {
        // Setup mock server and data
        let mut server = mockito::Server::new_async().await;
        let test_id = "af4a941d-96a4-463e-9043-cfa511e5eddd";
        let test_url = server.url();

        // Mock get_item_data response
        let item_data_path = "../../spec/fixtures/files/ephemera/ephemera1.json";
        let _mock_item = server
            .mock(
                "GET",
                "/catalog/af4a941d-96a4-463e-9043-cfa511e5eddd.jsonld",
            )
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body_from_file(item_data_path)
            .create();

        // Mock manifest response with thumbnail
        let manifest_json = r#"{
            "thumbnail": { "@id": "https://example.com/thumbnail.jpg" }
        }"#;
        let _mock_manifest = server
            .mock(
                "GET",
                "/concern/ephemera_folders/af4a941d-96a4-463e-9043-cfa511e5eddd/manifest",
            )
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body(manifest_json)
            .create();

        // Call chunk_read_id
        let ids = vec![test_id.to_string()];
        let result_json = chunk_read_id(ids, &test_url).await.unwrap();

        // Check that the thumbnail URL is present in the result
        assert!(
            result_json.contains("https://example.com/thumbnail.jpg"),
            "Thumbnail URL should be present in the serialized response"
        );
    }
}
