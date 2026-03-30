// This package is responsible for getting information
// about MARC records from Figgy

mod config;
mod error;
mod mms_records_report;
mod visibility;

pub use config::FiggyMarcConfig;
pub use mms_records_report::fetch_report;
pub use mms_records_report::only_open;
pub use visibility::Visibility;
