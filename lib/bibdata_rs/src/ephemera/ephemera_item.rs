use super::{
    ephemera_folder::ephemera_folders_iterator, ephemera_item_builder::EphemeraItemBuilder,
};
use serde::{ser::SerializeStruct, Deserialize, Serialize, Serializer};

#[derive(Deserialize, Debug)]
pub struct EphemeraItem {
    #[serde(rename = "@id")]
    pub id: String,
    pub title: Vec<String>,
    #[serde(rename = "alternative", skip_serializing_if = "Option::is_none")]
    pub alternative_title_display: Option<Vec<String>>,
    #[serde(
        rename = "transliterated_title",
        skip_serializing_if = "Option::is_none"
    )]
    pub transliterated_title_display: Option<Vec<String>>,
    // // creator -> author_display, author, author_s, author_sort, author_roles_1display, author_citation_display
    // #[serde(rename = "creator")]
    // creator: Vec<String>,
}

impl EphemeraItem {
    pub fn builder() -> EphemeraItemBuilder {
        EphemeraItemBuilder::new()
    }
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
    pub fn other_title_display(&self) -> Vec<String> {
        let mut combined = self.alternative_title_display.clone().unwrap_or_default();
        combined.extend(
            self.transliterated_title_display
                .clone()
                .unwrap_or_default(),
        );
        combined
    }
}

pub fn json_ephemera_document(url: String) -> Result<String, magnus::Error> {
    let rt = tokio::runtime::Runtime::new()
        .map_err(|e| magnus::Error::new(magnus::exception::runtime_error(), e.to_string()))?;
    rt.block_on(async {
        let folder_results = ephemera_folders_iterator(&url)
            .await
            .map_err(|e| magnus::Error::new(magnus::exception::runtime_error(), e.to_string()))?;
        let combined_json = folder_results.join(",");
        Ok(combined_json)
    })
}

#[cfg(test)]
mod tests {
    use crate::{
        ephemera::CatalogClient,
        testing_support::{preserving_envvar, preserving_envvar_async},
    };

    use super::*;

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
        preserving_envvar("FIGGY_BORN_DIGITAL_EPHEMERA_URL", || {
            let mut server = mockito::Server::new();

            let folder_mock = server
                .mock("GET", "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%2C+%26+Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera_folders.json")
                .create();

            let item_mock = server
                .mock(
                    "GET",
                    mockito::Matcher::Regex(
                        r"^/catalog/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
                            .to_string(),
                    ),
                )
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera1.json")
                .expect(12)
                .create();

            let result = json_ephemera_document(server.url().to_string()).unwrap();

            let parsed: serde_json::Value = serde_json::from_str(&result).unwrap();
            assert!(parsed.is_array());

            folder_mock.assert();
            item_mock.assert();
        });
    }

    mod no_transliterated_title {
        use std::path::PathBuf;

        use rb_sys_test_helpers::ruby_test;

        use super::*;
        #[ruby_test]
        fn test_json_ephemera_document_with_no_transliterated_title() {
            let mut server = mockito::Server::new();

            let folder_mock = server
                .mock("GET", "/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%2C+%26+Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=")
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file("../../spec/fixtures/files/ephemera/ephemera_folders.json")
                .create();

            let item_mock = server
                .mock(
                    "GET",
                    mockito::Matcher::Regex(
                        r"^/catalog/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$"
                            .to_string(),
                    ),
                )
                .with_status(200)
                .with_header("content-type", "application/json")
                .with_body_from_file(
                    "../../spec/fixtures/files/ephemera/ephemera_no_transliterated_title.json",
                )
                .expect(12)
                .create();

            let result = json_ephemera_document(server.url().to_string()).unwrap();
            let parsed: serde_json::Value = serde_json::from_str(&result).unwrap();
            assert!(parsed.is_array());
            folder_mock.assert();
            item_mock.assert();
        }
    }
}
