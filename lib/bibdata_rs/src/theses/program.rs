// This module is responsible for mapping program names in Dataspace to the Library of Congress authorized names

pub fn map_program(original: &str) -> Option<&str> {
    match original {
        "African American Studies Program" => {
            Some("Princeton University. Program in African-American Studies")
        }
        "African Studies Program" => Some("Princeton University. Program in African Studies"),
        "American Studies Program" => Some("Princeton University. Program in American Studies"),
        "Applications of Computing Program" => {
            Some("Princeton University. Program in Applications of Computing")
        }
        "Architecture and Engineering Program" => {
            Some("Princeton University. Program in Architecture and Engineering")
        }
        "Center for Statistics and Machine Learning" => {
            Some("Princeton University. Center for Statistics and Machine Learning")
        }
        "Creative Writing Program" => Some("Princeton University. Creative Writing Program"),
        "East Asian Studies Program" => Some("Princeton University. Program in East Asian Studies"),
        "Engineering Biology Program" => {
            Some("Princeton University. Program in Engineering Biology")
        }
        "Engineering and Management Systems Program" => {
            Some("Princeton University. Program in Engineering and Management Systems")
        }
        "Environmental Studies Program" => {
            Some("Princeton University. Program in Environmental Studies")
        }
        "Ethnographic Studies Program" => {
            Some("Princeton University. Program in Ethnographic Studies")
        }
        "European Cultural Studies Program" => {
            Some("Princeton University. Program in European Cultural Studies")
        }
        "Finance Program" => Some("Princeton University. Program in Finance"),
        "Geological Engineering Program" => {
            Some("Princeton University. Program in Geological Engineering")
        }
        "Global Health and Health Policy Program" => {
            Some("Princeton University. Program in Global Health and Health Policy")
        }
        "Hellenic Studies Program" => Some("Princeton University. Program in Hellenic Studies"),
        "Humanities Council and Humanistic Studies Program" => {
            Some("Princeton University. Program in Humanistic Studies")
        }
        "Judaic Studies Program" => Some("Princeton University. Program in Judaic Studies"),
        "Latin American Studies Program" => {
            Some("Princeton University. Program in Latin American Studies")
        }
        "Latino Studies Program" => Some("Princeton University. Program in Latino Studies"),
        "Linguistics Program" => Some("Princeton University. Program in Linguistics"),
        "Materials Science and Engineering Program" => {
            Some("Princeton University. Program in Materials Science and Engineering")
        }
        "Medieval Studies Program" => Some("Princeton University. Program in Medieval Studies"),
        "Near Eastern Studies Program" => {
            Some("Princeton University. Program in Near Eastern Studies")
        }
        "Neuroscience Program" => Some("Princeton University. Program in Neuroscience"),
        "Program in Cognitive Science" => {
            Some("Princeton University. Program in Cognitive Science")
        }
        "Program in Entrepreneurship" => Some("Princeton University. Program in Entrepreneurship"),
        "Program in Gender and Sexuality Studies" => {
            Some("Princeton University. Program in Gender and Sexuality Studies")
        }
        "Program in Music Theater" => Some("Princeton University. Program in Music Theater"),
        "Program in Technology & Society, Technology Track" => {
            Some("Princeton University. Program in Technology and Society")
        }
        "Program in Values and Public Life" => {
            Some("Princeton University. Program in Values and Public Life")
        }
        "Quantitative and Computational Biology Program" => {
            Some("Princeton University. Program in Quantitative and Computational Biology")
        }
        "Robotics & Intelligent Systems Program" => {
            Some("Princeton University. Program in Robotics and Intelligent Systems")
        }
        "Russian & Eurasian Studies Program" => {
            Some("Princeton University. Program in Russian, East European and Eurasian Studies")
        }
        "South Asian Studies Program" => {
            Some("Princeton University. Program in South Asian Studies")
        }
        "Theater" => Some("Princeton University. Program in Theater"),
        "Theater Program" => Some("Princeton University. Program in Theater"),
        "Sustainable Energy Program" => Some("Princeton University. Program in Sustainable Energy"),
        "Urban Studies Program" => Some("Princeton University. Program in Urban Studies"),
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
