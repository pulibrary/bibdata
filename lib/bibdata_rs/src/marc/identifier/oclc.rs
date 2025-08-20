use crate::marc::string_normalize::strip_non_numeric;
use regex::Regex;
use std::sync::LazyLock;

pub fn normalize_oclc_number(original: &str) -> String {
    let cleaned = strip_non_numeric(original);
    match cleaned.len() {
        1..=8 => format!("ocm{:0>8}", cleaned),
        9 => format!("ocn{cleaned}"),
        _ => format!("on{cleaned}"),
    }
}

pub fn is_oclc_number(possible_number: &str) -> bool {
    // Ensure it follows the OCLC standard
    // (see https://help.oclc.org/Metadata_Services/WorldShare_Collection_Manager/Data_sync_collections/Prepare_your_data/30035_field_and_OCLC_control_numbers)
    static OCLC_CRITERIA: LazyLock<Regex> =
        LazyLock::new(|| Regex::new(r"\(OCoLC\)(ocn|ocm|on)*\d+").unwrap());

    let cleaned = possible_number.replace(['-', ' '], "");
    OCLC_CRITERIA.is_match(&cleaned)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_normalize_oclc_number() {
        assert_eq!(normalize_oclc_number("9913506421"), "on9913506421");
        assert_eq!(normalize_oclc_number("9913504"), "ocm09913504");
        assert_eq!(normalize_oclc_number("991350412"), "ocn991350412");
        assert_eq!(normalize_oclc_number("(OCoLC)882089266"), "ocn882089266");
        assert_eq!(normalize_oclc_number("(OCoLC)on9990014350"), "on9990014350");
        assert_eq!(normalize_oclc_number("(OCoLC)ocn899745778"), "ocn899745778");
        assert_eq!(normalize_oclc_number("(OCoLC)ocm00012345"), "ocm00012345");
        assert_eq!(normalize_oclc_number("(OCoLC)on9990014353"), "on9990014353");

        assert_eq!(
            normalize_oclc_number("(OCoLC)ocm00012345"),
            normalize_oclc_number("(OCoLC)12345")
        );
    }

    #[test]
    fn it_can_identify_oclc_number() {
        // Valid numbers with various prefixes and extraneous (but harmless) spaces
        assert!(is_oclc_number("(OCoLC)882089266"));
        assert!(is_oclc_number("(OCoLC)on9990014350"));
        assert!(is_oclc_number("(OCoLC)ocn899745778"));
        assert!(is_oclc_number("(OCoLC)ocm00112267 "));
        assert!(is_oclc_number("(OCoLC)on 9990014350"));

        // Invalid numbers
        assert!(!is_oclc_number("(OCoLC)TGPSM11-B2267 "));
        assert!(!is_oclc_number("(OCoLC)xon9990014350"));
        assert!(!is_oclc_number("(OCoLC)onx9990014350"));
    }
}
