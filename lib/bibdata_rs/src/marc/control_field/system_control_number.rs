// This module is concerned with the 035 (system control number)

use marctk::Record;

pub enum SystemControlNumber {
    Pulfa(String),
    OtherControlNumber,
    InvalidControlNumber,
}

impl From<&str> for SystemControlNumber {
    fn from(value: &str) -> Self {
        if value.starts_with("(PULFA)") {
            match value.split(')').next_back() {
                Some(number) => SystemControlNumber::Pulfa(number.to_owned()),
                None => SystemControlNumber::InvalidControlNumber,
            }
        } else {
            SystemControlNumber::OtherControlNumber
        }
    }
}

pub fn system_control_numbers(record: &Record) -> Vec<SystemControlNumber> {
    record
        .extract_values("035a")
        .iter()
        .map(|value| SystemControlNumber::from(value.as_str()))
        .collect()
}

pub fn is_princeton_finding_aid(record: &Record) -> bool {
    system_control_numbers(record)
        .iter()
        .any(|number| matches!(number, SystemControlNumber::Pulfa(_)))
}
