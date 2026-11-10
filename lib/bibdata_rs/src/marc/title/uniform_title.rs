//! Uniform titles are distinctive titles that catalogers use to group together
//! records for works that have appeared under multiple titles (e.g. translations)

use marctk::Record;

use crate::{
    data_pipeline::pipe,
    marc::{
        extract_values::ExtractValues,
        string_normalize::maybe_not_empty,
        trim_punctuation,
        variable_length_field::{
            SubfieldIterator, join_subfields_by_code, latin_or_non_latin_tag,
            latin_or_non_latin_tag_included_in, latin_tag_included_in, non_latin_tag_included_in,
        },
    },
};

/// Subfields that make up a 240 uniform title.
pub const UNIFORM_TITLE_240_SUBLFIELDS: &[&str] =
    &["a", "p", "l", "d", "f", "h", "k", "m", "n", "o", "r", "s"];

/// Subfields to index for a Latin 130 field of `uniform_title_1display`. This matches
/// the traject spec `'130apldfhkmnorst'`.
const UNIFORM_130_SUBLFIELDS: &[&str] = &[
    "a", "p", "l", "d", "f", "h", "k", "m", "n", "o", "r", "s", "t",
];

/// The uniform title, including information about a translation, but without any information about the author
pub fn uniform_title(record: &Record) -> impl Iterator<Item = String> {
    let uniform_title_fields = record.extract_field_values_by(
        latin_or_non_latin_tag_included_in(&["130", "240"]),
        |field| {
            let subfields: &[&str] = if latin_or_non_latin_tag(field) == "130" {
                &["a", "p", "l", "d", "f", "h", "k", "m", "n", "o", "r", "t"]
            } else {
                UNIFORM_TITLE_240_SUBLFIELDS
            };
            let joined = join_subfields_by_code(field, subfields);
            pipe!(trim_punctuation, maybe_not_empty)(&joined)
        },
    );

    let author_and_title_fields = record.extract_field_values_by(
        latin_or_non_latin_tag_included_in(&["100", "110", "111"]),
        |field| {
            let joined = field.subfields().iter().subfields_after("t").join(" ");
            pipe!(trim_punctuation, maybe_not_empty)(&joined)
        },
    );
    uniform_title_fields.chain(author_and_title_fields)
}

pub fn uniform_130_non_latin(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_field_values_by(non_latin_tag_included_in(&["130"]), |field| {
            Some(join_subfields_by_code(
                field,
                &[
                    "a", "p", "l", "d", "f", "h", "k", "m", "n", "o", "r", "s", "t",
                ],
            ))
        })
        .map(|s| s.to_string())
}

