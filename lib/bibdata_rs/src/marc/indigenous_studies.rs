use crate::marc::subject::SEPARATOR;
use serde::{Deserialize, Deserializer};
use std::{collections::HashSet, sync::LazyLock};

// This file can be re-created using `bundle exec rake augment:recreate_fixtures`
const MAIN_TERMS_JSON: &str =
    include_str!("../../../../marc_to_solr/lib/augment_the_subject/standalone_subfield_a.json");
// This file must be created by hand from file provided by metadata librarians
const SUBFIELDS_JSON: &str =
    include_str!("../../../../marc_to_solr/lib/augment_the_subject/standalone_subfield_x.json");

fn normalize(raw: &str) -> String {
    raw.to_lowercase()
}

// Normalize terms as we deserialize, so that we don't have to do it for every comparison
fn normalize_lcsh<'de, D>(deserializer: D) -> Result<HashSet<String>, D::Error>
where
    D: Deserializer<'de>,
{
    let raw: HashSet<String> = HashSet::deserialize(deserializer)?;
    Ok(raw.iter().map(|str| normalize(str)).collect())
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

static LCSH_SUBFIELDS: LazyLock<LcshIndigenousStudiesSubfields> = LazyLock::new(|| {
    serde_json::from_str(SUBFIELDS_JSON)
        .expect("Could not parse AugmentTheSubject standalone_subfield_x file")
});

pub fn has_subfield_related_to_indigenous_studies(term: &str) -> bool {
    term.split(SEPARATOR)
        .any(|subfield| LCSH_SUBFIELDS.contains(&subfield.to_lowercase()))
}

pub fn has_main_term_related_to_indigenous_studies(term: &str) -> bool {
    term.split(SEPARATOR).next().is_some_and(|main_term| {
        LCSH_MAIN_TERMS.contains(normalize(main_term).trim_end_matches('.'))
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
}
