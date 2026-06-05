use std::iter::empty;

use marctk::Record;

use crate::marc::{
    extract_values::ExtractValues, trim_punctuation, variable_length_field::latin_tag_included_in,
};

/// A very basic autosuggest field for Romanized Bengali and Hindi
pub fn south_asian_latin_suggest<'a>(record: &'a Record) -> Box<dyn Iterator<Item = String> + 'a> {
    if record.get_control_fields("008").iter().any(|field| {
        let lang_code = field.content().get(35..38);
        matches!(lang_code, Some("hin") | Some("ben"))
    }) {
        Box::new(
            record.extract_field_values_by(latin_tag_included_in(&["100", "245"]), |field| {
                field
                    .first_subfield("a")
                    .map(|subfield| trim_punctuation(subfield.content()))
            }),
        )
    } else {
        Box::new(empty())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_get_bengali_suggestions() {
        let record = Record::from_breaker(
            r#"=008 230810s2023    bg a          000 0 beno^
=245 0 $6880-01 $a Chaṛābārshikī /"#,
        )
        .unwrap();
        let mut suggestions = south_asian_latin_suggest(&record);
        assert_eq!(suggestions.next(), Some(String::from("Chaṛābārshikī")));
        assert!(suggestions.next().is_none())
    }
}
