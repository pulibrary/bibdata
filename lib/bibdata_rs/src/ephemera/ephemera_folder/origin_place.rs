use crate::ephemera_folder::country::ExactMatch;
use serde::Deserialize;

#[derive(Clone, Deserialize, Debug)]
pub struct OriginPlace {
    pub exact_match: ExactMatch,
    #[serde(rename = "pref_label")]
    pub label: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_parse_origin_place_exact_match_from_the_json_ld() {
        let json_ld = r#"[
            {
                "@id": "https://figgy-staging.princeton.edu/catalog/91004621-0204-4c75-aaa4-0ce3a3167dd0",
                "@type": "skos:Concept",
                "pref_label": "Colombia",
                "in_scheme": {
                "@id": "https://figgy.princeton.edu/ns/lAEGeographicAreas",
                "@type": "skos:ConceptScheme",
                "pref_label": "LAE Geographic Areas"
                },
                "exact_match": {
                    "@id": "http://id.loc.gov/vocabulary/countries/ck"
                }
            },
            {
                "@id": "https://figgy-staging.princeton.edu/catalog/6170d545-fe9b-4df9-ae72-776083f00102",
                "@type": "skos:Concept",
                "pref_label": "Venezuela",
                "in_scheme": {
                "@id": "https://figgy.princeton.edu/ns/lAEGeographicAreas",
                "@type": "skos:ConceptScheme",
                "pref_label": "LAE Geographic Areas"
                },
                "exact_match": {
                    "@id": "http://id.badbadbad.gov/vocabulary/countries/ve"
                }
            }
          ]"#;
        let origin_vector: Vec<OriginPlace> = serde_json::from_str(json_ld).unwrap();
        assert_eq!(
            origin_vector[0].exact_match.id,
            "http://id.loc.gov/vocabulary/countries/ck"
        );
        assert_eq!(origin_vector[0].label, "Colombia");
        assert_eq!(origin_vector[1].label, "Venezuela");
        assert!(origin_vector[0].exact_match.accepted_vocabulary());
        assert!(!origin_vector[1].exact_match.accepted_vocabulary());
    }
}
