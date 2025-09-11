use log::trace;
use serde::{Deserialize, Deserializer, Serialize};
use serde_json::Value;

#[derive(Clone, Deserialize, Debug)]
pub struct Subject {
    pub exact_match: Option<ExactMatch>,
    #[serde(rename = "pref_label")]
    pub label: String,
}

#[derive(Clone, Serialize, Debug)]
pub struct ExactMatch {
    pub id: Id,
}
#[derive(Clone, Deserialize, Serialize, Debug)]
pub struct Id {
    #[serde(rename = "@id")]
    pub id: String,
}
impl Id {
    fn subject_ids(&self) -> anyhow::Result<Vec<String>> {
        if self.id.starts_with('[') {
            let v: Vec<String> = serde_json::from_str(&self.id)?;
            Ok(v)
        } else {
            Ok(vec![self.id.clone()])
        }
    }
}

impl ExactMatch {
    pub fn accepted_loc_vocabulary(&self) -> bool {
        matches!(&self.id.subject_ids(), Ok(s) if s.iter().any(|url| {
                  url.starts_with("http://id.loc.gov")
        }))
    }

    pub fn accepted_homoit_vocabulary(&self) -> bool {
        matches!(&self.id.subject_ids(), Ok(s) if s.iter().any(|url| {
            url.starts_with("https://homosaurus.org/")
        }))
    }
}

impl Subject {
    pub fn log_when_there_is_no_exact_match(&self) {
        if self.exact_match.is_none() {
            trace!("Subject missing exact_match: {:?}", self);
        }
    }
}

pub fn log_subjects_without_exact_match(subjects: &[Subject]) {
    for subject in subjects {
        subject.log_when_there_is_no_exact_match();
    }
}

impl<'de> Deserialize<'de> for ExactMatch {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let value = Value::deserialize(deserializer)?;
        if let Some(id_value) = value.get("@id") {
            if id_value.is_string() {
                return Ok(ExactMatch {
                    id: Id {
                        id: id_value.as_str().unwrap().to_string(),
                    },
                });
            } else if id_value.is_object() {
                if let Some(nested_id) = id_value.get("@id") {
                    if nested_id.is_string() {
                        return Ok(ExactMatch {
                            id: Id {
                                id: nested_id.as_str().unwrap().to_string(),
                            },
                        });
                    }
                }
            }
        }
        Err(serde::de::Error::custom(
            "Could not parse ExactMatch Subject id",
        ))
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
            subject[0].exact_match.as_ref().unwrap().id.id,
            "http://id.loc.gov/authorities/subjects/sh85088762"
        );
        assert_eq!(subject[0].label, "Music")
    }
}
