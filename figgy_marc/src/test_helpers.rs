use std::{collections::HashMap, env::VarError};

use crate::{
    FiggyConfig,
    config::{AppEnvironment, EnvVar},
};

#[derive(Default)]
pub struct FiggyConfigBuilder {
    figgy_url: String,
    figgy_sync_token: String,
    app_environment: AppEnvironment,
}
impl FiggyConfigBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_figgy_url(mut self, figgy_url: String) -> Self {
        self.figgy_url = figgy_url;
        self
    }

    pub fn with_figgy_sync_token(mut self, figgy_sync_token: String) -> Self {
        self.figgy_sync_token = figgy_sync_token;
        self
    }

    pub fn build(self) -> FiggyConfig {
        FiggyConfig::new(self.figgy_url, self.figgy_sync_token, self.app_environment)
    }
}

pub fn fake_environment<'a>(values: &'a HashMap<&'a str, &'a str>) -> impl EnvVar<'a> {
    |key| match values.get(key) {
        Some(value) => Ok(value.to_string()),
        _ => Err(VarError::NotPresent),
    }
}
