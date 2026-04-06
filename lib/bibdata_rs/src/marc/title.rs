use crate::marc::{
    extract_values::ExtractValues,
    string_normalize::maybe_not_empty,
    trim_punctuation,
    variable_length_field::{SubfieldIterator, latin_or_non_latin_tag_included_in},
};
use itertools::Itertools;
use marctk::Record;

pub fn contains_titles_index(record: &Record) -> impl Iterator<Item = String> {
    record.extract_field_values_by(
        latin_or_non_latin_tag_included_in(&["700", "710", "711"]),
        |field| {
            maybe_not_empty(trim_punctuation(
                &field.subfields().iter().subfields_after("t").join(" "),
            ))
        },
    )
}

pub fn latin_script_title(record: &Record) -> Option<String> {
    record
        .extract_field_values_by(
            |field| field.tag() == "245",
            |field| {
                Some(
                    field
                        .subfields()
                        .iter()
                        .filter(|subfield| ["abchknps"].contains(&subfield.code()))
                        .map(|subfield| subfield.content())
                        .join(" "),
                )
            },
        )
        .next()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_find_contains_titles_index() {
        let record = Record::from_breaker(r#"=700 12$6880-12$aDawwānī, Muḥammad ibn Asʻad, $d 1426 or 1427-1512 or 1513. $t Zawrāʼ.
=880 12$6700-12$aدواني، محمد بن اسعد, $d 1426 or 1427-1512 or 1513. $t زوراء."#).unwrap();
        let mut contains_titles = contains_titles_index(&record);
        assert_eq!(contains_titles.next(), Some(String::from("Zawrāʼ")));
        assert_eq!(contains_titles.next(), Some(String::from("زوراء")));
        assert_eq!(contains_titles.next(), None);
    }
}
