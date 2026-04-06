use crate::marc::control_field::control_number::ControlNumber;
use marctk::Record;

mod collection_group;
pub mod recap_partner;

// We use this SCSB check for multiple workflows
pub fn is_scsb(record: &Record) -> bool {
    matches!(ControlNumber::from(record), ControlNumber::SCSB(_))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_tell_if_record_is_scsb() {
        let scsb_record = Record::from_breaker("=001 SCSB-12345").unwrap();
        let alma_record = Record::from_breaker("=001 991234506421").unwrap();
        assert!(is_scsb(&scsb_record));
        assert!(!is_scsb(&alma_record));
    }
}
