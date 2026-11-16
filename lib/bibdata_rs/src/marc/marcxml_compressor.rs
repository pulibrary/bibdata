use base64::prelude::*;
use flate2::{Compression, write::GzEncoder};
use marctk::Record;
use std::io::Write;

pub fn marcxml_compressed(record: &Record) -> String {
    let marcxml_string = record.to_xml_string();
    let mut encoder = GzEncoder::new(Vec::new(), Compression::default());
    encoder.write_all(marcxml_string.as_bytes()).unwrap();
    let marcxml_compressed = encoder.finish().unwrap();
    BASE64_STANDARD.encode(marcxml_compressed)
}

#[cfg(test)]
mod tests {
    use super::marcxml_compressed;
    use std::assert_matches;

    use crate::marc::control_field::control_number::ControlNumber;
    use marctk::Record;

    #[test]
    fn test_marcxml_compressed_alma_record() {
        let alma_record = Record::from_breaker("=001 991234506421").unwrap();
        let compressed = marcxml_compressed(&alma_record);
        assert!(!compressed.is_empty());
        assert_matches!(
            ControlNumber::from(&alma_record),
            ControlNumber::Alma("991234506421")
        );
    }
    #[test]
    fn test_marcxml_compressed_scsb_record() {
        let scsb_record = Record::from_breaker("=001 SCSB-12345").unwrap();
        let compressed = marcxml_compressed(&scsb_record);
        assert!(!compressed.is_empty());
        assert_matches!(
            ControlNumber::from(&scsb_record),
            ControlNumber::SCSB("SCSB-12345")
        );
    }
}
