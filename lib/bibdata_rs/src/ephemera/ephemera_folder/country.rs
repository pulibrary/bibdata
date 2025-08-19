use serde::{Deserialize, Deserializer};
use serde_json::Value;

#[derive(Clone, Debug)]
pub struct ExactMatch {
    pub id: String,
}

impl<'de> Deserialize<'de> for ExactMatch {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let value = Value::deserialize(deserializer)?;
        if let Some(id) = value.get("@id") {
            if id.is_string() {
                return Ok(ExactMatch {
                    id: id.as_str().unwrap().to_string(),
                });
            }
            if id.is_object() {
                if let Some(nested_id) = id.get("@id") {
                    if nested_id.is_string() {
                        return Ok(ExactMatch {
                            id: nested_id.as_str().unwrap().to_string(),
                        });
                    }
                }
            }
        }
        Err(serde::de::Error::custom("Could not parse ExactMatch Country id"))
    }
}

impl ExactMatch {
    pub fn accepted_vocabulary(&self) -> bool {
        self.id
            .starts_with("http://id.loc.gov/vocabulary/countries/")
    }
}
