// This module is responsible for mapping department names in Dataspace to the Library of Congress authorized names

pub fn map_department(original: &str) -> Option<&str> {
    match original {
        "African American Studies" => {
            Some("Princeton University. Department of African American Studies")
        }
        "Art and Archaeology" => Some("Princeton University. Department of Art and Archaeology"),
        "Aeronautical Engineering" => {
            Some("Princeton University. Department of Aeronautical Engineering")
        }
        "Anthropology" => Some("Princeton University. Department of Anthropology"),
        "Architecture School" => Some("Princeton University. School of Architecture"),
        "Astrophysical Sciences" => {
            Some("Princeton University. Department of Astrophysical Sciences")
        }
        "Biochemical Sciences" => Some("Princeton University. Department of Biochemical Sciences"),
        "Biology" => Some("Princeton University. Department of Biology"),
        "Civil and Environmental Engineering" => {
            Some("Princeton University. Department of Civil and Environmental Engineering")
        }
        "Civil Engineering and Operations Research" => {
            Some("Princeton University. Department of Civil Engineering and Operations Research")
        }
        "Chemical and Biological Engineering" => {
            Some("Princeton University. Department of Chemical and Biological Engineering")
        }
        "Chemistry" => Some("Princeton University. Department of Chemistry"),
        "Classics" => Some("Princeton University. Department of Classics"),
        "Comparative Literature" => {
            Some("Princeton University. Department of Comparative Literature")
        }
        "Computer Science" => Some("Princeton University. Department of Computer Science"),
        "East Asian Studies" => Some("Princeton University. Department of East Asian Studies"),
        "Economics" => Some("Princeton University. Department of Economics"),
        "Ecology and Evolutionary Biology" => {
            Some("Princeton University. Department of Ecology and Evolutionary Biology")
        }
        "Electrical Engineering" => {
            Some("Princeton University. Department of Electrical Engineering")
        }
        "Engineering and Applied Science" => {
            Some("Princeton University. School of Engineering and Applied Science")
        }
        "English" => Some("Princeton University. Department of English"),
        "French and Italian" => Some("Princeton University. Department of French and Italian"),
        "Geosciences" => Some("Princeton University. Department of Geosciences"),
        "German" => Some("Princeton University. Department of Germanic Languages and Literatures"),
        "History" => Some("Princeton University. Department of History"),
        "Special Program in Humanities" => {
            Some("Princeton University. Special Program in the Humanities")
        }
        "Independent Concentration" => {
            Some("Princeton University Independent Concentration Program")
        }
        "Mathematics" => Some("Princeton University. Department of Mathematics"),
        "Molecular Biology" => Some("Princeton University. Department of Molecular Biology"),
        "Mechanical and Aerospace Engineering" => {
            Some("Princeton University. Department of Mechanical and Aerospace Engineering")
        }
        "Medieval Studies" => Some("Princeton University. Program in Medieval Studies"),
        "Modern Languages" => Some("Princeton University. Department of Modern Languages."),
        "Music" => Some("Princeton University. Department of Music"),
        "Near Eastern Studies" => Some("Princeton University. Department of Near Eastern Studies"),
        "Neuroscience" => Some("Princeton Neuroscience Institute"),
        "Operations Research and Financial Engineering" => Some(
            "Princeton University. Department of Operations Research and Financial Engineering",
        ),
        "Oriental Studies" => Some("Princeton University. Department of Oriental Studies"),
        "Philosophy" => Some("Princeton University. Department of Philosophy"),
        "Physics" => Some("Princeton University. Department of Physics"),
        "Politics" => Some("Princeton University. Department of Politics"),
        "Psychology" => Some("Princeton University. Department of Psychology"),
        "Religion" => Some("Princeton University. Department of Religion"),
        "Romance Languages and Literatures" => {
            Some("Princeton University. Department of Romance Languages and Literatures")
        }
        "Slavic Languages and Literature" => {
            Some("Princeton University. Department of Slavic Languages and Literatures")
        }
        "Sociology" => Some("Princeton University. Department of Sociology"),
        "Spanish and Portuguese" => Some(
            "Princeton University. Department of Spanish and Portuguese Languages and Cultures",
        ),
        "Spanish and Portuguese Languages and Cultures" => Some(
            "Princeton University. Department of Spanish and Portuguese Languages and Cultures",
        ),
        "Statistics" => Some("Princeton University. Department of Statistics"),
        "School of Public and International Affairs" => {
            Some("Princeton University. School of Public and International Affairs")
        }

        "Public & International Affairs" => {
            Some("Princeton University. School of Public and International Affairs")
        }
        "Art & Archaeology" => Some("Princeton University. Department of Art and Archaeology"),
        "Civil & Environmental Engr" => {
            Some("Princeton University. Department of Civil and Environmental Engineering")
        }
        "Mechanical & Aerospace Engr" => {
            Some("Princeton University. Department of Mechanical and Aerospace Engineering")
        }
        "Chemical and Biological Engr" => {
            Some("Princeton University. Department of Chemical and Biological Engineering")
        }
        "Architecture" => Some("Princeton University. School of Architecture"),
        "Ops Research & Financial Engr" => Some(
            "Princeton University. Department of Operations Research and Financial Engineering",
        ),
        "Electrical & Computer Engr" => {
            Some("Princeton University. Department of Electrical Engineering")
        }
        "Creative Writing Program" => Some("Princeton University. Creative Writing Program"),
        "Ecology & Evolutionary Biology" => {
            Some("Princeton University. Department of Ecology and Evolutionary Biology")
        }
        "Independent Study-Linguistics" => {
            Some("Princeton University Independent Concentration Program")
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
            map_department("Comparative Literature").unwrap(),
            "Princeton University. Department of Comparative Literature"
        );
        assert_eq!(map_department("Cool new department"), None);
    }
}