/// Builds `uniform_title_1display` for works that do not have an author.
///
/// ## Arguments
///
/// - `record`: the MARC record
///
/// ## Returns
///
/// `Some(json_string)` when a uniform title exists, otherwise `None`.
pub fn uniform_title_1display(record: &Record) -> Option<String> {
    use serde_json::Value;

    let mut items: Vec<Value> = Vec::new();

    // Latin 130: keep the subfield values of the first Latin 130 field as an inner
    // array, filtering to the subfield codes the traject spec `130apldfhkmnorst` allowed.
    let latin_130 = record.first_matching_field_value(latin_tag_included_in(&["130"]), |field| {
        let subfields: Vec<Value> = field
            .subfields()
            .iter()
            .filter_by_code(UNIFORM_130_SUBLFIELDS)
            .map(|s| Value::String(s.content().to_owned()))
            .collect();
        (!subfields.is_empty()).then_some(subfields)
    });
    if let Some(subfields) = latin_130 {
        items.push(Value::Array(subfields));
    }

    // Non-Latin 130: each joined string, wrapped in a single inner array.
    let vern_130: Vec<Value> = uniform_130_non_latin(record).map(Value::String).collect();
    if !vern_130.is_empty() {
        items.push(Value::Array(vern_130));
    }

    if items.is_empty() {
        None
    } else {
        serde_json::to_string(&Value::Array(items)).ok()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_builds_uniform_title_from_130() {
        let record = Record::from_breaker(r#"=130 0 $aMahābhārata."#).unwrap();
        let mut titles = uniform_title(&record);
        assert_eq!(titles.next(), Some(String::from("Mahābhārata")));
        assert_eq!(titles.next(), None);
    }

    #[test]
    fn it_builds_uniform_title_from_240() {
        let record = Record::from_breaker(r#"=240 10$aNoruwei no mori. $l English"#).unwrap();
        let mut titles = uniform_title(&record);
        assert_eq!(
            titles.next(),
            Some(String::from("Noruwei no mori. English"))
        );
        assert_eq!(titles.next(), None);
    }

    #[test]
    fn it_does_not_include_subfield_0() {
        let record = Record::from_breaker(
            r#"=240 10$a Pantomima $0 http://id.loc.gov/authorities/names/n95021885 "#,
        )
        .unwrap();
        let mut titles = uniform_title(&record);
        assert_eq!(titles.next(), Some(String::from("Pantomima")));
        assert_eq!(titles.next(), None);
    }

    #[test]
    fn it_includes_non_latin_880_uniform_title() {
        let record = Record::from_breaker(
            r#"=240 10 $6880-02$aNoruwei no mori. $l Chinese 
=880 00$6240-02$aノルウェイの森. $l Chinese"#,
        )
        .unwrap();
        let mut titles = uniform_title(&record);
        assert_eq!(
            titles.next(),
            Some(String::from("Noruwei no mori. Chinese"))
        );
        assert_eq!(titles.next(), Some(String::from("ノルウェイの森. Chinese")));
        assert_eq!(titles.next(), None);
    }

    #[test]
    fn it_trims_trailing_punctuation_from_uniform_title() {
        let record = Record::from_breaker(r#"=130 00$aGiovanni's room. $l Russian."#).unwrap();
        let mut titles = uniform_title(&record);
        assert_eq!(
            titles.next(),
            Some(String::from("Giovanni's room. Russian"))
        );
        assert_eq!(titles.next(), None);
    }

    #[test]
    fn it_treats_empty_uniform_title_fields_as_absent() {
        let record = Record::from_breaker(r#"=130 00$a    "#).unwrap();
        let titles: Vec<_> = uniform_title(&record).collect();
        assert!(titles.is_empty());
    }

    #[test]
    fn it_can_find_uniform_130_vern() {
        let record = Record::from_breaker(
            r#"=130 00$aUniform title test $d2020 $lEnglish
=880 00$6130-01$aعنوان کتاب"#,
        )
        .unwrap();
        let mut titles = uniform_130_non_latin(&record);
        assert_eq!(titles.next(), Some(String::from("عنوان کتاب")));
        assert_eq!(titles.next(), None);
    }

    #[test]
    fn it_builds_uniform_title_1display_from_latin_130() {
        // A work without an author whose uniform title is a Latin 130 field.
        let record = Record::from_breaker(r#"=130 10$aBible.$lLatin.$sVulgate.$f1461."#).unwrap();
        assert_eq!(
            uniform_title_1display(&record),
            Some(r#"[["Bible.","Latin.","Vulgate.","1461."]]"#.to_string())
        );
    }

    #[test]
    fn it_builds_uniform_title_1display_from_latin_and_non_latin_130() {
        // A Latin 130 with a parallel non-Latin (Arabic) 880-130 field.
        let record = Record::from_breaker(
            r#"=130 00$6880-01$aAwrāq (Madrid, Spain)
=880 00$6130-01$aاوراق (Madrid, Spain)"#,
        )
        .unwrap();
        assert_eq!(
            uniform_title_1display(&record),
            Some(r#"[["Awrāq (Madrid, Spain)"],["اوراق (Madrid, Spain)"]]"#.to_string())
        );
    }

    #[test]
    fn it_is_absent_when_there_is_no_uniform_title() {
        // A record with an author and a title but no 130/240 uniform title.
        let record = Record::from_breaker(r#"=100 10$aAuthor. $245 00$aA title."#).unwrap();
        assert_eq!(uniform_title_1display(&record), None);
    }
}
