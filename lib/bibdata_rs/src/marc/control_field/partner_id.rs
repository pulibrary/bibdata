//! This module is concerned with the record IDs from our partner libraries

use marctk::Record;

/// Our partner library's record ID (stored in the 009 of records that we get from SCSB)
pub fn other_id(record: &Record) -> Option<String> {
    record
        .get_control_fields("009")
        .first()
        .map(|field| field.content().to_owned())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_returns_none_for_records_without_009() {
        let record = Record::default();
        assert!(other_id(&record).is_none());
    }

    #[test]
    fn it_returns_the_content_of_field_009() {
        let record = Record::from_breaker("=009 .b118131060").unwrap();
        assert_eq!(other_id(&record), Some(".b118131060".to_owned()));
    }

    #[test]
    fn it_returns_only_the_first_009_field() {
        let record = Record::from_breaker(
            "=009 first_value
=009 second_value",
        )
        .unwrap();
        assert_eq!(other_id(&record), Some("first_value".to_owned()));
    }
}
