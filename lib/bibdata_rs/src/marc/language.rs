use crate::{
    languages::{
        Language, is_valid_language_code, iso_639_2b::from_iso_639b_code, two_letter_code,
    },
    marc::fixed_field::general_information::slice_from_008,
};
use itertools::Itertools;
use marctk::Record;

pub fn original_languages_of_translation(record: &Record) -> Vec<Language> {
    record
        .extract_values("041(1*)hn")
        .iter()
        .filter_map(|code| from_iso_639b_code(code.trim()))
        .collect()
}

/// If a language code in the record has a 2-letter equivalent, use it.  Otherwise use the 3-letter version.
pub fn simplified_language_codes(record: &Record) -> impl Iterator<Item = &str> {
    language_codes(record).filter_map(|original_code| {
        two_letter_code(original_code).or_else(|| {
            if is_valid_language_code(original_code) {
                Some(original_code)
            } else {
                None
            }
        })
    })
}

pub fn language_codes(record: &Record) -> impl Iterator<Item = &str> {
    record
        .extract_values("041ad")
        .into_iter()
        .chain(slice_from_008(record, 35..38))
        .map(str::trim)
        .unique()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_find_original_language_from_041h() {
        let record = Record::from_breaker(r"=041 1\ $htgl").unwrap();

        let mut languages = original_languages_of_translation(&record);
        assert_eq!(languages.pop().unwrap().english_name, "Tagalog");
        assert_eq!(languages.pop(), None);
    }

    #[test]
    fn it_can_find_original_language_from_041n() {
        let record = Record::from_breaker(r"=041 1\ $nmga").unwrap();

        let mut languages = original_languages_of_translation(&record);
        assert_eq!(
            languages.pop().unwrap().english_name,
            "Irish, Middle (900-1200)"
        );
        assert_eq!(languages.pop(), None);
    }

    #[test]
    fn it_can_find_multiple_original_languages() {
        let record = Record::from_breaker(r"=041 1\ $hlad $hspa").unwrap();

        let mut languages = original_languages_of_translation(&record);
        assert_eq!(languages.pop().unwrap().english_name, "Spanish");
        assert_eq!(languages.pop().unwrap().english_name, "Ladino");
        assert_eq!(languages.pop(), None);
    }

    #[test]
    fn it_ignores_values_unless_first_indicator_is_1() {
        let record = Record::from_breaker(r"=041 0\ $hlad $hspa").unwrap();

        let languages = original_languages_of_translation(&record);
        assert!(languages.is_empty());
    }

    #[test]
    fn it_can_get_language_codes_from_008() {
        let record = Record::from_breaker("=008 060302s1994    io a   j      000 1 may|d").unwrap();
        let mut codes = language_codes(&record);
        assert_eq!(codes.next(), Some("may"));
        assert_eq!(codes.next(), None);
    }

    #[test]
    fn it_can_get_language_codes_from_041() {
        let record = Record::from_breaker(r"=041 0\ $aeng $achi $amay $atam").unwrap();
        let mut codes = language_codes(&record);
        assert_eq!(codes.next(), Some("eng"));
        assert_eq!(codes.next(), Some("chi"));
        assert_eq!(codes.next(), Some("may"));
        assert_eq!(codes.next(), Some("tam"));
        assert_eq!(codes.next(), None);
    }

    #[test]
    fn it_can_determine_simplified_codes() {
        let record = Record::from_breaker(
            r#"=008 151221t20152015si a          001 m eng d
=041 0\ $aeng $achi $amay $atam"#,
        )
        .unwrap();
        let mut codes = simplified_language_codes(&record);
        assert_eq!(codes.next(), Some("en"));
        assert_eq!(codes.next(), Some("zh"));
        assert_eq!(codes.next(), Some("ms"));
        assert_eq!(codes.next(), Some("ta"));
        assert_eq!(codes.next(), None);
    }

    #[test]
    fn it_retains_3_letter_codes_when_there_is_no_2_letter_equivalent() {
        let record =
            Record::from_breaker(r"=041 \7 $aasb $a ats $a crd $a cro $a eng $a nez $2 iso639-3")
                .unwrap();
        let mut codes = simplified_language_codes(&record);
        assert_eq!(codes.next(), Some("asb"));
        assert_eq!(codes.next(), Some("ats"));
        assert_eq!(codes.next(), Some("crd"));
        assert_eq!(codes.next(), Some("cro"));
        assert_eq!(codes.next(), Some("en"));
        assert_eq!(codes.next(), Some("nez"));
        assert_eq!(codes.next(), None);
    }
}
