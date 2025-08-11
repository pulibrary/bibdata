use serde::Deserialize;

#[derive(Clone, Deserialize, Debug)]
pub struct Language {
    pub exact_match: ExactMatch,
    #[serde(rename = "pref_label")]
    pub label: String,
}

#[derive(Clone, Deserialize, Debug)]
pub struct ExactMatch {
    #[serde(rename = "@id")]
    pub id: Id,
}

#[derive(Clone, Deserialize, Debug)]
pub struct Id {
    #[serde(rename = "@id")]
    pub id: String,
}
impl Id {
    fn language_ids(&self) -> anyhow::Result<Vec<String>> {
        let v: Vec<String> = serde_json::from_str(&self.id)?;
        Ok(v)
    }
}

impl ExactMatch {
    pub fn accepted_vocabulary(&self) -> bool {
        matches!(&self.id.language_ids(), Ok(s) if s.iter().any(|url| {
                  url.starts_with("http://id.loc.gov/vocabulary/iso639-1")
                     || url.starts_with("http://id.loc.gov/vocabulary/iso639-2")
        }))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_parse_exact_match_from_the_json_ld() {
        let json_ld = r#"[
            {
              "@id": "https://figgy-staging.princeton.edu/catalog/6c38683a-cc07-4dea-bd52-09a29fb0f59f",
              "@type": "skos:Concept",
              "pref_label": "English",
              "in_scheme": {
                "@id": "https://figgy.princeton.edu/ns/lAELanguagesNeato",
                "@type": "skos:ConceptScheme",
                "pref_label": "LAE Languages neato"
              },
              "exact_match": {
                "@id": {
                  "@id": "[\"http://id.loc.gov/vocabulary/iso639-1/en\"]"
                }
              }
            },
            {
              "@id": "https://figgy-staging.princeton.edu/catalog/766dba0b-6393-4c29-b237-c3468e6c5d9d",
              "@type": "skos:Concept",
              "pref_label": "Spanish",
              "in_scheme": {
                "@id": "https://figgy.princeton.edu/ns/lAELanguagesNeato",
                "@type": "skos:ConceptScheme",
                "pref_label": "LAE Languages neato"
              },
              "exact_match": {
                "@id": {
                  "@id": "[\"http://id.loc.gov/vocabulary/iso639-2/spa\"]"
                }
              }
            }
          ]"#;
        let languages: Vec<Language> = serde_json::from_str(json_ld).unwrap();
        assert_eq!(
            languages[0].exact_match.id.language_ids().unwrap(),
            vec!["http://id.loc.gov/vocabulary/iso639-1/en"]
        );
        assert_eq!(languages[0].label, "English");
        assert_eq!(languages[1].label, "Spanish");
        assert!(languages[0].exact_match.accepted_vocabulary());
        assert!(languages[1].exact_match.accepted_vocabulary());
    }
}
