//! This module is concerned with the MARC field 246, "Varying form of Title"

use crate::marc::{
    extract_values::ExtractValues,
    string_normalize::trim_punctuation,
    variable_length_field::{
        VariableLengthField, join_subfields_by_code, latin_or_non_latin_tag_included_in,
    },
};
use marctk::{Field, Record};
use std::{collections::BTreeMap, ops::Deref};

struct Field246<'a>(&'a Field);

impl<'a> Field246<'a> {
    pub fn display_text(&'a self) -> Option<&'a str> {
        self.get("i")
    }
}

impl Deref for Field246<'_> {
    type Target = Field;

    fn deref(&self) -> &Self::Target {
        self.0
    }
}

impl VariableLengthField<'_> for Field246<'_> {}

/// Subfields of 246 that make up the displayed title (the $i label is excluded,
/// so it can never leak into the title itself).
const OTHER_TITLE_SUBFIELDS: &[&str] = &["a", "b", "f", "n", "p"];

struct LabeledOtherTitle {
    label: String,
    title: String,
}

impl LabeledOtherTitle {
    /// Returns `Some` only when the field has an $i label and a non-empty title.
    fn from_field(field: &Field246) -> Option<Self> {
        let label = field.display_text()?;
        let title = join_subfields_by_code(field, OTHER_TITLE_SUBFIELDS);
        if title.is_empty() {
            return None;
        }
        Some(Self {
            label: trim_punctuation(label),
            title,
        })
    }
}

fn labeled_other_titles(record: &Record) -> BTreeMap<String, Vec<String>> {
    let mut labels: BTreeMap<String, Vec<String>> = BTreeMap::new();
    record
        .extract_field_values_by(latin_or_non_latin_tag_included_in(&["246"]), |field| {
            LabeledOtherTitle::from_field(&Field246(field))
        })
        .for_each(|labeled| {
            labels.entry(labeled.label).or_default().push(labeled.title);
        });
    labels
}

pub fn other_title_1display(record: &Record) -> Option<String> {
    let labels = labeled_other_titles(record);
    if labels.is_empty() {
        None
    } else {
        serde_json::to_string(&labels).ok()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_excludes_unlabeled_246() {
        let record = Record::from_breaker(
            r#"=246 13$aCalifornia State Assembly file analysis 
=246 30$aZeitschrift für analytische Chemie
=246 31$aProblèmes actuels de pharmacopsychiatrie"#,
        )
        .unwrap();
        assert_eq!(other_title_1display(&record), None);
    }

    #[test]
    fn it_builds_a_labeled_hash_from_a_246_with_i() {
        let record =
            Record::from_breaker(r#"=246 1 $iEnglish title also known as : $aDad for rent"#)
                .unwrap();
        assert_eq!(
            other_title_1display(&record),
            Some(r#"{"English title also known as":["Dad for rent"]}"#.to_string())
        );
    }

    #[test]
    fn it_accumulates_titles_sharing_a_label() {
        let record = Record::from_breaker(
            r#"=246 1 $iAlt title $aFirst edition
=246 1 $iAlt title $aSecond edition"#,
        )
        .unwrap();
        assert_eq!(
            other_title_1display(&record),
            Some(r#"{"Alt title":["First edition","Second edition"]}"#.to_string())
        );
    }

    #[test]
    fn it_trims_punctuation_from_the_label() {
        let record = Record::from_breaker(r#"=246 1 $iAlso known as : $aAnother name"#).unwrap();
        assert_eq!(
            other_title_1display(&record),
            Some(r#"{"Also known as":["Another name"]}"#.to_string())
        );
    }

    #[test]
    fn it_uses_only_the_abfnp_subfields_for_the_title() {
        let record = Record::from_breaker(
            r#"=246 1 $iLabel $aTitle $b subtitle $c by the poet $n 2 $p illus."#,
        )
        .unwrap();
        assert_eq!(
            other_title_1display(&record),
            Some(r#"{"Label":["Title subtitle 2 illus."]}"#.to_string())
        );
    }

    #[test]
    fn it_excludes_a_labeled_246_with_no_title_subfields() {
        let record = Record::from_breaker(r#"=246 1 $iOrphaned label"#).unwrap();
        assert_eq!(other_title_1display(&record), None);
    }

    #[test]
    fn it_includes_non_latin_labeled_246() {
        let record = Record::from_breaker(
            r#"=246 1 $iLabeled title $aLatin title
=880 10$6246-01 $iLabeled title $a日本語タイトル"#,
        )
        .unwrap();
        let json = other_title_1display(&record).unwrap();
        let parsed: BTreeMap<String, Vec<String>> =
            serde_json::from_str(&json).expect("expected valid JSON");
        assert_eq!(
            parsed.get("Labeled title"),
            Some(&vec![
                String::from("Latin title"),
                String::from("日本語タイトル"),
            ])
        );
    }
}
