// This module is responsible for working with Figgy's MMS
// Records Report.

use std::{collections::HashMap, time::Duration};

use crate::{config::FiggyMarcConfig, error::FiggyMarcError};
use reqwest::StatusCode;

pub fn fetch_report(
    config: &FiggyMarcConfig,
) -> Result<HashMap<String, serde_json::Value>, FiggyMarcError<'_>> {
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

#[cfg(test)]
mod tests {
    use mockito::Matcher;

    use super::*;

    #[test]
    fn it_sends_the_auth_token() {
        let mut server = mockito::Server::new();
        let config = FiggyMarcConfig::new(server.url(), "FAKE_TOKEN".into());

        let mock = server
            .mock("GET", "/reports/mms_records.json")
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
