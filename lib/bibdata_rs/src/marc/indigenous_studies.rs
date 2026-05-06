use crate::marc::{subject::SEPARATOR, utils::slice::contains_subslice};
use serde::{Deserialize, Deserializer};
use std::{
    collections::{HashMap, HashSet},
    sync::LazyLock,
};

// This file can be re-created using `bundle exec rake augment:recreate_fixtures`
const MAIN_TERMS_JSON: &str =
    include_str!("../../../../marc_to_solr/lib/augment_the_subject/standalone_subfield_a.json");
// This file can be re-created using `bundle exec rake augment:recreate_fixtures`
const COMBINED_TERMS_JSON: &str = include_str!(
    "../../../../marc_to_solr/lib/augment_the_subject/indigenous_studies_required.json"
);
// This file must be created by hand from file provided by metadata librarians
const SUBFIELDS_JSON: &str =
    include_str!("../../../../marc_to_solr/lib/augment_the_subject/standalone_subfield_x.json");

fn normalize(raw: impl AsRef<str>) -> String {
    raw.as_ref().to_lowercase()
}

// Normalize terms as we deserialize, so that we don't have to do it for every comparison
fn normalize_lcsh<'de, D>(deserializer: D) -> Result<HashSet<String>, D::Error>
where
    D: Deserializer<'de>,
{
    let raw: HashSet<String> = HashSet::deserialize(deserializer)?;
    Ok(raw.iter().map(normalize).collect())
}

#[derive(Deserialize)]
struct LcshIndigenousStudiesMainTerms {
    #[serde(deserialize_with = "normalize_lcsh")]
    standalone_subfield_a: HashSet<String>,
}

impl LcshIndigenousStudiesMainTerms {
    pub fn contains(&self, term: &str) -> bool {
        self.standalone_subfield_a.contains(term)
    }
}

#[derive(Deserialize)]
struct LcshIndigenousStudiesSubfields {
    #[serde(deserialize_with = "normalize_lcsh")]
    standalone_subfield_x: HashSet<String>,
}

impl LcshIndigenousStudiesSubfields {
    pub fn contains(&self, term: &str) -> bool {
        self.standalone_subfield_x.contains(term)
    }
}

static LCSH_MAIN_TERMS: LazyLock<LcshIndigenousStudiesMainTerms> = LazyLock::new(|| {
    serde_json::from_str(MAIN_TERMS_JSON)
        .expect("Could not parse AugmentTheSubject standalone_subfield_a file")
});

static LCSH_COMBINED_TERMS: LazyLock<HashMap<String, Vec<Vec<String>>>> = LazyLock::new(|| {
    let raw: HashMap<&str, Vec<Vec<&str>>> = serde_json::from_str(COMBINED_TERMS_JSON)
        .expect("Could not parse the AugmentTheSubject indigenous_studies_required file");

    let mut normalized = HashMap::with_capacity(raw.capacity());
    for (key, value) in raw.iter() {
        let _ = normalized.insert(
            normalize(key),
            value
                .iter()
                .map(|terms| terms.iter().map(normalize).collect())
                .collect(),
        );
    }
    normalized
});

static LCSH_SUBFIELDS: LazyLock<LcshIndigenousStudiesSubfields> = LazyLock::new(|| {
    serde_json::from_str(SUBFIELDS_JSON)
        .expect("Could not parse AugmentTheSubject standalone_subfield_x file")
});

pub fn indicates_indigenous_studies<T: AsRef<str>>(terms: &[T]) -> bool {
    terms.iter().any(|term| has_subfield_related_to_indigenous_studies(term.as_ref()) || has_main_term_related_to_indigenous_studies(term.as_ref()) || has_combined_term_related_to_indigenous_studies(term.as_ref()))
}


/// For some subfield terms, only a single subfield needs to match.
/// E.g., any subject term that includes "Indian authors" should be assigned Indigenous Studies
fn has_subfield_related_to_indigenous_studies(term: &str) -> bool {
    term.split(SEPARATOR)
        .any(|subfield| LCSH_SUBFIELDS.contains(&subfield.to_lowercase()))
}

/// For some subject terms, only the first part needs to match.
/// E.g., "Quinnipiac Indians-History", "Quinnipiac Indians-Culture" should both
/// be assigned an Indigenous Studies term even though that entire term doesn't
/// appear in our terms list.
fn has_main_term_related_to_indigenous_studies(term: &str) -> bool {
    term.split(SEPARATOR).next().is_some_and(|main_term| {
        LCSH_MAIN_TERMS.contains(normalize(main_term).trim_end_matches('.'))
    })
}

/// Some subject terms require a combination of terms in order to be assigned Indigenous Studies.
/// For example, "Alaska-Antiquities" should be a match, but "Alaska" by itself should not,
/// nor should "Antiquities" by itself.
fn has_combined_term_related_to_indigenous_studies(term: &str) -> bool {
    // Return early if the term has no subdivisions
    if !term.contains(SEPARATOR) {
        return false;
    }

    let mut subfields = term.split(SEPARATOR);
    let main_term = subfields.next();
    let subdivisions: Vec<String> = subfields.map(normalize).collect();

    main_term
        .and_then(|main| LCSH_COMBINED_TERMS.get(&normalize(main)))
        .is_some_and(|subdivision_windows| {
            subdivision_windows
                .iter()
                .any(|window| contains_subslice(&subdivisions, window))
        })
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_has_the_expected_number_of_main_terms() {
        assert_eq!(LCSH_MAIN_TERMS.standalone_subfield_a.len(), 5599);
    }

    #[test]
    fn it_has_the_expected_number_of_subfields() {
        assert_eq!(LCSH_SUBFIELDS.standalone_subfield_x.len(), 26);
    }

    #[test]
    fn it_can_match_a_subfield() {
        assert!(has_subfield_related_to_indigenous_studies("ABC123—Indian authors—History"));
        assert!(indicates_indigenous_studies(&["ABC123—Indian authors—History"]));

        // It is case-insensitive
        assert!(has_subfield_related_to_indigenous_studies("ABC123—Indian AUThors—History"));
        assert!(indicates_indigenous_studies(&["ABC123—Indian AUThors—History"]));

        assert!(!has_subfield_related_to_indigenous_studies("ABC123—History—United States"));
        assert!(!indicates_indigenous_studies(&["ABC123—History—United States"]));
    }

    #[test]
    fn it_can_match_a_main_term_despite_incorrect_capitalization() {
        assert!(has_main_term_related_to_indigenous_studies("Abipon language"));
        assert!(has_main_term_related_to_indigenous_studies("Abipon Language"));
        assert!(indicates_indigenous_studies(&["Abipon language"]));
    }

    #[test]
    fn it_can_find_a_combined_term() {
        assert!(has_combined_term_related_to_indigenous_studies(
            "Embroidery—Arctic regions"
        ));
        assert!(has_combined_term_related_to_indigenous_studies(
            "Embroidery—ARctic regions"
        ));
        assert!(!has_combined_term_related_to_indigenous_studies(
            "Embroidery"
        ));
        assert!(!has_combined_term_related_to_indigenous_studies(
            "Embroidery—Conservation and restoration"
        ));
    }

    #[test]
    fn it_can_find_a_combined_term_with_extra_punctuation() {
        assert!(indicates_indigenous_studies(&["Quinnipiac Indians."]))
    }
}
