use magnus::{function, prelude::*, Error, Ruby};
use serde::{ser::SerializeStruct, Deserialize, Serialize, Serializer};
use std::fs;

#[derive(Deserialize)]
struct Metadata {
    #[serde(rename = "oai_dc:dc")]
    thesis: Thesis,
}

#[derive(Debug, Deserialize)]
struct Thesis {
    #[serde(rename = "dc:title")]
    title: Vec<String>,
}

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

impl Serialize for Thesis {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        let mut serializer = serializer.serialize_struct("Document", 1)?;
        serializer.serialize_field("title_citation_display", &self.title.first())?;
        serializer.serialize_field("title_display", &self.title.first())?;
        serializer.serialize_field("format", "Senior Thesis")?;
        serializer.end()
    }
}
fn json_ephemera_document(path: String) -> String {
    let data = fs::read_to_string(path).expect("Unable to read file");
    let metadata: Attributes = serde_json::from_str(&data).expect("Unable to parse JSON");
    serde_json::to_string(&metadata).unwrap()
}

fn json_theses_document(path: String) -> String {
    let data = fs::read_to_string(path).expect("Unable to read file");
    let metadata: Metadata = serde_xml_rs::SerdeXml::new()
        .namespace("oai_dc", "http://www.openarchives.org/OAI/2.0/oai_dc/")
        .namespace("dc", "http://purl.org/dc/elements/1.1/")
        .from_str(&data)
        .expect("Unable to parse XML");
    serde_json::to_string(&metadata.thesis).unwrap()
}

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("BibdataRs")?;
    let submodule = module.define_module("Theses")?;
    let submodule_ephemera = submodule.define_module("Ephemera")?;
    submodule.define_singleton_method("json_document", function!(json_theses_document, 1))?;
    submodule_ephemera
        .define_singleton_method("json_document", function!(json_ephemera_document, 1))?;
    Ok(())
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
