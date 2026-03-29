// This module is concerned with the 035 (system control number)

use std::borrow::Cow;
use crate::marc::{extract_values::ExtractValues, identifier::oclc::is_oclc_number};
use marctk::Record;

pub enum SystemControlNumber {
    Pulfa(String),
    OCLCNumber(String),
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
        } else if is_oclc_number(value) {
            Self::OCLCNumber(value.to_owned())
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

pub fn standard_numbers<'a>(record: &'a Record) -> impl Iterator<Item = Cow<'a, str>> {
    record.extract_field_values_by(
        |field| field.tag() == "035",
        |field| {
            field.first_subfield("a").map(|original| {
                if original.content().starts_with('(') {
                    Cow::Owned(
                        original
                            .content()
                            .chars()
                            .skip_while(|x| x != &')')
                            .skip(1) // skip the closing Paren
                            .collect()
                    )
                } else {
                    Cow::Borrowed(original.content())
                }
            })
        }
    )
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_find_standard_numbers() {
        let record = Record::from_breaker("=035 \\$a(OCoLC)ocn179901451").unwrap();
        let mut numbers = standard_numbers(&record);
        let normalized = numbers.next().unwrap();
        assert_eq!(normalized, "ocn179901451");
        assert!(numbers.next().is_none());
    }
}
