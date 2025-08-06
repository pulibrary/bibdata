use crate::ephemera_folder::country::ExactMatch;
use serde::Deserialize;

#[derive(Clone, Deserialize, Debug)]
pub struct Coverage {
    pub exact_match: ExactMatch,
    #[serde(rename = "pref_label")]
    pub label: String,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_parse_coverage_exact_match_from_the_json_ld() {
        let json_ld = r#"[
            {
                "@id": "https://figgy-staging.princeton.edu/catalog/8d175872-80fc-4389-bd0b-5034d1178669",
                "@type": "skos:Concept",
                "pref_label": "Andorra",
                "in_scheme": {
                  "@id": "https://figgy.princeton.edu/ns/lAEGeographicAreas",
                  "@type": "skos:ConceptScheme",
                  "pref_label": "LAE Geographic Areas"
                },
                "exact_match": {
                    "@id": {
                        "@id": "[\"http://id.loc.gov/vocabulary/countries/an\"]"
                    }
                }
            },
            {
                "@id": "https://figgy-staging.princeton.edu/catalog/6170d545-fe9b-4df9-ae72-776083f00102",
                "@type": "skos:Concept",
                "pref_label": "Anguilla",
                "in_scheme": {
                  "@id": "https://figgy.princeton.edu/ns/lAEGeographicAreas",
                  "@type": "skos:ConceptScheme",
                  "pref_label": "LAE Geographic Areas"
                },
                "exact_match": {
                    "@id": {
                        "@id": "[\"http://id.badbadbad.gov/vocabulary/countries/am\"]"
                    }
                }
            }
          ]"#;
        let coverage_vector: Vec<Coverage> = serde_json::from_str(json_ld).unwrap();
        assert_eq!(
            coverage_vector[0].exact_match.id.country_ids().unwrap(),
            vec!["http://id.loc.gov/vocabulary/countries/an"]
        );
        assert_eq!(coverage_vector[0].label, "Andorra");
        assert_eq!(coverage_vector[1].label, "Anguilla");
        assert!(coverage_vector[0].exact_match.accepted_vocabulary());
        assert!(!coverage_vector[1].exact_match.accepted_vocabulary());
    }
}
