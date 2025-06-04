use serde::Deserialize;

#[derive(Deserialize)]
struct Format {
    pref_label: Option<String>,
}

impl Format {
    pub fn rename_format(&self) -> Option<&str> {
        match &self.pref_label {
            Some(f) if f == "Books" => Some("Book"),
            Some(f) if f == "Serials" => Some("Journal"),
            Some(f) if f == "Reports" => Some("Report"),
            _ => None,
        }
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
              "pref_label": "Books",
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
        assert_eq!(formats[0].rename_format(), Some("Book"));
    }
}
