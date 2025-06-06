use serde::{ser::Error, Deserialize, Serialize};
use std::collections::HashMap;

#[derive(Clone, Deserialize, Debug, PartialEq)]
pub struct ElectronicAccess {
    pub url: String,
    pub link_text: String,
    pub link_description: Option<String>,
}

impl Serialize for ElectronicAccess {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        let notes = match &self.link_description {
            Some(desc) => {
                vec![&self.link_text, desc]
            }
            None => {
                vec![&self.link_text]
            }
        };
        let mut hash = HashMap::new();
        hash.insert(&self.url, notes);
        serializer.serialize_str(&serde_json::to_string(&hash).map_err(S::Error::custom)?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_serialize_to_json() {
        let access = ElectronicAccess {
            url: "http://arks.princeton.edu/ark:/88435/dch989rf19q".to_owned(),
            link_text: "Electronic Resource".to_owned(),
            link_description: None,
        };
        assert_eq!(
            serde_json::to_string(&access).unwrap(),
            r#""{\"http://arks.princeton.edu/ark:/88435/dch989rf19q\":[\"Electronic Resource\"]}""#
        );
    }
}
