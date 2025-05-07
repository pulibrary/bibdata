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
    match original.as_str() {
        "African American Studies Program" => {
            Some("Princeton University. Program in African-American Studies".to_owned())
        }
        "African Studies Program" => {
            Some("Princeton University. Program in African Studies".to_owned())
        }
        "American Studies Program" => {
            Some("Princeton University. Program in American Studies".to_owned())
        }
        "Applications of Computing Program" => {
            Some("Princeton University. Program in Applications of Computing".to_owned())
        }
        "Architecture and Engineering Program" => {
            Some("Princeton University. Program in Architecture and Engineering".to_owned())
        }
        "Center for Statistics and Machine Learning" => {
            Some("Princeton University. Center for Statistics and Machine Learning".to_owned())
        }
        "Creative Writing Program" => {
            Some("Princeton University. Creative Writing Program".to_owned())
        }
        "East Asian Studies Program" => {
            Some("Princeton University. Program in East Asian Studies".to_owned())
        }
        "Engineering Biology Program" => {
            Some("Princeton University. Program in Engineering Biology".to_owned())
        }
        "Engineering and Management Systems Program" => {
            Some("Princeton University. Program in Engineering and Management Systems".to_owned())
        }
        "Environmental Studies Program" => {
            Some("Princeton University. Program in Environmental Studies".to_owned())
        }
        "Ethnographic Studies Program" => {
            Some("Princeton University. Program in Ethnographic Studies".to_owned())
        }
        "European Cultural Studies Program" => {
            Some("Princeton University. Program in European Cultural Studies".to_owned())
        }
        "Finance Program" => Some("Princeton University. Program in Finance".to_owned()),
        "Geological Engineering Program" => {
            Some("Princeton University. Program in Geological Engineering".to_owned())
        }
        "Global Health and Health Policy Program" => {
            Some("Princeton University. Program in Global Health and Health Policy".to_owned())
        }
        "Hellenic Studies Program" => {
            Some("Princeton University. Program in Hellenic Studies".to_owned())
        }
        "Humanities Council and Humanistic Studies Program" => {
            Some("Princeton University. Program in Humanistic Studies".to_owned())
        }
        "Judaic Studies Program" => {
            Some("Princeton University. Program in Judaic Studies".to_owned())
        }
        "Latin American Studies Program" => {
            Some("Princeton University. Program in Latin American Studies".to_owned())
        }
        "Latino Studies Program" => {
            Some("Princeton University. Program in Latino Studies".to_owned())
        }
        "Linguistics Program" => Some("Princeton University. Program in Linguistics".to_owned()),
        "Materials Science and Engineering Program" => {
            Some("Princeton University. Program in Materials Science and Engineering".to_owned())
        }
        "Medieval Studies Program" => {
            Some("Princeton University. Program in Medieval Studies".to_owned())
        }
        "Near Eastern Studies Program" => {
            Some("Princeton University. Program in Near Eastern Studies".to_owned())
        }
        "Neuroscience Program" => Some("Princeton University. Program in Neuroscience".to_owned()),
        "Program in Cognitive Science" => {
            Some("Princeton University. Program in Cognitive Science".to_owned())
        }
        "Program in Entrepreneurship" => {
            Some("Princeton University. Program in Entrepreneurship".to_owned())
        }
        "Program in Gender and Sexuality Studies" => {
            Some("Princeton University. Program in Gender and Sexuality Studies".to_owned())
        }
        "Program in Music Theater" => {
            Some("Princeton University. Program in Music Theater".to_owned())
        }
        "Program in Technology & Society, Technology Track" => {
            Some("Princeton University. Program in Technology and Society".to_owned())
        }
        "Program in Values and Public Life" => {
            Some("Princeton University. Program in Values and Public Life".to_owned())
        }
        "Quantitative and Computational Biology Program" => Some(
            "Princeton University. Program in Quantitative and Computational Biology".to_owned(),
        ),
        "Robotics & Intelligent Systems Program" => {
            Some("Princeton University. Program in Robotics and Intelligent Systems".to_owned())
        }
        "Russian & Eurasian Studies Program" => Some(
            "Princeton University. Program in Russian, East European and Eurasian Studies"
                .to_owned(),
        ),
        "South Asian Studies Program" => {
            Some("Princeton University. Program in South Asian Studies".to_owned())
        }
        "Theater" => Some("Princeton University. Program in Theater".to_owned()),
        "Theater Program" => Some("Princeton University. Program in Theater".to_owned()),
        "Sustainable Energy Program" => {
            Some("Princeton University. Program in Sustainable Energy".to_owned())
        }
        "Urban Studies Program" => {
            Some("Princeton University. Program in Urban Studies".to_owned())
        }
        _ => None,
    }
}

