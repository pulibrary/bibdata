use crate::config::FiggyMarcConfig;
use std::{env::VarError, error::Error, fmt::Display};

#[derive(Debug)]
pub enum FiggyMarcError<'a> {
    CouldNotAuthenticateToFiggy(&'a FiggyMarcConfig),
    CouldNotConnectToFiggy(reqwest::Error),
    CouldNotParseReportBody(reqwest::Error),
    InvalidEnvironmentVariable(&'a str, VarError),
}

impl<'a> Display for FiggyMarcError<'a> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(f, "{:?}", self)
    }
}

impl<'a> Error for FiggyMarcError<'a> {
    fn source(&self) -> Option<&(dyn Error + 'static)> {
        match self {
            Self::CouldNotConnectToFiggy(e) => Some(e),
            Self::InvalidEnvironmentVariable(_, e) => Some(e),
            _ => None,
        }
    }
}
