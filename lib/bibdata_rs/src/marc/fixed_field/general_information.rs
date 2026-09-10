//! This module is focused on the MARC field 008 (Fixed-Length Data Elements-General Information)

use marctk::Record;
use std::range::Range;

pub const TYPE_OF_DATE_INDEX: usize = 6;

/// Get the desired byte from the MARC 008 field
pub fn char_from_008(record: &Record, index: usize) -> Option<char> {
    record
        .get_control_fields("008")
        .first()
        .and_then(|field| field.content().chars().nth(index))
}

/// Get the desired slice from the MARC 008 field
pub fn slice_from_008(record: &Record, range: impl Into<Range<usize>>) -> Option<&str> {
    record
        .get_control_fields("008")
        .first()
        .and_then(|field| field.content().get(range.into()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_get_a_single_char_from_008() {
        let record = Record::from_breaker("=008 940720d19761979it mr         0   a0ita d").unwrap();
        assert_eq!(char_from_008(&record, TYPE_OF_DATE_INDEX), Some('d'));
    }

    #[test]
    fn it_does_not_get_a_char_if_008_is_weirdly_short() {
        let record = Record::from_breaker("=008 123").unwrap();
        assert_eq!(char_from_008(&record, TYPE_OF_DATE_INDEX), None);
    }

    #[test]
    fn it_does_not_get_a_char_if_no_008() {
        let record = Record::from_breaker("=245 00$Hello").unwrap();
        assert_eq!(char_from_008(&record, TYPE_OF_DATE_INDEX), None);
    }

    #[test]
    fn it_can_get_a_slice_from_008() {
        let record = Record::from_breaker("=008 940720d19761979it mr         0   a0ita d").unwrap();
        assert_eq!(slice_from_008(&record, 0..6), Some("940720"));
    }
}
