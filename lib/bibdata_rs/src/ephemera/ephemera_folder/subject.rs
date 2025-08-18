use serde::Deserialize;

#[derive(Clone, Deserialize, Debug)]
pub struct Subject {
    pub exact_match: ExactMatch,
    #[serde(rename = "pref_label")]
    pub label: String,
}

#[derive(Clone, Deserialize, Debug)]
pub struct ExactMatch {
    #[serde(rename = "@id")]
    pub id: String,
}

impl ExactMatch {
    pub fn accepted_vocabulary(&self) -> bool {
        match self.id.as_str() {
            s if s.starts_with("http://id.loc.gov") => true,
            s if s.starts_with("https://homosaurus.org/") => true,
            _ => false,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_parse_exact_match_from_the_json_ld() {
        let json_ld = r#"[
            {
                "@id": "https://figgy-staging.princeton.edu/catalog/abf14319-f4bd-48d3-b4ab-5369354cc4aa",
                "@type": "skos:Concept",
                "pref_label": "Music",
                "in_scheme": {
                    "@id": "https://figgy.princeton.edu/ns/lAESubjects/artsAndCulture",
                    "@type": "skos:ConceptScheme",
                    "pref_label": "Arts and culture"
                },
                "exact_match": {
                   "@id": "http://id.loc.gov/authorities/subjects/sh85088762"
                }
            }
        ]"#;
        let subject: Vec<Subject> = serde_json::from_str(json_ld).unwrap();
        assert_eq!(
            subject[0].exact_match.id,
            "http://id.loc.gov/authorities/subjects/sh85088762"
        );
        assert_eq!(subject[0].label, "Music")
    }
}
