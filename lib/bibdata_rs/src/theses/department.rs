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
