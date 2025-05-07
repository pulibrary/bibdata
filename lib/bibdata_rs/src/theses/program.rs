// This module is responsible for mapping program names in Dataspace to the Library of Congress authorized names

pub fn map_program(original: &str) -> Option<String> {
    match original {
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

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn it_maps_program_to_lc_program() {
        assert_eq!(
            map_program("Global Health and Health Policy Program").unwrap(),
            "Princeton University. Program in Global Health and Health Policy"
        );
        assert_eq!(map_program("Cool new program"), None);
    }
}
