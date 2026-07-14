use std::borrow::Cow;

use crate::marc::{
    extract_values::ExtractValues,
    string_normalize::maybe_not_empty,
    trim_punctuation,
    variable_length_field::{
        SubfieldIterator, join_subfields_by_code, latin_or_non_latin_tag_included_in,
        latin_tag_included_in, non_latin_tag_included_in,
    },
};
use itertools::Itertools;
use marctk::{Field, Record};

struct Field245<'a>(&'a Field);
impl<'a> Field245<'a> {
    pub fn non_filing_characters(&'a self) -> u8 {
        self.0.ind2().parse().unwrap_or_default()
    }
}

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
    record.first_matching_field_value(
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
        let field = Field245(field);
        let joined =
            join_subfields_by_code(field.0, &["a", "b", "c", "f", "g", "h", "k", "n", "p", "s"]);
        let trimmed =
            without_non_filing_characters(&joined, field.non_filing_characters()).to_string();
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

/// Returns the non-Latin version of the main title,
/// with non-filing characters removed.  Looks at 880 fields pointing to 245.
pub fn non_latin_title_sort(record: &Record) -> Option<String> {
    record.first_matching_field_value(non_latin_tag_included_in(&["245"]), |field| {
        let field = Field245(field);
        let joined =
            join_subfields_by_code(field.0, &["a", "b", "c", "f", "g", "h", "k", "n", "p", "s"]);
        let trimmed =
            without_non_filing_characters(&joined, field.non_filing_characters()).to_string();
        maybe_not_empty(trimmed)
    })
}

/// Returns titles from field 245 (both Latin and non-Latin scripts),
/// excluding subfield $h, with two versions per field:
/// one including non-filing characters and one without.
pub fn title_no_h_index(record: &Record) -> impl Iterator<Item = String> {
    record
        .extract_field_values_by(latin_or_non_latin_tag_included_in(&["245"]), |field| {
            let field = Field245(field);
            let joined =
                join_subfields_by_code(field.0, &["a", "b", "c", "f", "g", "k", "n", "p", "s"]);
            if joined.is_empty() {
                return None;
            }
            let without_nf_chars =
                without_non_filing_characters(&joined, field.non_filing_characters()).to_string();
            Some(vec![joined, without_nf_chars])
        })
        .flatten()
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

    #[test]
    fn it_can_find_non_latin_title_sort() {
        let record = Record::from_breaker(
            r#"=245 10 $aal-Dulfīn al-alīf / $c [taʼlīf Muḥyī al-Dīn Salīmah].
=880 10$6245-02/ $a الدلفين الاليف / $c [تأليف محيي الدين سليمة]."#,
        )
        .unwrap();
        let non_latin_title_sort = non_latin_title_sort(&record).unwrap();
        assert_eq!(
            non_latin_title_sort,
            "الدلفين الاليف / [تأليف محيي الدين سليمة]."
        );
    }

    #[test]
    fn it_returns_non_latin_title_sort_none_when_no_880() {
        let record = Record::from_breaker(r"=245 \0 $aPlain title").unwrap();
        assert_eq!(non_latin_title_sort(&record), None);
    }

    #[test]
    fn it_returns_two_versions_for_title_no_h_index() {
        let record = Record::from_breaker(
            r#"=245 10 $aThe great novel : $b a subtitle / $c by the author."#,
        )
        .unwrap();
        let title_values: Vec<_> = title_no_h_index(&record).collect();
        // Two entries: original and "stripped" (same when ind2=0)
        assert_eq!(title_values.len(), 2);
        assert_eq!(
            title_values[0],
            "The great novel : a subtitle / by the author."
        );
        assert_eq!(
            title_values[1],
            "The great novel : a subtitle / by the author."
        );
    }

    #[test]
    fn it_strips_non_filing_characters_for_title_no_h_index() {
        let record = Record::from_breaker(r#"=245 12 $aA great novel : $b a subtitle."#).unwrap();
        let title_values: Vec<_> = title_no_h_index(&record).collect();
        assert_eq!(title_values.len(), 2);
        assert_eq!(title_values[0], "A great novel : a subtitle.");
        assert_eq!(title_values[1], "great novel : a subtitle.");
    }

    #[test]
    fn it_includes_non_latin_880_for_title_no_h_index() {
        let record = Record::from_breaker(
            r#"=245 10 $aLatin title.
=880 10$6245-01/ $aNon-Latin title."#,
        )
        .unwrap();
        let title_values: Vec<_> = title_no_h_index(&record).collect();
        // Latin field: 2 entries (original + stripped), non-Latin field: 2 entries
        assert_eq!(title_values.len(), 4);
        assert_eq!(title_values[0], "Latin title.");
        assert_eq!(title_values[1], "Latin title.");
        assert_eq!(title_values[2], "Non-Latin title.");
        assert_eq!(title_values[3], "Non-Latin title.");
    }

    #[test]
    fn it_excludes_subfield_h_for_title_no_h_index() {
        let record =
            Record::from_breaker(r#"=245 10 $aThe book : $h [voluminous pages] $b a subtitle."#)
                .unwrap();
        let title_values: Vec<_> = title_no_h_index(&record).collect();
        assert_eq!(title_values.len(), 2);
        // Should NOT include "$h" content
        assert_eq!(title_values[0], "The book : a subtitle.");
        assert!(title_values[0].contains("book") && !title_values[0].contains("voluminous"));
    }

    #[test]
    fn it_returns_empty_iterator_for_missing_245() {
        let record = Record::from_breaker(r#"=300 \ $a100 pages."#).unwrap();
        let title_values: Vec<_> = title_no_h_index(&record).collect();
        assert!(title_values.is_empty());
    }

    #[test]
    fn it_returns_empty_iterator_for_blank_245() {
        let record = Record::from_breaker(r"=245 10 $a   ").unwrap();
        let title_values: Vec<_> = title_no_h_index(&record).collect();
        assert!(title_values.is_empty());
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
