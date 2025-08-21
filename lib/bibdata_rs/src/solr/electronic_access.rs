use serde::{ser::Error, Deserialize, Deserializer, Serialize};
use std::collections::HashMap;

#[derive(Clone, Debug, PartialEq)]
pub struct ElectronicAccess {
    pub url: String,
    pub link_text: String,
    pub link_description: Option<String>,
    pub iiif_manifest_url: Option<String>,
    pub digital_content: Option<DigitalContent>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct DigitalContent {
    pub url: String,
    pub link_text: Vec<String>,
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

impl<'de> Deserialize<'de> for ElectronicAccess {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        // The input is a JSON string containing a map: {url: [link_text, link_description?]}
        let s = String::deserialize(deserializer)?;
        let map: HashMap<String, Vec<String>> =
            serde_json::from_str(&s).map_err(serde::de::Error::custom)?;
        let url = map.keys().next().ok_or(serde::de::Error::custom(
            "No url found in this ElectronicAccess",
        ))?;
        let mut details = map
            .get(url)
            .ok_or(serde::de::Error::custom(
                "No url details found in this ElectronicAccess",
            ))?
            .iter();
        let link_text = details.next().ok_or(serde::de::Error::custom(
            "No link text found in this ElectronicAccess",
        ))?;
        let link_description = details.next();
        Ok(ElectronicAccess {
            url: url.to_owned(),
            link_text: link_text.to_owned(),
            link_description: link_description.cloned(),
            iiif_manifest_url: None,
            digital_content: None,
        })
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
            iiif_manifest_url: None,
            digital_content: None,
        };
        assert_eq!(
            serde_json::to_string(&access).unwrap(),
            r#""{\"http://arks.princeton.edu/ark:/88435/dch989rf19q\":[\"Electronic Resource\"]}""#
        );
    }

    #[test]
    fn it_can_deserialize_from_json() {
        let json =
            r#""{\"http://arks.princeton.edu/ark:/88435/dch989rf19q\":[\"Electronic Resource\"]}""#;
        let parsed: ElectronicAccess = serde_json::from_str(&json).unwrap();
        assert_eq!(
            parsed.url,
            "http://arks.princeton.edu/ark:/88435/dch989rf19q"
        );
        assert_eq!(parsed.link_text, "Electronic Resource");
        assert!(parsed.link_description.is_none());
    }

    #[test]
    fn it_can_deserialize_electronic_access_with_link_description_from_json() {
        let json = r#""{\"http://arks.princeton.edu/ark:/88435/dch989rf19q\":[\"Electronic Resource\",\"My nice description\"]}""#;
        let parsed: ElectronicAccess = serde_json::from_str(&json).unwrap();
        assert_eq!(
            parsed.url,
            "http://arks.princeton.edu/ark:/88435/dch989rf19q"
        );
        assert_eq!(parsed.link_text, "Electronic Resource");
        assert_eq!(parsed.link_description.unwrap(), "My nice description");
    }
}
