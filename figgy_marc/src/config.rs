// This module is responsible for the configuration
// of how we access Figgy, cache our data, etc.

use std::env::VarError;
use std::fmt::Debug;

use crate::error::FiggyMarcError;

#[derive(PartialEq)]
pub struct FiggyMarcConfig {
    figgy_url: String,
    figgy_sync_token: String,
}

impl Debug for FiggyMarcConfig {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("FiggyMarcConfig")
            .field("figgy_url", &self.figgy_url)
            .field("figgy_sync_token", &self.redacted_sync_token())
            .finish()
    }
}

type GetEnvVar<K> = fn(K) -> Result<String, VarError>;

impl FiggyMarcConfig {
    // Typical usage:
    // ```
    // use std::env;
    // let config = FiggyMarcConfig::try_new(env::var)?;
    // ```
    pub fn try_new(env: GetEnvVar<&str>) -> Result<Self, FiggyMarcError<'_>> {
        Ok(Self {
            figgy_url: Self::get(env, "FIGGY_URL")?,
            figgy_sync_token: Self::get(env, "CATALOG_SYNC_TOKEN")?,
        })
    }

    pub fn new(figgy_url: String, figgy_sync_token: String) -> Self {
        Self {
            figgy_url,
            figgy_sync_token,
        }
    }

    pub fn figgy_url(&self) -> &str {
        &self.figgy_url
    }

    pub fn figgy_sync_token(&self) -> &str {
        &self.figgy_sync_token
    }

    pub fn redacted_sync_token(&self) -> String {
        let length = self.figgy_sync_token.len();
        let end_redaction_at_char = length.checked_sub(4).unwrap_or(length);
        let should_show = |char_index: usize| char_index >= end_redaction_at_char;
        self.figgy_sync_token
            .chars()
            .enumerate()
            .map(|(index, char)| if should_show(index) { char } else { '*' })
            .collect()
    }

    fn get<'a>(env: GetEnvVar<&'a str>, key: &'a str) -> Result<String, FiggyMarcError<'a>> {
        env(key).map_err(|e| FiggyMarcError::InvalidEnvironmentVariable(key, e))
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_set_from_the_environment() {
        let get_env_var: GetEnvVar<&str> = |key| match key {
            "FIGGY_URL" => Ok("https://figgy.example.com".to_owned()),
            "CATALOG_SYNC_TOKEN" => Ok("FAKE_TOKEN".to_owned()),
            _ => Err(VarError::NotPresent),
        };

        let config = FiggyMarcConfig::try_new(get_env_var).unwrap();
        assert_eq!(config.figgy_url(), "https://figgy.example.com");
        assert_eq!(config.figgy_sync_token(), "FAKE_TOKEN");
    }

    #[test]
    fn it_can_redact_the_token() {
        assert_eq!(
            FiggyMarcConfig::new("url".into(), "MY_TOKEN".into()).redacted_sync_token(),
            "****OKEN"
        );
        assert_eq!(
            FiggyMarcConfig::new("url".into(), "123".into()).redacted_sync_token(),
            "***"
        );
    }
}
