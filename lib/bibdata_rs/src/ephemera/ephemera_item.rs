use serde::{ser::SerializeStruct, Deserialize, Serialize, Serializer};
use std::fs;

#[derive(Deserialize, Debug)]
pub struct EphemeraItem {
    #[serde(rename = "@id")]
    id: String,
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
pub struct ItemResponse {
    pub data: Vec<EphemeraItem>,
}

impl Serialize for EphemeraItem {
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
impl EphemeraItem {
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
    let metadata: EphemeraItem = serde_json::from_str(&data).expect("Unable to parse JSON");
    serde_json::to_string(&metadata).unwrap()
}

#[cfg(test)]
mod tests {
    use crate::{ephemera::CatalogClient, testing_support::preserving_envvar_async};

    use super::*;
    use std::path::PathBuf;

    #[tokio::test]
    async fn test_get_item_data() {
        preserving_envvar_async("FIGGY_BORN_DIGITAL_EPHEMERA_URL", || async {
            let mut server = mockito::Server::new_async().await;
            std::env::set_var("FIGGY_BORN_DIGITAL_EPHEMERA_URL", &server.url());

            let mock = server
                .mock("GET", "/catalog/af4a941d-96a4-463e-9043-cfa512e5eddd")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera1.json")
                .create_async()
                .await;

            let client = CatalogClient::new(server.url());
            let result = client
                .get_item_data("af4a941d-96a4-463e-9043-cfa512e5eddd")
                .await;

            mock.assert_async().await;

            match result {
                Ok(_response) => assert!(true),
                Err(e) => panic!("Request failed: {}", e),
            }
        })
        .await
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
