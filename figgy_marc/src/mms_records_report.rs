// This module is responsible for working with Figgy's MMS
// Records Report.

use std::{collections::HashMap, time::Duration};

use crate::{Visibility, config::FiggyConfig, error::FiggyMarcError};
use reqwest::StatusCode;

pub type FiggyItems = Vec<serde_json::Value>;
pub type FiggyMmsIdCache = HashMap<String, FiggyItems>;

pub fn fetch_report(config: &FiggyConfig) -> Result<FiggyMmsIdCache, FiggyMarcError<'_>> {
    let url = format!(
        "{}/reports/mms_records.json?auth_token={}",
        config.figgy_url(),
        config.private_figgy_sync_token()
    );
    let client = reqwest::blocking::Client::new();
    let response = client
        .get(url)
        .timeout(Duration::from_mins(3))
        .send()
        .map_err(FiggyMarcError::CouldNotConnectToFiggy)?;
    match response.status() {
        StatusCode::FORBIDDEN | StatusCode::UNAUTHORIZED => {
            Err(FiggyMarcError::CouldNotAuthenticateToFiggy(config))
        }
        _ => Ok(response
            .json()
            .map_err(FiggyMarcError::CouldNotParseReportBody)?),
    }
}

pub fn only_open(full_cache: &FiggyMmsIdCache) -> FiggyMmsIdCache {
    full_cache
        .iter()
        .filter_map(|(mms_id, figgy_items)| {
            let open_items: Vec<_> = figgy_items
                .iter()
                .filter_map(|item| {
                    if matches!(Visibility::from(item), Visibility::Open) {
                        Some(item.clone())
                    } else {
                        None
                    }
                })
                .collect();
            if open_items.is_empty() {
                None
            } else {
                Some((mms_id.clone(), open_items))
            }
        })
        .collect()
}

pub fn ark_eq(ark: &str, json: &serde_json::Value) -> bool {
    json.as_object()
        .and_then(|object| object.get("ark"))
        .map(|json_ark| json_ark.as_str() == Some(ark))
        .unwrap_or(false)
}

pub fn iiif_manifest_url(json: &serde_json::Value) -> Option<&str> {
    json.as_object()
        .and_then(|object| object.get("iiif_manifest_url"))
        .and_then(|manifest| manifest.as_str())
}

#[cfg(test)]
mod tests {
    use crate::test_helpers::FiggyConfigBuilder;

    use super::*;
    use mockito::Matcher;
    use serde_json::json;

    const BASIC_RESPONSE: &str = r#"{
  "99129146648906421": [
    {
      "visibility": {
        "value": "restricted",
        "label": "private",
        "definition": "Only privileged users of this application can view."
      },
      "portion_note": null,
      "iiif_manifest_url": "https://figgy.princeton.edu/concern/scanned_resources/1ab2345-bde9-4165-ba00-4eb0e772e145/manifest"
    }
  ]
}"#;

    #[test]
    fn it_sends_the_auth_token() {
        let mut server = mockito::Server::new();
        let config = FiggyConfigBuilder::new()
            .with_figgy_sync_token("FAKE_TOKEN".into())
            .with_figgy_url(server.url())
            .build();

        let mock = server
            .mock("GET", "/reports/mms_records.json")
            .with_body(BASIC_RESPONSE)
            .match_query(Matcher::UrlEncoded(
                "auth_token".into(),
                "FAKE_TOKEN".into(),
            ))
            .create();

        fetch_report(&config).unwrap();

        mock.assert();
    }

    #[test]
    fn it_returns_error_if_forbidden() {
        let mut server = mockito::Server::new();
        let config = FiggyConfigBuilder::new()
            .with_figgy_sync_token("BAD_TOKEN".into())
            .with_figgy_url(server.url())
            .build();

        let mock = server
            .mock("GET", "/reports/mms_records.json?auth_token=BAD_TOKEN")
            .with_status(403)
            .create();

        assert!(matches!(
            fetch_report(&config),
            Err(FiggyMarcError::CouldNotAuthenticateToFiggy(_))
        ));
        mock.assert();
    }

    #[test]
    fn it_can_tell_if_ark_is_equal_to_ark_in_json_object() {
        let json = json!({"ark":"http://arks.princeton.edu/ark:/88435/dc08613099f","iiif_manifest_url":"https://figgy.princeton.edu/concern/scanned_resources/4abf0d8c-a64a-4422-a3f4-229fd9b3b28d/manifest","label":{"@value":"Stress Analysis of Coil Support Frames for B-3 Machine.","@language":"en"},"portion_note":null,"visibility":{"value":"open","label":"open","definition":"Open to the world. Anyone can view."}});
        assert!(ark_eq(
            "http://arks.princeton.edu/ark:/88435/dc08613099f",
            &json
        ));
        assert!(!ark_eq(
            "http://arks.princeton.edu/ark:/i/do/not/match",
            &json
        ));
    }

    #[test]
    fn it_can_get_the_iiif_manifest_url_from_json_object() {
        let json = json!({"ark":"http://arks.princeton.edu/ark:/88435/dc08613099f","iiif_manifest_url":"https://figgy.princeton.edu/concern/scanned_resources/4abf0d8c-a64a-4422-a3f4-229fd9b3b28d/manifest","label":{"@value":"Stress Analysis of Coil Support Frames for B-3 Machine.","@language":"en"},"portion_note":null,"visibility":{"value":"open","label":"open","definition":"Open to the world. Anyone can view."}});
        assert_eq!(
            iiif_manifest_url(&json),
            Some(
                "https://figgy.princeton.edu/concern/scanned_resources/4abf0d8c-a64a-4422-a3f4-229fd9b3b28d/manifest"
            )
        );
        assert_eq!(iiif_manifest_url(&json!({})), None);
    }
}
