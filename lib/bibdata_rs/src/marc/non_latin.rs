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
use marctk::Record;

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
