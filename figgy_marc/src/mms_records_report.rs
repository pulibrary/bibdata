// This module is responsible for working with Figgy's MMS
// Records Report.

use std::{collections::HashMap, time::Duration};

use crate::{Visibility, config::FiggyMarcConfig, error::FiggyMarcError};
use reqwest::StatusCode;

pub fn fetch_report(
    config: &FiggyMarcConfig,
) -> Result<HashMap<String, Vec<serde_json::Value>>, FiggyMarcError<'_>> {
    let url = format!(
        "{}/reports/mms_records.json?auth_token={}",
        config.figgy_url(),
        config.figgy_sync_token()
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

pub fn only_open(
    documents: &HashMap<String, Vec<serde_json::Value>>,
) -> HashMap<String, Vec<serde_json::Value>> {
    documents
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

#[cfg(test)]
mod tests {
    use super::*;
    use mockito::Matcher;

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
        let config = FiggyMarcConfig::new(server.url(), "FAKE_TOKEN".into());

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
        let config = FiggyMarcConfig::new(server.url(), "BAD_TOKEN".into());

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
}
