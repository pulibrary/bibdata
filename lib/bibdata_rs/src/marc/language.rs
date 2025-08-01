use crate::languages::{iso_639_2b::from_iso_639b_code, Language};
use marctk::Record;

pub fn original_languages_of_translation(record: &Record) -> Vec<Language> {
    record
        .extract_values("041(1*)hn")
        .iter()
        .filter_map(|code| from_iso_639b_code(code.trim()))
        .collect()
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
}
