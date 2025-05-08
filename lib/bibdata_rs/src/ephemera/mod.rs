use serde::{ser::SerializeStruct, Deserialize, Serialize, Serializer};
use std::fs;

#[derive(Deserialize, Debug)]
pub struct ItemResponse {
    pub data: Vec<EphemeraItem>,
}

#[derive(Deserialize, Debug)]
pub struct FolderResponse {
    pub data: Vec<EphemeraFolder>,
}

#[derive(Deserialize, Debug)]
pub struct Attributes {
    title: Vec<String>,
    #[serde(rename = "alternative", skip_serializing_if = "Option::is_none")]
    alternative_title_display: Option<Vec<String>>,
    #[serde(
        rename = "transliterated_title",
        skip_serializing_if = "Option::is_none"
    )]
    transliterated_title_display: Option<Vec<String>>,
    // // creator -> author_display, author, author_s, author_sort, author_roles_1display, author_citation_display
    // #[serde(rename = "creator")]
    // creator: Vec<String>,
}

#[derive(Deserialize, Debug)]
pub struct EphemeraItem {
    id: String,
    attributes: Attributes,
}

#[derive(Deserialize, Debug)]
pub struct EphemeraFolder {
    id: String,
}

pub struct CatalogClient {
    url: String,
}

impl Default for CatalogClient {
    fn default() -> Self {
        Self::new()
    }
}

impl CatalogClient {
    pub fn new() -> Self {
        let figgy_ephemera_url = std::env::var("FIGGY_BORN_DIGITAL_EPHEMERA_URL");
        CatalogClient {
            url: figgy_ephemera_url.unwrap(),
        }
    }

    pub async fn get_item_data(&self) -> Result<ItemResponse, reqwest::Error> {
        let response = reqwest::get(&self.url).await?;
        let data: ItemResponse = response.json().await?;
        Ok(data)
    }

    pub async fn get_folder_data(&self) -> Result<FolderResponse, reqwest::Error> {
        let response = reqwest::get(&self.url).await?;
        let data: FolderResponse = response.json().await?;
        Ok(data)
    }
}

impl Serialize for Attributes {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut serializer = serializer.serialize_struct("Attributes", 5)?;
        serializer.serialize_field("title_display", &self.title.first())?;
        serializer.serialize_field("title_citation_display", &self.title)?;
        serializer.serialize_field("other_title_display", &self.other_title_display())?;
        serializer.end()
    }
}
impl Attributes {
    fn other_title_display(&self) -> Vec<String> {
        let mut combined = self.alternative_title_display.clone().unwrap_or_default();
        combined.extend(
            self.transliterated_title_display
                .clone()
                .unwrap_or_default(),
        );
        combined
    }
}
pub async fn read_ephemera_folders() -> Result<Vec<String>, Box<dyn std::error::Error>> {
    let client = CatalogClient::default();
    let response = client.get_folder_data().await?;

    let ids: Vec<String> = response.data.into_iter().map(|item| item.id).collect();
    Ok(ids)
}

pub fn json_ephemera_document(path: String) -> String {
    let data = fs::read_to_string(path).expect("Unable to read file");
    let metadata: Attributes = serde_json::from_str(&data).expect("Unable to parse JSON");
    serde_json::to_string(&metadata).unwrap()
}

#[cfg(test)]
mod tests {
    use super::*;
    use mockito::mock;
    use std::path::PathBuf;

    #[tokio::test]
    async fn test_get_item_data() {
        let mock_url = mockito::server_url();
        std::env::set_var("FIGGY_BORN_DIGITAL_EPHEMERA_URL", &mock_url);

        let mock = mock("GET", "/")
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body(r#"{ "data": [] }"#)
            .create();

        let client = CatalogClient::default();
        let result = client.get_item_data().await;

        mock.assert();

        match result {
            Ok(_response) => assert!(true),
            Err(e) => panic!("Request failed: {}", e),
        }
    }

    #[test]
    fn test_json_ephemera_document() {
        let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));

        d.push("../../spec/fixtures/files/ephemera/ephemera1.json");

        let result = json_ephemera_document(d.to_string_lossy().to_string());
        assert_eq!(result, "{\"title_display\":\"Of technique : chance procedures on turntable : a book of essays & illustrations\",\"title_citation_display\":[\"Of technique : chance procedures on turntable : a book of essays & illustrations\"],\"other_title_display\":[\"Chance procedures on turntable\",\"custom transliterated title\"]}");
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

    mod no_transliterated_title {
        use super::*;
        #[test]
        fn test_json_ephemera_document() {
            let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));

            d.push("../../spec/fixtures/files/ephemera/ephemera_no_transliterated_title.json");

            let result = json_ephemera_document(d.to_string_lossy().to_string());
            assert_eq!(result, "{\"title_display\":\"Of technique : chance procedures on turntable : a book of essays & illustrations\",\"title_citation_display\":[\"Of technique : chance procedures on turntable : a book of essays & illustrations\"],\"other_title_display\":[\"Chance procedures on turntable\"]}");
        }
    }
}
