// This module is responsible for determining the visibility of a
// Figgy resource

use serde::Deserialize;
use serde_json::Value;

#[derive(Debug, PartialEq)]
pub enum Visibility {
    Open,
    Private,
    Unknown,
}

impl From<&Value> for Visibility {
    fn from(json: &Value) -> Self {
        json.as_object()
            .and_then(|item| item.get("visibility"))
            .and_then(|raw_visibility| serde_json::from_value(raw_visibility.clone()).ok())
            .map(|figgy_visibility: FiggyVisibilityData| Visibility::from(figgy_visibility))
            .unwrap_or(Self::Unknown)
    }
}

// How figgy visibility is expressed in the report
#[derive(Deserialize)]
struct FiggyVisibilityData {
    label: String,
}

impl From<FiggyVisibilityData> for Visibility {
    fn from(value: FiggyVisibilityData) -> Self {
        match value.label.as_str() {
            "open" => Self::Open,
            "private" => Self::Private,
            _ => Self::Unknown,
        }
    }
}

#[cfg(test)]
mod tests {
    use serde_json::json;

    use super::*;

    #[test]
    fn it_can_determine_open_from_json() {
        let json = json!({"visibility": {
          "value": "open",
          "label": "open",
          "definition": "Open to the world. Anyone can view."
        }});

        assert_eq!(Visibility::from(&json), Visibility::Open);
    }

    #[test]
    fn it_can_determine_private_from_json() {
        let json = json!({"visibility": {
          "value": "restricted",
          "label": "private",
          "definition": "Only privileged users of this application can view."
        }});

        assert_eq!(Visibility::from(&json), Visibility::Private);
    }
}
