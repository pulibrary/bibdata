//! Uniform titles are distinctive titles that catalogers use to group together
//! records for works that have appeared under multiple titles (e.g. translations)

use marctk::Record;

use crate::marc::{
    extract_values::ExtractValues,
    string_normalize::maybe_not_empty,
    trim_punctuation,
    variable_length_field::{
        SubfieldIterator, join_subfields_by_code, latin_or_non_latin_tag,
        latin_or_non_latin_tag_included_in, non_latin_tag_included_in,
    },
};

/// The uniform title, including information about a translation, but without any information about the author
pub fn uniform_title(record: &Record) -> impl Iterator<Item = String> {
    let uniform_title_fields = record.extract_field_values_by(
        latin_or_non_latin_tag_included_in(&["130", "240"]),
        |field| {
            let subfields: &[&str] = if latin_or_non_latin_tag(field) == "130" {
                &["a", "p", "l", "d", "f", "h", "k", "m", "n", "o", "r", "t"]
            } else {
                &["a", "p", "l", "d", "f", "h", "k", "m", "n", "o", "r", "s"]
            };
            let joined = join_subfields_by_code(field, subfields);
            maybe_not_empty(trim_punctuation(&joined))
        },
    );

    let author_and_title_fields = record.extract_field_values_by(
        latin_or_non_latin_tag_included_in(&["100", "110", "111"]),
        |field| {
            let joined = field.subfields().iter().subfields_after("t").join(" ");
            maybe_not_empty(trim_punctuation(&joined))
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
}
