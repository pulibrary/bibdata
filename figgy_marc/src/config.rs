// This module is responsible for the configuration
// of how we access Figgy, cache our data, etc.

use crate::error::FiggyMarcError;
use std::env::VarError;
use std::fmt::Debug;
use std::str::FromStr;

#[derive(Debug, Default, PartialEq)]
pub enum AppEnvironment {
    #[default]
    Development,
    Test,
    Production,
    Staging,
    QA,
}

pub struct UnknownAppEnvironment;

impl FromStr for AppEnvironment {
    type Err = UnknownAppEnvironment;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "development" => Ok(Self::Development),
            "test" => Ok(Self::Test),
            "production" => Ok(Self::Production),
            "staging" => Ok(Self::Staging),
            "qa" => Ok(Self::QA),
            _ => Err(UnknownAppEnvironment),
        }
    }
}

#[derive(PartialEq)]
pub struct FiggyConfig {
    figgy_url: String,
    figgy_sync_token: String,
    app_environment: AppEnvironment,
}

impl Debug for FiggyConfig {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("FiggyMarcConfig")
            .field("figgy_url", &self.figgy_url)
            .field("figgy_sync_token", &self.redacted_sync_token())
            .finish()
    }
}

// A trait and blanket implementation for functions similar to std::env::var
pub trait EnvVar<'a>: Fn(&'a str) -> Result<String, VarError> + Copy {}
impl<'a, F> EnvVar<'a> for F where F: Copy + Fn(&'a str) -> Result<String, VarError> + 'a {}

impl FiggyConfig {
    // Typical usage:
    // ```
    // use std::env;
    // let config = FiggyMarcConfig::try_new(env::var)?;
    // ```
    pub fn try_new<'a>(env: impl EnvVar<'a>) -> Result<Self, FiggyMarcError<'a>> {
        let app_environment = get_from_env(env, "RAILS_ENV")
            .map(|rails_env| rails_env.parse().unwrap_or_default())
            .unwrap_or_default();
        Ok(Self {
            figgy_url: get_from_env(env, "FIGGY_URL")?,
            figgy_sync_token: get_from_env(env, "CATALOG_SYNC_TOKEN")?,
            app_environment,
        })
    }

    pub fn new(
        figgy_url: String,
        figgy_sync_token: String,
        app_environment: AppEnvironment,
    ) -> Self {
        Self {
            figgy_url,
            figgy_sync_token,
            app_environment,
        }
    }

    pub fn figgy_url(&self) -> &str {
        &self.figgy_url
    }

    // This should only be used for connecting to Figgy,
    // if you need to print something to logs or for
    // troubleshooting, use redacted_sync_token()
    pub fn private_figgy_sync_token(&self) -> &str {
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
}

#[derive(Debug, PartialEq)]
pub struct RedisConfig {
    redis_url: String,
    redis_port: String,
    redis_db: String,
}

impl RedisConfig {
    pub fn redis_url(&self) -> &str {
        &self.redis_url
    }

    pub fn redis_db(&self) -> &str {
        &self.redis_db
    }

    pub fn redis_port(&self) -> &str {
        &self.redis_port
    }
}

impl<'a, E> From<E> for RedisConfig
where
    E: EnvVar<'a>,
{
    fn from(env: E) -> Self {
        let app_environment = get_from_env(env, "RAILS_ENV")
            .map(|rails_env| rails_env.parse().unwrap_or_default())
            .unwrap_or_default();
        Self {
            redis_url: get_from_env(env, "BIBDATA_REDIS_URL")
                .or(get_from_env(env, "lando_bibdata_redis_conn_host"))
                .unwrap_or("localhost".to_owned()),
            redis_port: get_from_env(env, "BIBDATA_REDIS_PORT")
                .or(get_from_env(env, "lando_bibdata_redis_conn_port"))
                .unwrap_or("6379".to_string()),
            redis_db: get_from_env(env, "BIBDATA_REDIS_DB").unwrap_or(match app_environment {
                AppEnvironment::Development => "1".to_string(),
                AppEnvironment::Test => "2".to_string(),
                _ => "6".to_string(),
            }),
        }
    }
}

fn get_from_env<'a>(env: impl EnvVar<'a>, key: &'a str) -> Result<String, FiggyMarcError<'a>> {
    env(key).map_err(|e| FiggyMarcError::InvalidEnvironmentVariable(key, e))
}

#[cfg(test)]
mod tests {
    use std::collections::HashMap;

    use super::*;
    use crate::test_helpers::{FiggyConfigBuilder, fake_environment};

    #[test]
    fn it_can_set_figgy_config_from_the_environment() {
        let vars = HashMap::from([
            ("FIGGY_URL", "https://figgy.example.com"),
            ("CATALOG_SYNC_TOKEN", "FAKE_TOKEN"),
        ]);
        let get_env_var = fake_environment(&vars);

        let config = FiggyConfig::try_new(get_env_var).unwrap();
        assert_eq!(config.figgy_url(), "https://figgy.example.com");
        assert_eq!(config.private_figgy_sync_token(), "FAKE_TOKEN");
    }

    #[test]
    fn it_can_set_redis_config_from_the_environment() {
        let vars = HashMap::from([
            ("BIBDATA_REDIS_URL", "my-redis.example.com"),
            ("BIBDATA_REDIS_PORT", "1234"),
        ]);
        let get_env_var = fake_environment(&vars);

        let config = RedisConfig::from(get_env_var);
        assert_eq!(config.redis_url(), "my-redis.example.com");
        assert_eq!(config.redis_port(), "1234");
    }

    #[test]
    fn in_development_default_to_redis_db_1() {
        let vars = HashMap::from([("RAILS_ENV", "development")]);
        let get_env_var = fake_environment(&vars);

        assert_eq!(RedisConfig::from(get_env_var).redis_db(), "1");
    }

    #[test]
    fn in_test_default_to_redis_db_2() {
        let vars = HashMap::from([("RAILS_ENV", "test")]);
        let get_env_var = fake_environment(&vars);

        assert_eq!(RedisConfig::from(get_env_var).redis_db(), "2");
    }

    #[test]
    fn in_prod_default_to_redis_db_6() {
        let vars = HashMap::from([("RAILS_ENV", "production")]);
        let get_env_var = fake_environment(&vars);

        assert_eq!(RedisConfig::from(get_env_var).redis_db(), "6");
    }

    #[test]
    fn it_can_redact_the_token() {
        assert_eq!(
            FiggyConfigBuilder::new()
                .with_figgy_sync_token("MY_TOKEN".to_owned())
                .build()
                .redacted_sync_token(),
            "****OKEN"
        );
        assert_eq!(
            FiggyConfigBuilder::new()
                .with_figgy_sync_token("123".to_owned())
                .build()
                .redacted_sync_token(),
            "***"
        );
    }
}
