use serde::{ser::SerializeStruct, Deserialize, Serialize, Serializer};
use std::fs;

#[derive(Deserialize, Debug)]
pub struct Response {
    pub data: Vec<Item>,
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
pub struct Item {
    id: String,
    attributes: Attributes,
}

pub struct CatalogClient {
    pub url: String,
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

    pub async fn get_data(&self) -> Result<Response, reqwest::Error> {
        let response = reqwest::get(&self.url).await?;
        let data: Response = response.json().await?;
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
    async fn test_get_data() {
        let mock_url = mockito::server_url();
        std::env::set_var("FIGGY_BORN_DIGITAL_EPHEMERA_URL", &mock_url);

        let mock = mock("GET", "/")
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body(r#"{ "data": [] }"#)
            .create();

        let client = CatalogClient::default();
        let result = client.get_data().await;

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
