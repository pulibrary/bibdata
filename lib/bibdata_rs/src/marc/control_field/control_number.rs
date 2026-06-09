// This module is concerned with the Control Number (found in field 001)

use marctk::Record;

#[derive(Debug)]
pub enum ControlNumber<'a> {
    Alma(&'a str),
    SCSB(&'a str),
    Unknown(&'a str),
    Missing,
}

impl<'a> From<&'a Record> for ControlNumber<'a> {
    fn from(record: &'a Record) -> Self {
        match record.get_control_fields("001").first() {
            Some(field) => Self::from(field.content()),
            _ => Self::Missing,
        }
    }
}

impl<'a> From<&'a str> for ControlNumber<'a> {
    fn from(string: &'a str) -> Self {
        match string {
            string if string.starts_with("SCSB-") => Self::SCSB(string),
            string if string.starts_with("99") && string.ends_with("06421") => Self::Alma(string),
            _ => Self::Unknown(string),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::assert_matches;

    #[test]
    fn it_can_detect_alma_record() {
        let record = Record::from_breaker("=001 9912606733506421").unwrap();
        assert_matches!(
            ControlNumber::from(&record),
            ControlNumber::Alma("9912606733506421")
        );
    }
}
