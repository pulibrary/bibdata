use std::borrow::Cow;

use crate::marc::{
    extract_values::ExtractValues,
    string_normalize::maybe_not_empty,
    trim_punctuation,
    variable_length_field::{
        SubfieldIterator, join_subfields_by_code, latin_or_non_latin_tag_included_in,
        latin_tag_included_in,
    },
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
        .first_matching_field_value(
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
}

pub fn title_sort(record: &Record) -> Option<String> {
    record.first_matching_field_value(latin_tag_included_in(&["245"]), |field| {
        let joined =
            join_subfields_by_code(field, &["a", "b", "c", "f", "g", "h", "k", "n", "p", "s"]);
        let non_filing_characters = field.ind2().parse::<u8>();
        let trimmed = match non_filing_characters {
            Ok(non_filing_characters) => {
                without_non_filing_characters(&joined, non_filing_characters).to_string()
            }
            Err(_) => joined,
        };
        maybe_not_empty(trimmed)
    })
}

fn without_non_filing_characters<'a>(title: &'a str, non_filing_characters: u8) -> Cow<'a, str> {
    if non_filing_characters == 0 {
        Cow::Borrowed(title)
    } else {
        if title.len() > non_filing_characters.into() {
            Cow::Owned(title.chars().skip(non_filing_characters.into()).collect())
        } else {
            Cow::Borrowed(Default::default())
        }
    }
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

    #[test]
    fn it_can_find_title_sort() {
        let record = Record::from_breaker(r"=245 \4 $aThe octopus").unwrap();
        let title_sort = title_sort(&record).unwrap();
        assert_eq!(title_sort, "octopus");
    }

    #[test]
    fn it_returns_title_sort_none_if_245_empty() {
        let record = Record::from_breaker(r"=245 \4 $a  ").unwrap();
        let title_sort = title_sort(&record);
        assert_eq!(title_sort, None);
    }
}
