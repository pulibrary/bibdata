//! This module is responsible for fields that contain text in
//! non-Latin and non-CJK languages

use crate::marc::{
    cjk::has_cjk_chars,
    extract_values::ExtractValues,
    trim_punctuation,
    variable_length_field::{
        SubfieldIterator, join_subfields_except, non_latin_tag, non_latin_tag_included_in,
    },
};
use itertools::Itertools;
use marctk::{Field, Record};

pub fn non_latin_non_cjk_all(record: &Record) -> impl Iterator<Item = String> {
    record.extract_field_values_by(
        |field| field.tag() == "880",
        |field| {
            let joined = join_subfields_except(field, &["6"]);
            maybe_has_non_cjk_text(joined)
        },
    )
}

pub fn non_latin_non_cjk_authors(record: &Record) -> impl Iterator<Item = String> {
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
            maybe_has_non_cjk_text(joined)
        },
    )
}

pub const NON_LATIN_TITLE_TAGS: [&str; 35] = [
    "130", "210", "211", "212", "214", "222", "240", "242", "243", "245", "246", "247", "440",
    "490", "505", "534", "730", "740", "760", "762", "765", "767", "770", "772", "773", "774",
    "775", "776", "777", "780", "785", "786", "787", "830", "840",
];
pub fn non_latin_title_subfields(field: &Field) -> Vec<&str> {
    match non_latin_tag(field) {
        // Very common fields
        Some("245") => vec!["a", "b", "c", "f", "g", "h", "k", "n", "p", "s"],
        Some("246") => vec!["a", "b", "f", "n", "p"],
        Some("505") => vec!["t"],

        // Less common fields
        Some("130") => vec![
            "a", "p", "l", "d", "f", "h", "k", "m", "n", "o", "r", "s", "t",
        ],
        Some("210") => vec!["a", "b"],
        Some("211") | Some("212") | Some("214") => vec!["a"],
        Some("222") => vec!["a", "b"],
        Some("240") => vec!["a", "p", "l", "d", "f", "h", "k", "m", "n", "o", "r", "s"],
        Some("242") => vec!["a", "b", "c", "h", "n", "p"],
        Some("243") => vec!["a", "d", "f", "k", "l", "m", "n", "o", "p", "r", "s"],
        Some("247") => vec!["a", "b", "f", "h", "n", "p"],
        Some("440") => vec!["a", "n", "p", "v", "x"],
        Some("490") => vec!["a", "v", "x"],
        Some("534") => vec!["f"],
        Some("730") => vec!["a", "p", "l", "s", "k", "f", "m", "n", "o", "r"],
        Some("740") => vec!["a", "h", "n", "p"],
        Some("760") | Some("762") => vec!["a", "c", "g", "s", "t"],
        Some(tag)
            if [
                "765", "767", "770", "772", "773", "774", "775", "776", "777", "780", "785", "786",
                "787",
            ]
            .contains(&tag) =>
        {
            vec!["k", "s", "t"]
        }
        Some("830") => vec![
            "a", "d", "f", "g", "h", "k", "l", "m", "n", "o", "p", "r", "s", "t", "v",
        ],
        Some("840") => vec!["a", "n", "p", "v"],
        _ => Default::default(),
    }
}

pub fn non_latin_non_cjk_titles(record: &Record) -> impl Iterator<Item = String> {
    let title_fields =
        record.extract_field_values_by(non_latin_tag_included_in(&NON_LATIN_TITLE_TAGS), |field| {
            let desired_subfields = non_latin_title_subfields(field);
            let joined = trim_punctuation(
                &field
                    .subfields()
                    .iter()
                    .filter_by_code(&desired_subfields)
                    .content()
                    .join(" "),
            );
            maybe_has_non_cjk_text(joined)
        });
    let fields_with_author_and_title_info = record.extract_field_values_by(
        non_latin_tag_included_in(&[
            "100", "110", "111", "400", "410", "411", "700", "710", "711", "800", "810", "811",
        ]),
        |field| {
            let joined = trim_punctuation(
                &field
                    .subfields()
                    .iter()
                    .subfields_after("t")
                    .content()
                    .join(" "),
            );
            maybe_has_non_cjk_text(joined)
        },
    );
    title_fields.chain(fields_with_author_and_title_info)
}

pub const NON_LATIN_SERIES_TITLE_TAGS: [&str; 20] = [
    "440", "490", "534", "760", "762", "765", "767", "770", "772", "773", "774", "775", "776",
    "777", "780", "785", "786", "787", "830", "840",
];
pub fn non_latin_series_title_subfields(field: &Field) -> Vec<&str> {
    match non_latin_tag(field) {
        Some("440") => vec!["a", "n", "p", "v", "x"],
        Some("490") => vec!["a", "v", "x"],
        Some("534") => vec!["f"],
        Some("760") | Some("762") => vec!["a", "c", "g", "s", "t"],
        Some(tag)
            if [
                "765", "767", "770", "772", "773", "774", "775", "776", "777", "780", "785", "786",
                "787",
            ]
            .contains(&tag) =>
        {
            vec!["k"]
        }
        Some("830") => vec![
            "a", "d", "f", "g", "h", "k", "l", "m", "n", "o", "p", "r", "s", "t", "v",
        ],
        Some("840") => vec!["a", "n", "p", "v"],
        _ => Default::default(),
    }
}

pub fn non_latin_non_cjk_series_titles(record: &Record) -> impl Iterator<Item = String> {
    let series_title_fields = record.extract_field_values_by(
        non_latin_tag_included_in(&NON_LATIN_SERIES_TITLE_TAGS),
        |field| {
            let desired_subfields = non_latin_series_title_subfields(field);
            let joined = trim_punctuation(
                &field
                    .subfields()
                    .iter()
                    .filter_by_code(&desired_subfields)
                    .content()
                    .join(" "),
            );
            maybe_has_non_cjk_text(joined)
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
            maybe_has_non_cjk_text(joined)
        },
    );
    series_title_fields.chain(fields_with_author_and_title_info)
}

fn maybe_has_non_cjk_text(original: String) -> Option<String> {
    if !has_cjk_chars(&original) && !original.is_empty() {
        Some(original)
    } else {
        None
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_indexes_fields_that_are_not_in_a_cjk_language() {
        let record = Record::from_breaker(
            r#"=880 \\$6123-01$a돌고래
=880 \\$6123-02$aدُلفين"#,
        )
        .unwrap();
        let mut cjk_all = non_latin_non_cjk_all(&record);
        assert_eq!(cjk_all.next(), Some(String::from("دُلفين")));
        assert_eq!(cjk_all.next(), None);
    }

    #[test]
    fn it_can_index_non_latin_authors() {
        let record = Record::from_breaker(
            r#"=100 \\$aJohn$d1492$tTITLE$kignore
=880 \\$6100-1$aΚινέζικα$tTITLE$kignore
=880 \\$6100-2$a村上 春樹$tTITLE$kignore"#,
        )
        .unwrap();
        let mut names = non_latin_non_cjk_authors(&record);
        assert_eq!(names.next(), Some(String::from("Κινέζικα")));
        assert_eq!(names.next(), None);
    }
}
