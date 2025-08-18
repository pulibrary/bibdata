use crate::solr;
use serde::Deserialize;

use serde::de::Deserializer;
use serde::Serialize;

#[derive(Copy, Clone, Debug, Serialize, PartialEq)]
pub struct Format {
    pub pref_label: Option<solr::FormatFacet>,
}

impl<'de> Deserialize<'de> for Format {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        #[derive(Deserialize)]
        struct FormatNestedId {
            #[serde(rename = "exact_match")]
            exact_match: Option<serde_json::Value>,
        }

        let format_nested = FormatNestedId::deserialize(deserializer)?;
        let facet = format_nested
            .exact_match
            .as_ref()
            .and_then(|em| em.get("@id"))
            .map(|id_val| {
                Some(if id_val.is_string() {
                    solr::FormatFacet::Book
                } else if id_val.is_object() {
                    solr::FormatFacet::Book
                } else {
                    // If @id is neither string nor object, return None
                    return None;
                })
            });

        Ok(Format {
            pref_label: facet.flatten(),
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_parse_format_from_the_json_ld() {
        let json_ld = r#"[
            {
              "@id": "https://figgy-staging.princeton.edu/catalog/5dbeae15-f46a-4411-a385-ce6df02231dc",
              "@type": "skos:Concept",
              "pref_label": "Pamphlets",
              "in_scheme": {
                "@id": "https://figgy.princeton.edu/ns/ephemeraGenres",
                "@type": "skos:ConceptScheme",
                "pref_label": "Ephemera Genres"
              },
              "exact_match": {
                "@id": {
                  "@id": "http://id.loc.gov/vocabulary/graphicMaterials/tgm001221"
                }
              }
            }
          ]"#;
        let formats: Vec<Format> = serde_json::from_str(json_ld).unwrap();
        assert_eq!(formats[0].pref_label, Some(solr::FormatFacet::Book));
    }

    #[test]
    fn it_can_parse_format_from_the_json_ld_when_exact_match_has_one_id() {
        let json_ld = r#"[
            {
              "@id": "https://figgy-staging.princeton.edu/catalog/5dbeae15-f46a-4411-a385-ce6df02231dc",
              "@type": "skos:Concept",
              "pref_label": "Pamphlets",
              "in_scheme": {
                "@id": "https://figgy.princeton.edu/ns/ephemeraGenres",
                "@type": "skos:ConceptScheme",
                "pref_label": "Ephemera Genres"
              },
              "exact_match": {
                  "@id": "http://id.loc.gov/vocabulary/graphicMaterials/tgm001221"
              }
            }
          ]"#;
        let formats: Vec<Format> = serde_json::from_str(json_ld).unwrap();
        assert_eq!(formats[0].pref_label, Some(solr::FormatFacet::Book));
    }
}
