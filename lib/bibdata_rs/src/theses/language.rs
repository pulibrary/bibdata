// This module is responsible for labeling the languages that are used in a thesis

use codes_iso_639::part_1::LanguageCode;
use itertools::Itertools;
use std::str::FromStr;

pub fn codes_to_english_names(codes: Option<Vec<String>>) -> Vec<String> {
    let names: Vec<String> = codes
        .unwrap_or_default()
        .iter()
        .map(|code| english_name(code))
        .unique()
        .collect();
    if !names.is_empty() {
        names
    } else {
        vec!["English".to_owned()]
    }
}

fn english_name(code: &str) -> String {
    match LanguageCode::from_str(code.split("-").next().unwrap_or_default()).ok() {
        Some(lang) => lang.language_name().to_owned(),
        None => "English".to_owned(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn english_name_defaults_to_english() {
        assert_eq!(english_name("not-valid"), "English");
    }

    #[test]
    fn english_name_can_identify_indonesian() {
        assert_eq!(english_name("id"), "Indonesian");
    }

    #[test]
    fn english_name_can_identify_czech_with_locale_code() {
        assert_eq!(english_name("cs-CZ"), "Czech");
    }

    #[test]
    fn english_name_gives_parenthetical_information_if_available() {
        assert_eq!(english_name("el"), "Greek, Modern (1453-)");
    }

    #[test]
    fn test_codes_to_english_names() {
        assert_eq!(codes_to_english_names(None), vec!["English"]);
        assert_eq!(
            codes_to_english_names(Some(vec!["fr".to_owned()])),
            vec!["French"]
        );
        assert_eq!(
            codes_to_english_names(Some(vec!["el".to_owned(), "it".to_owned()])),
            vec!["Greek, Modern (1453-)", "Italian"]
        );
        assert_eq!(
            codes_to_english_names(Some(vec!["en_US".to_owned(), "en".to_owned()])),
            vec!["English"]
        );
    }
}
