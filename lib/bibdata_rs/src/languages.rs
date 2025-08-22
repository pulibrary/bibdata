pub mod iso_639_2b;
pub mod iso_639_3;

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
        self.iso_639_2b_code
            .map(iso_639_2b::from_iso_639b_code)?
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
}
