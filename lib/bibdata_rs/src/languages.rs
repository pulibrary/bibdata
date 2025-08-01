pub mod iso_639_2b;

#[derive(Debug, PartialEq)]
pub struct Language {
    pub english_name: &'static str,
    pub two_letter_code: Option<&'static str>,
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
}
