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
    // alternative -> other_title_display
    // #[serde(rename = "transliterated_title")]
    // pub other_title_display: Vec<String>,
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
        let figgy_ephemera_url = std::env::var("FIGGY_BORN_DIGITAL_EPHEMERA_URL").ok();
        CatalogClient {
            url: figgy_ephemera_url.unwrap()
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
        let mut serializer = serializer.serialize_struct("Attributes", 1)?;
        serializer.serialize_field("title_display", &self.title.first())?;
        serializer.serialize_field("title_citation_display", &self.title.first())?;
        serializer.end()
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
    submodule_ephemera.define_singleton_method("json_document", function!(json_ephemera_document, 1))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use std::path::PathBuf;
    use super::*;

    #[tokio::test]
    async fn test_get_data() {
        std::env::set_var("FIGGY_BORN_DIGITAL_EPHEMERA_URL", "https://figgy-staging.princeton.edu/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%26Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=");
        let client = CatalogClient::default();
        let result = client.get_data().await;
        assert!(result.is_ok());
    }

    #[test]
    fn test_json_ephemera_document() {
        let mut d = PathBuf::from(env!("CARGO_MANIFEST_DIR"));
        let path = "spec/fixtures/files/ephemera/ephemera1.json";
        d.push(path);
        
        let result = json_ephemera_document(d.to_string_lossy().to_string());
        assert_eq!(result, "{\"title_display\":\"Of technique : chance procedures on turntable : a book of essays & illustrations\",\"title_citation_display\":\"Of technique : chance procedures on turntable : a book of essays & illustrations\"}");
    }
}
