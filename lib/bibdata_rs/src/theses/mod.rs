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

pub fn map_program(original: String) -> Option<String> {
    match (original.as_str()) {
        "African American Studies Program" => Some("Princeton University. Program in African-American Studies".to_owned()),
        "African Studies Program" => Some("Princeton University. Program in African Studies".to_owned()),
        "American Studies Program" => Some("Princeton University. Program in American Studies".to_owned()),
        "Applications of Computing Program" => Some("Princeton University. Program in Applications of Computing".to_owned()),
        "Architecture and Engineering Program" => Some("Princeton University. Program in Architecture and Engineering".to_owned()),
        "Center for Statistics and Machine Learning" => Some("Princeton University. Center for Statistics and Machine Learning".to_owned()),
        "Creative Writing Program" => Some("Princeton University. Creative Writing Program".to_owned()),
        "East Asian Studies Program" => Some("Princeton University. Program in East Asian Studies".to_owned()),
        "Engineering Biology Program" => Some("Princeton University. Program in Engineering Biology".to_owned()),
        "Engineering and Management Systems Program" => Some("Princeton University. Program in Engineering and Management Systems".to_owned()),
        "Environmental Studies Program" => Some("Princeton University. Program in Environmental Studies".to_owned()),
        "Ethnographic Studies Program" => Some("Princeton University. Program in Ethnographic Studies".to_owned()),
        "European Cultural Studies Program" => Some("Princeton University. Program in European Cultural Studies".to_owned()),
        "Finance Program" => Some("Princeton University. Program in Finance".to_owned()),
        "Geological Engineering Program" => Some("Princeton University. Program in Geological Engineering".to_owned()),
        "Global Health and Health Policy Program" => Some("Princeton University. Program in Global Health and Health Policy".to_owned()),
        "Hellenic Studies Program" => Some("Princeton University. Program in Hellenic Studies".to_owned()),
        "Humanities Council and Humanistic Studies Program" => Some("Princeton University. Program in Humanistic Studies".to_owned()),
        "Judaic Studies Program" => Some("Princeton University. Program in Judaic Studies".to_owned()),
        "Latin American Studies Program" => Some("Princeton University. Program in Latin American Studies".to_owned()),
        "Latino Studies Program" => Some("Princeton University. Program in Latino Studies".to_owned()),
        "Linguistics Program" => Some("Princeton University. Program in Linguistics".to_owned()),
        "Materials Science and Engineering Program" => Some("Princeton University. Program in Materials Science and Engineering".to_owned()),
        "Medieval Studies Program" => Some("Princeton University. Program in Medieval Studies".to_owned()),
        "Near Eastern Studies Program" => Some("Princeton University. Program in Near Eastern Studies".to_owned()),
        "Neuroscience Program" => Some("Princeton University. Program in Neuroscience".to_owned()),
        "Program in Cognitive Science" => Some("Princeton University. Program in Cognitive Science".to_owned()),
        "Program in Entrepreneurship" => Some("Princeton University. Program in Entrepreneurship".to_owned()),
        "Program in Gender and Sexuality Studies" => Some("Princeton University. Program in Gender and Sexuality Studies".to_owned()),
        "Program in Music Theater" => Some("Princeton University. Program in Music Theater".to_owned()),
        "Program in Technology & Society, Technology Track" => Some("Princeton University. Program in Technology and Society".to_owned()),
        "Program in Values and Public Life" => Some("Princeton University. Program in Values and Public Life".to_owned()),
        "Quantitative and Computational Biology Program" => Some("Princeton University. Program in Quantitative and Computational Biology".to_owned()),
        "Robotics & Intelligent Systems Program" => Some("Princeton University. Program in Robotics and Intelligent Systems".to_owned()),
        "Russian & Eurasian Studies Program" => Some("Princeton University. Program in Russian, East European and Eurasian Studies".to_owned()),
        "South Asian Studies Program" => Some("Princeton University. Program in South Asian Studies".to_owned()),
        "Theater" => Some("Princeton University. Program in Theater".to_owned()),
        "Theater Program" => Some("Princeton University. Program in Theater".to_owned()),
        "Sustainable Energy Program" => Some("Princeton University. Program in Sustainable Energy".to_owned()),
        "Urban Studies Program" => Some("Princeton University. Program in Urban Studies".to_owned()),
        _ => None
    }
}
