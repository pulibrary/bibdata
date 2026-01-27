use crate::ephemera_folder::country::ExactMatch;
use serde::{Deserialize, Deserializer};
use serde_json::Value;

#[derive(Clone, Debug)]
pub struct Coverage {
  pub exact_match: Option<ExactMatch>,
  pub label: String,
}

impl<'de> Deserialize<'de> for Coverage {
  fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
  where
    D: Deserializer<'de>,
  {
    let value = Value::deserialize(deserializer)?;
    let label = value.get("pref_label")
      .and_then(|v| v.as_str())
      .unwrap_or("").to_string();
    let exact_match = match value.get("exact_match") {
      Some(em_value) => ExactMatch::deserialize(em_value).ok(),
      None => None,
    };
    Ok(Coverage { exact_match, label })
  }
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
                        "@id": "http://id.loc.gov/vocabulary/countries/an"
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
            coverage_vector[0].exact_match.as_ref().unwrap().id,
            "http://id.loc.gov/vocabulary/countries/an"
        );
        assert_eq!(coverage_vector[0].label, "Andorra");
        assert_eq!(coverage_vector[1].label, "Anguilla");
        assert!(coverage_vector[0].exact_match.as_ref().unwrap().accepted_vocabulary());
        assert!(!coverage_vector[1].exact_match.as_ref().unwrap().accepted_vocabulary());
    }
    
    #[test]
    fn it_can_parse_coverage_and_skips_entry_when_exact_match_is_missing_from_the_json_ld() {
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
                        "@id": "http://id.loc.gov/vocabulary/countries/an"
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
                }
            }
          ]"#;
        let raw: Vec<Value> = serde_json::from_str(json_ld).unwrap();
        let coverage_vector: Vec<Coverage> = raw.into_iter()
            .filter_map(|v| Coverage::deserialize(v).ok())
            .filter(|c| c.exact_match.is_some())
            .collect();
        assert_eq!(coverage_vector.len(), 1);
        assert_eq!(coverage_vector[0].label, "Andorra");
        assert_eq!(coverage_vector[0].exact_match.as_ref().unwrap().id, "http://id.loc.gov/vocabulary/countries/an");
    }
}
