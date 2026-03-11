use itertools::Itertools;
use marctk::{Field, Record, Subfield};

use crate::marc::{
    extract_values::ExtractValues, trim_punctuation, variable_length_field::multiscript_tag_eq,
};

pub const SEPARATOR: char = '—';

enum SubjectVocabulary {
    Icpsr,
    Siku,
    UnknownVocabulary,
    VocabularyNotSpecified,
}

impl From<&Field> for SubjectVocabulary {
    // can convert a MARC 650 (Topic Subject) field into a SubjectVocabulary
    fn from(field: &Field) -> Self {
        if field.ind2() == "7" {
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
            "icpsr" => Self::Icpsr,
            "sk" => Self::Siku,
            "skbb" => Self::Siku,
            _ => Self::UnknownVocabulary,
        }
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
            multiscript_tag_eq(field, "650")
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
fn hierarchical_heading(
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
}
