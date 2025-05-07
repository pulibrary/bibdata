use serde::{ser::SerializeStruct, Deserialize, Serialize, Serializer};
use std::{fs, env};

pub mod department;
pub mod latex;
pub mod program;

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

pub fn json_document(path: String) -> String {
    let data = fs::read_to_string(path).expect("Unable to read file");
    let metadata: Metadata = serde_xml_rs::SerdeXml::new()
        .namespace("oai_dc", "http://www.openarchives.org/OAI/2.0/oai_dc/")
        .namespace("dc", "http://purl.org/dc/elements/1.1/")
        .from_str(&data)
        .expect("Unable to parse XML");
    serde_json::to_string(&metadata.thesis).unwrap()
}

pub fn theses_cache_path() -> String {
    match env::var("FILEPATH") {
        Ok(value) => value.to_owned(),
        Err(_) => "/tmp/theses.json".to_owned()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_determines_the_path_to_cache_the_theses() {
        without_mangling_filepath(|| {
            env::set_var("FILEPATH", "/home/user/theses.json");
            assert_eq!(theses_cache_path(), "/home/user/theses.json");
        });
    }

    #[test]
    fn it_defaults_theses_cache_path_to_tmp() {
        without_mangling_filepath(|| {
            env::remove_var("FILEPATH");
            assert_eq!(theses_cache_path(), "/tmp/theses.json");
        });
    }

    fn without_mangling_filepath<T: Fn() -> ()>(f: T) {
        let original = match env::var("FILEPATH") {
            Ok(value) => Some(value),
            Err(_) => None
        };
        f();
        if original.is_some() { env::set_var("FILEPATH", original.unwrap()) } else { env::remove_var("FILEPATH");}
    }
}

