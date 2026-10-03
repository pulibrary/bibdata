use crate::marc::{
    extract_values::ExtractValues,
    trim_punctuation,
    variable_length_field::{join_subfields, latin_or_non_latin_tag_included_in},
};
use itertools::Itertools;
use marctk::{Field, Record, Subfield};
use regex::Regex;
use std::iter;
use std::sync::LazyLock;

pub const SEPARATOR: char = '—';

// Subject fields whose `$y` subdivision is emitted directly as an era facet value.
const ORDINARY_ERA_TAGS: &[&str] = &["600", "610", "611", "630", "650", "654", "656", "690"];

// Subject fields whose `$y` subdivision gets its `$a` prefixed when it looks like
// a chronology/name pair (e.g. "Civil War, 1861-1865").
const GEOGRAPHIC_SUBJECT_TAGS: &[&str] = &["651", "691"];

static CHRON_SUBDIVISION_REGEX: LazyLock<Regex> = LazyLock::new(|| {
    Regex::new(r"\A\s*.+,\s+(ca\.\s+)?\d\d\d\d?(-\d\d\d\d?)?( B\.C\.)?[.,; ]*\z")
        .expect("Could not compile chron subdivision regex")
});

static TRAILING_PERIOD_REGEX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"\. *\z").expect("Could not compile trailing period regex"));

fn strip_trailing_period(value: &str) -> String {
    TRAILING_PERIOD_REGEX.replace(value, "").to_string()
}

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
        .extract_field_values_by(
            |field| {
                field.tag() == "650"
                    && matches!(SubjectVocabulary::from(field), SubjectVocabulary::Icpsr)
            },
            |field| {
                Some(trim_punctuation(&join_subfields(
                    field.get_subfields("a").into_iter(),
                )))
            },
        )
        .collect()
}

pub fn siku_subjects_display(record: &Record) -> impl Iterator<Item = String> {
    record.extract_field_values_by(
        |field| {
            latin_or_non_latin_tag_included_in(&["650"])(field)
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

/// Reimplementation of traject's `marc_era_facet` macro
pub fn subject_era_facet(record: &Record) -> Vec<String> {
    let mut accumulator: Vec<String> = Vec::new();

    for field in record.fields().iter() {
        match field.tag() {
            "648" => {
                let joined = field
                    .subfields()
                    .iter()
                    .filter(|subfield| subfield.code() == "a" || subfield.code() == "y")
                    .map(|subfield| subfield.content())
                    .collect::<Vec<_>>()
                    .join(" ");
                if !joined.is_empty() {
                    accumulator.push(strip_trailing_period(&joined));
                }
            }
            _ if ORDINARY_ERA_TAGS.contains(&field.tag()) => {
                for subfield in field.subfields().iter() {
                    if subfield.code() == "y" {
                        accumulator.push(strip_trailing_period(subfield.content()));
                    }
                }
            }
            _ => {}
        }
    }

    for field in record.fields().iter() {
        if !GEOGRAPHIC_SUBJECT_TAGS.contains(&field.tag()) {
            continue;
        }
        let a = field
            .first_subfield("a")
            .map(|subfield| subfield.content())
            .unwrap_or("");
        for subfield in field.subfields().iter() {
            if subfield.code() != "y" {
                continue;
            }
            let value = subfield.content();
            if CHRON_SUBDIVISION_REGEX.is_match(value) {
                accumulator.push(format!("{a}: {}", strip_trailing_period(value)));
            } else {
                accumulator.push(strip_trailing_period(value));
            }
        }
    }

    accumulator.into_iter().unique().collect()
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

    // Mirrors traject's `multi_era.marc` example.
    #[test]
    fn it_maps_a_complicated_record_like_traject() {
        let record = Record::from_breaker(
            r#"=600 \0$aEnglish literature$yEarly modern, 1500-1700$xHistory and criticism.
=600 \0$aPolitics and literature$zGreat Britain$xHistory$y17th century.
=600 \0$aPolitical poetry, English$xHistory and criticism.
=651 \0$aGreat Britain$xHistory$yPuritan Revolution, 1642-1660$xLiterature and the Revolution.
=651 \0$aGreat Britain$xHistory$yCivil War, 1642-1649$xLiterature and the war.
=651 \0$aGreat Britain$xPolitics and government$y1642-1660."#,
        )
        .unwrap();

        assert_eq!(
            subject_era_facet(&record),
            vec![
                "Early modern, 1500-1700",
                "17th century",
                "Great Britain: Puritan Revolution, 1642-1660",
                "Great Britain: Civil War, 1642-1649",
                "1642-1660",
            ]
        );
    }

    #[test]
    fn it_returns_an_empty_array_for_a_record_without_era_fields() {
        let record = Record::from_breaker(r"=245 10 $a A title.").unwrap();
        assert!(subject_era_facet(&record).is_empty());
    }

    #[test]
    fn it_uses_the_y_subdivision_of_ordinary_subject_fields() {
        let record = Record::from_breaker(
            r#"=610 \0$aSome society$y18th century.
=650 \0$aHistory$y17th century."#,
        )
        .unwrap();
        assert_eq!(
            subject_era_facet(&record),
            vec!["18th century", "17th century"]
        );
    }

    #[test]
    fn it_joins_a_and_y_subfields_of_a_648_field() {
        let record = Record::from_breaker(r#"=648 \0$aSome place$y18th century."#).unwrap();
        assert_eq!(subject_era_facet(&record), vec!["Some place 18th century"]);
    }

    #[test]
    fn it_prefixes_a_651_a_for_a_chronology_subdivision() {
        let record =
            Record::from_breaker(r#"=651 \0$aUnited States$xHistory$yCivil War, 1861-1865."#)
                .unwrap();
        assert_eq!(
            subject_era_facet(&record),
            vec!["United States: Civil War, 1861-1865"]
        );
    }

    #[test]
    fn it_does_not_prefix_a_plain_year_range_subdivision() {
        let record = Record::from_breaker(r#"=651 \0$aGreat Britain$y1861-1865."#).unwrap();
        assert_eq!(subject_era_facet(&record), vec!["1861-1865"]);
    }

    #[test]
    fn it_prefixes_a_chronology_with_a_ca_estimate() {
        let record = Record::from_breaker(r#"=651 \0$aFrance$yRevolution, ca. 1789."#).unwrap();
        assert_eq!(
            subject_era_facet(&record),
            vec!["France: Revolution, ca. 1789"]
        );
    }

    #[test]
    fn it_deduplicates_preserving_first_occurrence_order() {
        let record = Record::from_breaker(
            r#"=650 \0$aHistory$y19th century.
=650 \0$aPolitics$y19th century.
=651 \0$aNation$yWar, 1900-1910.
=651 \0$aNation$yWar, 1900-1910."#,
        )
        .unwrap();
        assert_eq!(
            subject_era_facet(&record),
            vec!["19th century", "Nation: War, 1900-1910"]
        );
    }

    #[test]
    fn it_strips_a_trailing_period_but_keeps_trailing_spaces_without_one() {
        assert_eq!(strip_trailing_period("17th century."), "17th century");
        assert_eq!(strip_trailing_period("17th century"), "17th century");
        assert_eq!(strip_trailing_period("17th century "), "17th century ");
    }
}
