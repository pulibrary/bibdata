use crate::marc::language::language_codes;
use marctk::Record;
use std::collections::HashSet;
use std::sync::LazyLock;

// Hand-maintained lists of Western Hemisphere indigenous languages
const LC_SH_CSV: &str = include_str!(
    "../../../../marc_to_solr/lib/augment_the_facet/indigenous_languages_western_hemisphere_lcsh.csv"
);
const CODES_CSV: &str = include_str!(
    "../../../../marc_to_solr/lib/augment_the_facet/indigenous_languages_western_hemisphere_codes.csv"
);

/// MARC language codes (from 008 or 041) that correspond to Western Hemisphere indigenous languages.
static LANGUAGE_CODES: LazyLock<HashSet<String>> = LazyLock::new(|| {
    CODES_CSV
        .lines()
        .map(|line| line.split(',').next().unwrap_or_default().trim())
        .filter(|code| code.len() == 3)
        .map(String::from)
        .collect()
});

/// LCSH subject headings for Western Hemisphere indigenous languages.
static SUBJECT_HEADINGS: LazyLock<HashSet<String>> = LazyLock::new(|| {
    LC_SH_CSV
        .lines()
        .map(|line| line.split(',').next().unwrap_or_default().trim())
        .filter(|heading| !heading.is_empty())
        .map(String::from)
        .collect()
});

/// 650 $a headings from 650 fields that also carry a $v indicating "texts"
fn possible_language_subject_headings(record: &Record) -> impl Iterator<Item = &str> {
    record
        .fields()
        .iter()
        .filter(|field| field.tag() == "650")
        .filter(|field| {
            field
                .first_subfield("v")
                .is_some_and(|v| v.content().to_ascii_lowercase().starts_with("texts"))
        })
        .filter_map(|field| field.first_subfield("a").map(|a| a.content().trim()))
}

/// Identify materials in indigenous languages from the Western Hemisphere
pub fn in_an_indigenous_language(record: &Record) -> bool {
    language_codes(record).any(|code| LANGUAGE_CODES.contains(code))
        || possible_language_subject_headings(record)
            .any(|heading| SUBJECT_HEADINGS.contains(heading))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_embeds_language_codes() {
        assert!(LANGUAGE_CODES.contains("alg"));
        assert!(LANGUAGE_CODES.contains("dak"));
        assert!(LANGUAGE_CODES.contains("iro"));
        assert!(LANGUAGE_CODES.contains("nah"));
    }

    #[test]
    fn it_embeds_subject_headings() {
        assert!(SUBJECT_HEADINGS.contains("Puget Sound Salish languages"));
        assert!(SUBJECT_HEADINGS.contains("Kalapuya language"));
        assert!(SUBJECT_HEADINGS.contains("Kootenai language"));
    }

    #[test]
    fn it_matches_a_relevant_041a_code() {
        let record = Record::from_breaker(r"=041 1\ $asai").unwrap();
        assert!(in_an_indigenous_language(&record));
    }

    #[test]
    fn it_matches_a_relevant_041d_code() {
        let record = Record::from_breaker(r"=041 0\ $aspa $anah").unwrap();
        assert!(in_an_indigenous_language(&record));
    }

    #[test]
    fn it_matches_a_relevant_008_code() {
        let record = Record::from_breaker("=008 120627s2012    ncuabg  ob    001 0 myn d").unwrap();
        assert!(in_an_indigenous_language(&record));
    }

    #[test]
    fn it_matches_a_relevant_subject_heading_with_texts() {
        let record = Record::from_breaker(r"=650 \0 $aMunsee language $vTexts.").unwrap();
        assert!(in_an_indigenous_language(&record));
    }

    #[test]
    fn it_ignores_subject_headings_without_texts() {
        let record =
            Record::from_breaker(r"=650 \0 $aUnami jargon $vGlossaries, vocabularies, etc.")
                .unwrap();
        assert!(!in_an_indigenous_language(&record));
    }

    #[test]
    fn it_returns_false_for_an_unrelated_record() {
        let record = Record::from_breaker(r"=245 10 $aI am an unrelated record").unwrap();
        assert!(!in_an_indigenous_language(&record));
    }
}
