// This package is responsible for getting information
// about MARC records from Figgy

mod config;
mod error;
mod mms_records_report;

pub use config::FiggyMarcConfig;
pub use mms_records_report::fetch_report;
