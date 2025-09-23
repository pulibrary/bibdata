// This module handles the indexing logic for CJK (Chinese, Japanese, and
// Korean) fields.  These fields share specialized CJK analysis logic in
// our solr configuration, so we consider them as a group here.

use itertools::Itertools;
use marctk::Record;
use unicode_blocks::is_cjk;

pub fn notes_cjk(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    let latin_script_note_fields = record.extract_fields(500..=599);
    let parallel_script_fields =
        record
            .get_fields("880")
            .into_iter()
            .filter(|field| matches!(field.first_subfield("6"), Some(subfield) if subfield.content().starts_with("5")));
    latin_script_note_fields
        .chain(parallel_script_fields)
        .map(|field| {
            field
                .subfields()
                .iter()
                .filter(|subfield| subfield.code() != "6")
                .map(|subfield| subfield.content())
                .join(" ")
        })
        .filter(|note| has_cjk_chars(note))
}

pub fn subjects_cjk(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    extract_parallel_values(
        record,
        "600",
        "*",
        "0",
        &[
            "a", "b", "c", "d", "f", "k", "l", "m", "n", "o", "p", "q", "r", "t", "v", "x", "y",
            "z",
        ],
    )
    .chain(extract_parallel_values(
        record,
        "610",
        "*",
        "0",
        &[
            "a", "b", "f", "k", "l", "m", "n", "o", "p", "r", "s", "t", "v", "x", "y", "z",
        ],
    ))
    .chain(extract_parallel_values(
        record,
        "611",
        "*",
        "0",
        &[
            "a", "b", "c", "d", "e", "f", "g", "k", "l", "n", "p", "q", "s", "t", "v", "x", "y",
            "z",
        ],
    ))
    .chain(extract_parallel_values(
        record,
        "630",
        "*",
        "0",
        &[
            "a", "d", "f", "g", "k", "l", "m", "n", "o", "p", "r", "s", "t", "v", "x", "y", "z",
        ],
    ))
    .chain(extract_parallel_values(
        record,
        "650",
        "*",
        "0",
        &["a", "b", "c", "v", "x", "y", "z"],
    ))
    .chain(extract_parallel_values(
        record,
        "650",
        "*",
        "7",
        &["a", "b", "c", "v", "x", "y", "z"],
    ))
    .chain(extract_parallel_values(
        record,
        "651",
        "*",
        "0",
        &["a", "v", "x", "y", "z"],
    ))
    .filter(|subject| has_cjk_chars(subject))
}

fn has_cjk_chars(value: &str) -> bool {
    value.chars().any(is_cjk)
}

fn extract_parallel_values<'record>(
    record: &'record Record,
    tag: &str,
    ind1: &'record str,
    ind2: &'record str,
    subfields: &'record [&str],
) -> impl Iterator<Item = String> + 'record {
    record
        .get_parallel_fields(tag)
        .into_iter()
        .filter(move |field| ind1 == "*" || ind1 == field.ind1())
        .filter(move |field| ind2 == "*" || ind2 == field.ind2())
        .map(|field| {
            field
                .subfields()
                .iter()
                .filter(|subfield| subfields.contains(&subfield.code()))
                .map(|subfield| subfield.content())
                .join(" ")
        })
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_extract_cjk_notes_from_500() {
        let record = Record::from_breaker("=500 \\ $a石室合選").unwrap();
        let mut cjk_notes = notes_cjk(&record);
        assert_eq!(cjk_notes.next(), Some("石室合選".to_string()));
        assert_eq!(cjk_notes.next(), None);
    }

    #[test]
    fn it_can_extract_cjk_notes_from_880() {
        let record = Record::from_breaker(
            r#"=500 \\$6880-01$aThạch thất hợp tuyển
=880 \\$6500-01$a石室合選"#,
        )
        .unwrap();
        let mut cjk_notes = notes_cjk(&record);
        assert_eq!(cjk_notes.next(), Some("石室合選".to_string()));
        assert_eq!(cjk_notes.next(), None);
    }
}
