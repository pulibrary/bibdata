// This module handles the indexing logic for CJK (Chinese, Japanese, and
// Korean) fields.  These fields share specialized CJK analysis logic in
// our solr configuration, so we consider them as a group here.

use itertools::Itertools;
use marctk::Record;
use unicode_blocks::is_cjk;

use crate::marc::{
    extract_values::ExtractValues,
    non_latin::{NON_LATIN_SERIES_TITLE_TAGS, non_latin_series_title_subfields},
    trim_punctuation,
    variable_length_field::{
        SubfieldIterator, join_subfields_except, non_latin_tag, non_latin_tag_included_in,
    },
};

pub fn cjk_all(record: &Record) -> impl Iterator<Item = String> {
    record.extract_field_values_by(
        |field| field.tag() == "880",
        |field| {
            let joined = join_subfields_except(field, &["6"]);
            maybe_has_cjk_text(joined)
        },
    )
}

pub fn cjk_authors(record: &Record) -> impl Iterator<Item = String> {
    record.extract_field_values_by(
        non_latin_tag_included_in(&["100", "110", "111", "700", "710", "711"]),
        |field| {
            let desired_subfields = match non_latin_tag(field) {
                Some("100") => vec!["a", "q", "b", "c", "d", "k"],
                Some("110") => vec!["a", "b", "c", "d", "f", "g", "k", "l", "n"],
                Some("111") => vec!["a", "b", "c", "d", "f", "g", "k", "l", "n", "p", "q"],
                Some("700") => vec!["a", "q", "b", "c", "d", "k"],
                Some("710") => vec!["a", "b", "c", "d", "f", "g", "k", "l", "n"],
                Some("711") => vec!["a", "b", "c", "d", "f", "g", "k", "l", "n", "p", "q"],
                _ => Default::default(),
            };
            let joined = trim_punctuation(
                &field
                    .subfields()
                    .iter()
                    .subfields_before("t")
                    .filter_by_code(&desired_subfields)
                    .content()
                    .join(" "),
            );
            maybe_has_cjk_text(joined)
        },
    )
}

pub fn cjk_series_titles(record: &Record) -> impl Iterator<Item = String> {
    let series_title_fields = record.extract_field_values_by(
        non_latin_tag_included_in(&NON_LATIN_SERIES_TITLE_TAGS),
        |field| {
            let desired_subfields = non_latin_series_title_subfields(field);
            let joined = trim_punctuation(
                &field
                    .subfields()
                    .iter()
                    .subfields_before("t")
                    .filter_by_code(&desired_subfields)
                    .content()
                    .join(" "),
            );
            maybe_has_cjk_text(joined)
        },
    );
    let fields_with_author_and_title_info = record.extract_field_values_by(
        non_latin_tag_included_in(&["400", "410", "411", "800", "810", "811"]),
        |field| {
            let joined = trim_punctuation(
                &field
                    .subfields()
                    .iter()
                    .subfields_after("t")
                    .content()
                    .join(" "),
            );
            maybe_has_cjk_text(joined)
        },
    );
    series_title_fields.chain(fields_with_author_and_title_info)
}

pub fn notes_cjk(record: &Record) -> impl Iterator<Item = String> + use<'_> {
    // These notes are supposedly in Latin script, but still may contain some
    // CJK characters
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

pub fn has_cjk_chars(value: &str) -> bool {
    value.chars().any(is_cjk)
}

fn extract_parallel_values<'record>(
    record: &'record Record,
    tag: &str,
    ind1: &'record str,
    ind2: &'record str,
    subfields: &'record [&str],
) -> impl Iterator<Item = String> + 'record + use<'record> {
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

fn maybe_has_cjk_text(original: String) -> Option<String> {
    if has_cjk_chars(&original) {
        Some(original)
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_extract_cjk_from_880() {
        let record = Record::from_breaker(
            r#"=880 \\$6123-01$a돌고래
=880 \\$6123-02$aدُلفين"#,
        )
        .unwrap();
        let mut cjk_all = cjk_all(&record);
        assert_eq!(cjk_all.next(), Some(String::from("돌고래")));
        assert_eq!(cjk_all.next(), None);
    }

    #[test]
    fn it_can_extract_cjk_from_multiple_880_subfields() {
        let record =
            Record::from_breaker(r"=880 \\$6260-03/{dollar}1$a上海 : $b 上海大学出版社, $c 2023.")
                .unwrap();
        let mut cjk_all = cjk_all(&record);
        assert_eq!(
            cjk_all.next(),
            Some(String::from("上海 : 上海大学出版社, 2023."))
        );
        assert_eq!(cjk_all.next(), None);
    }

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

    #[test]
    fn it_can_index_cjk_authors() {
        let record = Record::from_breaker(
            r#"=100 \\$aJohn$d1492$tTITLE$kignore
=880 \\$6100-1$aΚινέζικα$tTITLE$kignore
=880 \\$6100-2$a村上 春樹$tTITLE$kignore"#,
        )
        .unwrap();
        let mut names = cjk_authors(&record);
        assert_eq!(names.next(), Some(String::from("村上 春樹")));
        assert_eq!(names.next(), None);
    }

    #[test]
    fn it_can_index_cjk_series_titles() {
        let record = Record::from_breaker(
            r#"=880 \\ $6440-01$aフシギダネ
=880 \\ $6411-01$a コイキング $t ギャラドス"#,
        )
        .unwrap();
        let mut series_titles = cjk_series_titles(&record);
        assert_eq!(series_titles.next(), Some(String::from("フシギダネ")));
        assert_eq!(series_titles.next(), Some(String::from("ギャラドス")));
        assert_eq!(series_titles.next(), None);
    }
}