pub fn map_department(original: String) -> Option<String> {
    match original.as_str() {
        "African American Studies" => {
            Some("Princeton University. Department of African American Studies".to_owned())
        }
        "Art and Archaeology" => {
            Some("Princeton University. Department of Art and Archaeology".to_owned())
        }
        "Aeronautical Engineering" => {
            Some("Princeton University. Department of Aeronautical Engineering".to_owned())
        }
        "Anthropology" => Some("Princeton University. Department of Anthropology".to_owned()),
        "Architecture School" => Some("Princeton University. School of Architecture".to_owned()),
        "Astrophysical Sciences" => {
            Some("Princeton University. Department of Astrophysical Sciences".to_owned())
        }
        "Biochemical Sciences" => {
            Some("Princeton University. Department of Biochemical Sciences".to_owned())
        }
        "Biology" => Some("Princeton University. Department of Biology".to_owned()),
        "Civil and Environmental Engineering" => Some(
            "Princeton University. Department of Civil and Environmental Engineering".to_owned(),
        ),
        "Civil Engineering and Operations Research" => Some(
            "Princeton University. Department of Civil Engineering and Operations Research"
                .to_owned(),
        ),
        "Chemical and Biological Engineering" => Some(
            "Princeton University. Department of Chemical and Biological Engineering".to_owned(),
        ),
        "Chemistry" => Some("Princeton University. Department of Chemistry".to_owned()),
        "Classics" => Some("Princeton University. Department of Classics".to_owned()),
        "Comparative Literature" => {
            Some("Princeton University. Department of Comparative Literature".to_owned())
        }
        "Computer Science" => {
            Some("Princeton University. Department of Computer Science".to_owned())
        }
        "East Asian Studies" => {
            Some("Princeton University. Department of East Asian Studies".to_owned())
        }
        "Economics" => Some("Princeton University. Department of Economics".to_owned()),
        "Ecology and Evolutionary Biology" => {
            Some("Princeton University. Department of Ecology and Evolutionary Biology".to_owned())
        }
        "Electrical Engineering" => {
            Some("Princeton University. Department of Electrical Engineering".to_owned())
        }
        "Engineering and Applied Science" => {
            Some("Princeton University. School of Engineering and Applied Science".to_owned())
        }
        "English" => Some("Princeton University. Department of English".to_owned()),
        "French and Italian" => {
            Some("Princeton University. Department of French and Italian".to_owned())
        }
        "Geosciences" => Some("Princeton University. Department of Geosciences".to_owned()),
        "German" => Some(
            "Princeton University. Department of Germanic Languages and Literatures".to_owned(),
        ),
        "History" => Some("Princeton University. Department of History".to_owned()),
        "Special Program in Humanities" => {
            Some("Princeton University. Special Program in the Humanities".to_owned())
        }
        "Independent Concentration" => {
            Some("Princeton University Independent Concentration Program".to_owned())
        }
        "Mathematics" => Some("Princeton University. Department of Mathematics".to_owned()),
        "Molecular Biology" => {
            Some("Princeton University. Department of Molecular Biology".to_owned())
        }
        "Mechanical and Aerospace Engineering" => Some(
            "Princeton University. Department of Mechanical and Aerospace Engineering".to_owned(),
        ),
        "Medieval Studies" => Some("Princeton University. Program in Medieval Studies".to_owned()),
        "Modern Languages" => {
            Some("Princeton University. Department of Modern Languages.".to_owned())
        }
        "Music" => Some("Princeton University. Department of Music".to_owned()),
        "Near Eastern Studies" => {
            Some("Princeton University. Department of Near Eastern Studies".to_owned())
        }
        "Neuroscience" => Some("Princeton Neuroscience Institute".to_owned()),
        "Operations Research and Financial Engineering" => Some(
            "Princeton University. Department of Operations Research and Financial Engineering"
                .to_owned(),
        ),
        "Oriental Studies" => {
            Some("Princeton University. Department of Oriental Studies".to_owned())
        }
        "Philosophy" => Some("Princeton University. Department of Philosophy".to_owned()),
        "Physics" => Some("Princeton University. Department of Physics".to_owned()),
        "Politics" => Some("Princeton University. Department of Politics".to_owned()),
        "Psychology" => Some("Princeton University. Department of Psychology".to_owned()),
        "Religion" => Some("Princeton University. Department of Religion".to_owned()),
        "Romance Languages and Literatures" => {
            Some("Princeton University. Department of Romance Languages and Literatures".to_owned())
        }
        "Slavic Languages and Literature" => {
            Some("Princeton University. Department of Slavic Languages and Literatures".to_owned())
        }
        "Sociology" => Some("Princeton University. Department of Sociology".to_owned()),
        "Spanish and Portuguese" => Some(
            "Princeton University. Department of Spanish and Portuguese Languages and Cultures"
                .to_owned(),
        ),
        "Spanish and Portuguese Languages and Cultures" => Some(
            "Princeton University. Department of Spanish and Portuguese Languages and Cultures"
                .to_owned(),
        ),
        "Statistics" => Some("Princeton University. Department of Statistics".to_owned()),
        "School of Public and International Affairs" => {
            Some("School of Public and International Affairs".to_owned())
        }
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn it_maps_department_to_lc_department() {
        assert_eq!(
            map_department("Comparative Literature".to_owned()).unwrap(),
            "Princeton University. Department of Comparative Literature"
        );
        assert_eq!(map_department("Cool new department".to_owned()), None);
    }
}
