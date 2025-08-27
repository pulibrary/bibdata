use serde::{ser::Error, Deserialize, Deserializer, Serialize};

#[derive(Clone, Debug, PartialEq)]
pub struct ElectronicAccess {
    pub url: String,
    pub link_text: String,
    pub link_description: Option<String>,
    pub iiif_manifest_paths: Option<String>,
    pub digital_content: Option<DigitalContent>,
    pub thumbnail: Option<Thumbnail>,
}

#[derive(Clone, Debug, PartialEq)]
pub struct DigitalContent {
    pub url: String,
    pub link_text: Vec<String>,
}
#[derive(Deserialize, Serialize, Debug, Clone, PartialEq)]
pub struct Thumbnail {
    #[serde(rename = "@id")]
    pub id: String,
}

impl Serialize for ElectronicAccess {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        let mut hash = serde_json::Map::new();

        // Main URL
        let mut notes = vec![self.link_text.clone()];
        if let Some(desc) = &self.link_description {
            notes.push(desc.clone());
        }
        hash.shift_insert(
            0,
            self.url.clone(),
            serde_json::Value::Array(notes.into_iter().map(serde_json::Value::String).collect()),
        );

        // Digital Content
        if let Some(dc) = &self.digital_content {
            hash.shift_insert(
                1,
                dc.url.clone(),
                serde_json::Value::Array(
                    dc.link_text
                        .iter()
                        .cloned()
                        .map(serde_json::Value::String)
                        .collect(),
                ),
            );
        }

        // IIIF Manifest Paths
        if let Some(iiif_url) = &self.iiif_manifest_paths {
            let mut iiif_map = serde_json::Map::new();
            iiif_map.insert(
                "ephemera_ark".to_string(),
                serde_json::Value::String(iiif_url.clone()),
            );
            hash.shift_insert(
                2,
                "iiif_manifest_paths".to_string(),
                serde_json::Value::Object(iiif_map),
            );
        }

        serializer.serialize_str(&serde_json::to_string(&hash).map_err(S::Error::custom)?)
    }
}

impl<'de> Deserialize<'de> for ElectronicAccess {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        // The input is a JSON string containing a map with possible keys:
        // {url: [link_text, link_description?], digital_content_url: [link_text], iiif_manifest_paths: {ephemera_ark: url}}
        let s = String::deserialize(deserializer)?;
        let map: serde_json::Map<String, serde_json::Value> =
            serde_json::from_str(&s).map_err(serde::de::Error::custom)?;

        // Main URL and notes
        let (url, notes) = map
            .iter()
            .find(|(k, _)| *k != "iiif_manifest_paths" && *k != "digital_content_url")
            .ok_or_else(|| serde::de::Error::custom("No url found in this ElectronicAccess"))?;

        let notes_arr = notes
            .as_array()
            .ok_or_else(|| serde::de::Error::custom("Notes are not an array"))?;

        let link_text = notes_arr
            .first()
            .and_then(|v| v.as_str())
            .ok_or_else(|| serde::de::Error::custom("No link text found in this ElectronicAccess"))?
            .to_owned();

        let link_description = notes_arr
            .get(1)
            .and_then(|v| v.as_str())
            .map(|s| s.to_owned());

        // Digital Content
        let digital_content = map
            .iter()
            .find(|(k, _)| *k != "iiif_manifest_paths" && *k != url)
            .and_then(|(dc_url, dc_notes)| {
                let dc_notes_arr = dc_notes.as_array()?;
                let dc_link_texts: Vec<String> = dc_notes_arr
                    .iter()
                    .filter_map(|v| v.as_str().map(|s| s.to_owned()))
                    .collect();
                if dc_link_texts.is_empty() {
                    None
                } else {
                    Some(DigitalContent {
                        url: dc_url.clone(),
                        link_text: dc_link_texts,
                    })
                }
            });

        // IIIF Manifest URL
        let iiif_manifest_url = map
            .get("iiif_manifest_paths")
            .and_then(|v| v.as_object())
            .and_then(|obj| obj.get("ephemera_ark"))
            .and_then(|v| v.as_str())
            .map(|s| s.to_owned());

        Ok(ElectronicAccess {
            url: url.clone(),
            link_text,
            link_description,
            iiif_manifest_paths: iiif_manifest_url,
            digital_content,
            thumbnail: None
        })
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    use pretty_assertions::assert_eq;

    #[test]
    fn it_can_serialize_digital_content_to_json() {
        let access = ElectronicAccess {
            url: "https://figgy-staging.princeton.edu/catalog/af4a941d-96a4-463e-9043-cfa512e5eddd".to_string(),
            link_text: "Online Content".to_string(),
            link_description: Some("Born Digital Monographic Reports and Papers".to_string()),
            iiif_manifest_paths: Some("https://figgy.princeton.edu/concern/ephemera_folders/af4a941d-96a4-463e-9043-cfa512e5eddd/manifest".to_string()),
            digital_content: Some(DigitalContent {
                link_text: vec!["Digital Content".to_string()],
                url: "https://catalog-staging.princeton.edu/catalog/af4a941d-96a4-463e-9043-cfa512e5eddd#view".to_string(),
            }),
            thumbnail: None
        };
        assert_eq!(
            serde_json::to_string(&access).unwrap(),
            r#""{\"https://figgy-staging.princeton.edu/catalog/af4a941d-96a4-463e-9043-cfa512e5eddd\":[\"Online Content\",\"Born Digital Monographic Reports and Papers\"],\"https://catalog-staging.princeton.edu/catalog/af4a941d-96a4-463e-9043-cfa512e5eddd#view\":[\"Digital Content\"],\"iiif_manifest_paths\":{\"ephemera_ark\":\"https://figgy.princeton.edu/concern/ephemera_folders/af4a941d-96a4-463e-9043-cfa512e5eddd/manifest\"}}""#
        );
    }
    #[test]
    fn it_can_serialize_to_json() {
        let access = ElectronicAccess {
            url: "http://arks.princeton.edu/ark:/88435/dch989rf19q".to_owned(),
            link_text: "Electronic Resource".to_owned(),
            link_description: None,
            iiif_manifest_paths: None,
            digital_content: None,
            thumbnail: None
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
