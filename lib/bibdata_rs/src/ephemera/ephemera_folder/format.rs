use crate::solr;
use serde::Deserialize;

#[derive(Copy, Clone, Deserialize, Debug)]
pub struct Format {
    pub pref_label: Option<solr::FormatFacet>,
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
}
