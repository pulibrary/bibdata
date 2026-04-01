use std::iter;

use itertools::Itertools;
use marctk::{Field, Record, Subfield};

use crate::marc::{
    extract_values::ExtractValues, trim_punctuation,
    variable_length_field::latin_or_non_latin_tag_in,
};

pub const SEPARATOR: char = '—';

#[derive(PartialEq)]
enum SubjectVocabulary {
    Fast,
    Icpsr,
    LibraryOfCongress,
    Siku,
    UnknownVocabulary,
    VocabularyNotSpecified,
}

impl From<&Field> for SubjectVocabulary {
    // can convert a MARC 650 (Topic Subject) field into a SubjectVocabulary
    fn from(field: &Field) -> Self {
        if field.ind2() == "0" {
            Self::LibraryOfCongress
        } else if field.ind2() == "7" {
            match field.first_subfield("2") {
                Some(subfield) => Self::from(subfield.content()),
                _ => Self::VocabularyNotSpecified,
            }
        } else {
            Self::UnknownVocabulary
        }
    }
}

impl From<&str> for SubjectVocabulary {
    fn from(value: &str) -> Self {
        match value.trim() {
            "fast" => Self::Fast,
            "icpsr" => Self::Icpsr,
            "sk" => Self::Siku,
            "skbb" => Self::Siku,
            _ => Self::UnknownVocabulary,
        }
    }
}

pub fn fast_subjects<'a>(record: &'a Record) -> Box<dyn Iterator<Item = &'a str> + 'a> {
    // We only display FAST subjects for records with no Library of Congress subjects
    if record.fields().iter().any(|field| {
        ["600", "610", "611", "630", "650", "651"].contains(&field.tag())
            && SubjectVocabulary::from(field) == SubjectVocabulary::LibraryOfCongress
    }) {
        Box::new(iter::empty())
    } else {
        Box::new(record.extract_field_values_by(
            |field| {
                field.tag().starts_with("6")
                    && SubjectVocabulary::from(field) == SubjectVocabulary::Fast
            },
            |field| {
                field.first_subfield("a").map(|subfield| {
                    subfield
                        .content()
                        .trim_start()
                        .trim_end_matches(|c: char| c.is_whitespace() || c == '.')
                })
            },
        ))
    }
}

pub fn icpsr_subjects(record: &Record) -> Vec<String> {
    record
        .get_fields("650")
        .iter()
        .filter(|field| matches!(SubjectVocabulary::from(**field), SubjectVocabulary::Icpsr))
        .map(|field| {
            field
                .get_subfields("a")
                .iter()
                .map(|subfield| subfield.content())
                .join(" ")
        })
        .map(|heading| trim_punctuation(&heading))
        .collect()
}

pub fn siku_subjects_display(record: &Record) -> impl Iterator<Item = String> {
    record.extract_field_values_by(
        |field| {
            latin_or_non_latin_tag_in(&["650"])(field)
                && matches!(SubjectVocabulary::from(field), SubjectVocabulary::Siku)
        },
        |field| {
            Some(hierarchical_heading(
                field,
                &["a", "b", "c", "v", "x", "y", "z"],
                |subfield| ["t", "v", "x", "y", "z"].contains(&subfield.code()),
            ))
        },
    )
}

// Creates a concatenated heading with separators before the desired subfields, for example:
// German language—Foreign words and phrases
pub fn hierarchical_heading(
    field: &Field,
    subfields_to_include: &[&str],
    place_separator_before: fn(&Subfield) -> bool,
) -> String {
    field
        .subfields()
        .iter()
        .filter(|subfield| subfields_to_include.contains(&subfield.code()))
        .fold(String::default(), |mut accumulator, subfield| {
            if place_separator_before(subfield) {
                accumulator.push(SEPARATOR);
            }
            accumulator.push_str(&trim_punctuation(subfield.content()));
            accumulator
        })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_finds_icpsr_headings() {
        let record = Record::from_breaker(
            r#"=650 \7 $aAuto theft. $2 icpsr
=650 \7 $a Economic indicators.$2icpsr
=650 \0 $a Criminal statistics $z Oklahoma $z Oklahoma City."#,
        )
        .unwrap();
        assert_eq!(
            icpsr_subjects(&record),
            ["Auto theft".to_owned(), "Economic indicators".to_owned()]
        );
    }

    #[test]
    fn it_can_concatenate_a_hierarchical_heading() {
        let record =
            Record::from_breaker("=650 \0 $a German language $x Grammar, Historical.").unwrap();
        let field = record
            .fields()
            .iter()
            .filter(|field| field.tag() == "650")
            .next()
            .unwrap();
        assert_eq!(
            hierarchical_heading(field, &["a", "x"], |subfield| subfield.code() == "x"),
            "German language—Grammar, Historical"
        );
    }

    #[test]
    fn it_can_find_fast_headings() {
        let record =
            Record::from_breaker(r"=650 \7 $a Gods, Greek. $2 fast $0 (OCoLC)fst00944264").unwrap();
        let mut fast_headings = fast_subjects(&record);
        assert_eq!(fast_headings.next(), Some("Gods, Greek"));
        assert!(fast_headings.next().is_none())
    }

    #[test]
    fn it_does_not_include_fast_headings_if_there_are_lcsh_headings() {
        let record = Record::from_breaker(
            r#"=650 \0 $aGods, Greek $v Juvenile fiction.
=650 \7 $a Gods, Greek. $2 fast $0 (OCoLC)fst00944264"#,
        )
        .unwrap();
        let mut fast_headings = fast_subjects(&record);
        assert!(fast_headings.next().is_none())
    }
}
