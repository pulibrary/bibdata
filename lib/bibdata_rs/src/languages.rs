pub mod iso_639_2b;
pub mod iso_639_3;
pub mod iso_639_5;

#[derive(Debug, PartialEq)]
pub struct Language {
    pub english_name: &'static str,
    pub two_letter_code: Option<&'static str>,
}

#[derive(Debug, PartialEq)]
pub struct Iso639_3Language {
    pub language: Language,
    pub macrolanguage_code: Option<&'static str>,
    pub iso_639_2b_code: Option<&'static str>,
}

impl Iso639_3Language {
    pub fn macrolanguage(&self) -> Option<Iso639_3Language> {
        self.macrolanguage_code
            .map(iso_639_3::from_iso_639_3_code)?
    }

    pub fn iso_639_2b_language(&self) -> Option<Language> {
        self.iso_639_2b_code.map(iso_639_2b::from_iso_639b_code)?
    }

    pub fn language_name(&self) -> &'static str {
        self.iso_639_2b_language()
            .map(|language_2b| language_2b.english_name)
            .unwrap_or(self.language.english_name)
    }
}

#[derive(Debug)]
pub struct NoSuchLanguageCode;

pub fn language_name(code: &str) -> Result<&'static str, NoSuchLanguageCode> {
    iso_639_3::from_iso_639_3_code(code)
        .map(|language3| language3.language_name())
        .or(iso_639_2b::from_iso_639b_code(code).map(|language2| language2.english_name))
        .ok_or(NoSuchLanguageCode)
}

// A wrapper for use in Ruby that uses owned strings
pub fn language_code_to_name(code: String) -> Option<String> {
    language_name(&code).ok().map(|name| name.to_owned())
}

pub fn is_valid_language_code(code: String) -> bool {
    if code.is_empty() {
        return false;
    }
    iso_639_2b::from_iso_639b_code(&code).is_some()
        || iso_639_5::from_iso_639_5_code(&code).is_some()
        || iso_639_3::from_iso_639_3_code(&code).is_some()
}

pub fn two_letter_code(code: &str) -> Option<&'static str> {
    iso_639_2b::from_iso_639b_code(code)
        .and_then(|language| language.two_letter_code)
        .or_else(|| {
            iso_639_3::from_iso_639_3_code(code)
                .and_then(|language| language.language.two_letter_code)
        })
}

// A wrapper for use in Ruby that uses owned strings
pub fn two_letter_code_owned(code: String) -> Option<String> {
    two_letter_code(&code).map(|two_letter_code| two_letter_code.to_owned())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_provide_english_name_of_iso_639_2b_language_code() {
        assert_eq!(
            iso_639_2b::from_iso_639b_code("mao").unwrap().english_name,
            "Maori"
        );
        assert_eq!(
            iso_639_2b::from_iso_639b_code("gla").unwrap().english_name,
            "Gaelic"
        );
    }

    #[test]
    fn it_can_find_the_macrolanguage_of_iso_639_3_language_code() {
        let wu_chinese = iso_639_3::from_iso_639_3_code("wuu").unwrap();
        assert_eq!(wu_chinese.language.english_name, "Wu Chinese");

        let macrolanguage = wu_chinese.macrolanguage().unwrap();
        assert_eq!(macrolanguage.language.english_name, "Chinese");
    }

    #[test]
    fn it_uses_iso_639_2b_name_if_available() {
        assert_eq!(language_name("spa").unwrap(), "Spanish"); // rather than "Castilian", the name in ISO 639-3
    }

    #[test]
    fn it_can_get_the_language_name_by_iso_639_3_or_iso_639_2b_code() {
        assert_eq!(language_name("ell").unwrap(), "Greek, Modern (1453-)"); // ell is the ISO 639-3 code
        assert_eq!(language_name("gre").unwrap(), "Greek, Modern (1453-)"); // ell is the ISO 639-2b code
    }

    #[test]
    fn it_can_validate_language_codes() {
        assert!(
            is_valid_language_code("per".to_owned()),
            "ISO 639-2b code is considered to be valid"
        );
        assert!(
            is_valid_language_code("grc".to_owned()),
            "ISO 639-3 code is considered to be valid"
        );
        assert!(
            is_valid_language_code("nah".to_owned()),
            "ISO 639-5 collective code is considered to be valid"
        );
        assert!(!is_valid_language_code("123".to_owned()), "Invalid code");
    }

    #[test]
    fn it_can_get_a_two_letter_code() {
        assert_eq!(
            two_letter_code("eng"),
            Some("en"),
            "it shortens to the two-character form"
        );
        assert_eq!(
            two_letter_code("chi"),
            Some("zh"),
            "it handles cases where ISO 639-2 preferred codes are different from the MARC standard"
        );
        assert_eq!(
            two_letter_code("zxx"),
            None,
            "it handles non-languages from the MARC standard"
        );
    }
}
