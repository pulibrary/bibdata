use super::string_normalize::strip_non_numeric;
use isbn::normalized_isbns_for_all_versions;
use issn::normalized_issns_for_all_versions;
use marctk::Record;
use oclc::normalized_oclc_numbers;

mod isbn;
mod issn;
pub mod oclc;

pub use oclc::is_oclc_number;
pub use oclc::normalize_oclc_number;

// Get identifier numbers for all known versions of this title from the record.
// This is used to link records together in the catalog's Other Versions feature.
pub fn identifiers_of_all_versions(record: &Record) -> Vec<String> {
    normalized_isbns_for_all_versions(record)
        .chain(normalized_issns_for_all_versions(record))
        .chain(normalized_oclc_numbers(record))
        .chain(linked_record_control_numbers(record))
        .collect()
}

const FALLBACK_STANDARD_NO: &str = "Other standard number";
pub fn map_024_indicators_to_labels(indicator: char) -> &'static str {
    match indicator {
        '0' => "International Standard Recording Code",
        '1' => "Universal Product Code",
        '2' => "International Standard Music Number",
        '3' => "International Article Number",
        '4' => "Serial Item and Contribution Identifier",
        '7' => "$2",
        _ => FALLBACK_STANDARD_NO,
    }
}

// Record control numbers can either be OCLC numbers (which are normalized to a format like ocn991350412)
// or some other type of control number (which are normalized and include the prefix BIB)
fn linked_record_control_numbers(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_values("776w:787w")
        .into_iter()
        .filter_map(|value| {
            if is_oclc_number(value) {
                Some(normalize_oclc_number(value))
            } else if value.contains('(') {
                Some(format!("BIB{}", strip_non_numeric(value)))
            } else {
                None
            }
        })
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn it_can_map_024_indicators_to_labels() {
        assert_eq!(
            map_024_indicators_to_labels('0'),
            "International Standard Recording Code"
        );
        assert_eq!(map_024_indicators_to_labels('1'), "Universal Product Code");
    }

    #[test]
    fn it_can_get_identifiers_of_all_versions() {
        let record = Record::from_breaker(
            r#"=776 \\ $w9947652213506421
=776 \\ $w(DLC)12345678
=776 \\ $w(OCoLC)on9990014350
=787 \\ $w(OCoLC)on9990014351$z(OCoLC)on9990014352
=035 \\ $a(OCoLC)on9990014353
=022 \\ $l0378-5955$y0378-5955
=776 \\ $x1234-5679
=776 \\ $z0-9752298-0-X
=020 \\ $aISBN: 978-0-306-40615-7$z0-306-40615-2"#,
        )
        .unwrap();
        assert_eq!(
            identifiers_of_all_versions(&record).sort(),
            [
                "BIB9947652213506421",
                "on9990014350",
                "on9990014351",
                "on9990014353",
                "03785955",
                "12345679",
                "9780975229804",
                "9780306406157"
            ]
            .sort()
        )
    }
}
