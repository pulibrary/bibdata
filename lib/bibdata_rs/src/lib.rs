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
pub struct Item {
    pub id: String,
    pub attributes: Attributes,
}

#[derive(Deserialize, Debug)]
pub struct Response {
    pub data: Vec<Item>,
}

#[derive(Deserialize, Debug)]
pub struct Attributes {
    #[serde(rename = "sort_title")]
    pub title_sort: String,
    // alternative -> other_title_display
    #[serde(rename = "transliterated_title")]
    pub other_title_display: Vec<String>,
    // creator -> author_display, author, author_s, author_sort, author_roles_1display, author_citation_display
    #[serde(rename = "creator")]
    creator: Vec<String>,
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
        let figgy_url = std::env::var("FIGGY_URL");
        CatalogClient {
            url: figgy_url.unwrap()
        }
    }

    pub async fn get_data(&self) -> Result<Response, reqwest::Error> {
        let response = reqwest::get(&self.url).await?;
        let data: Response = response.json().await?;
        Ok(data)
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

fn json_document(path: String) -> String {
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
    submodule.define_singleton_method("json_document", function!(json_document, 1))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[tokio::test]
    async fn test_get_data() {
        std::env::set_var("FIGGY_URL", "https://figgy-staging.princeton.edu/catalog.json?f%5Bephemera_project_ssim%5D%5B%5D=Born+Digital+Monographs%2C+Serials%26Series+Reports&f%5Bhuman_readable_type_ssim%5D%5B%5D=Ephemera+Folder&f%5Bstate_ssim%5D%5B%5D=complete&per_page=100&q=");
        let client = CatalogClient::default();
        let result = client.get_data().await;
        assert!(result.is_ok());
    }
}
