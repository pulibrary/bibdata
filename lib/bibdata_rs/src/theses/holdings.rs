// This module is responsible for describing the holdings of a thesis

use crate::theses::embargo;
use serde::{ser::SerializeStruct, Serialize};
use std::collections::HashMap;

pub fn call_number(non_ark_ids: Option<&Vec<String>>) -> String {
    let ids = match non_ark_ids {
        Some(value) => value,
        None => &Vec::default(),
    };
    if !ids.is_empty() {
        format!("AC102 {}", ids.first().unwrap())
    } else {
        "AC102".to_string()
    }
}

pub fn online_holding_string(non_ark_ids: Option<&Vec<String>>) -> Option<String> {
    serde_json::to_string(&ThesisHoldingHash {
        thesis: OnlineHolding {
            call_number: call_number(non_ark_ids),
        },
    })
    .ok()
}

pub fn physical_holding_string(non_ark_ids: Option<Vec<String>>) -> Option<String> {
    serde_json::to_string(&ThesisHoldingHash {
        thesis: PhysicalHolding {
            call_number: call_number(non_ark_ids.as_ref()),
        },
    })
    .ok()
}

fn physical_class_year(class_years: Vec<String>) -> bool {
    // For theses, there is no physical copy since 2013
    // anything 2012 and prior have a physical copy
    // @see https://github.com/pulibrary/orangetheses/issues/76
    match class_years.first() {
        Some(year) => year < &"2013".to_string(),
        None => false,
    }
}

pub fn ark_hash(
    identifier_uri: Option<Vec<String>>,
    location: bool,
    access_rights: bool,
    mudd_walkin: bool,
    class_year: Vec<String>,
    embargo_lift: Option<Vec<String>>,
    embargo_terms: Option<Vec<String>>,
) -> Option<String> {
    let arks = identifier_uri.unwrap_or_default();
    let key = arks.first()?;
    let value = if on_site_only(
        location,
        access_rights,
        mudd_walkin,
        class_year,
        embargo_lift,
        embargo_terms,
    ) {
        ["DataSpace", "Citation only"]
    } else {
        ["DataSpace", "Full text"]
    };
    let mut hash: HashMap<String, serde_json::Value> = HashMap::new();
    hash.insert(key.into(), value.into());
    Some(serde_json::to_string(&hash).unwrap())
}

pub fn on_site_only(
    location: bool,
    access_rights: bool,
    mudd_walkin: bool,
    class_year: Vec<String>,
    embargo_lift: Option<Vec<String>>,
    embargo_terms: Option<Vec<String>>,
) -> bool {
    if embargo::has_current_embargo(embargo_lift.as_ref(), embargo_terms.as_ref()) {
        return true;
    };
    if !physical_class_year(class_year) {
        return false;
    }
    location || access_rights || mudd_walkin
}

#[derive(Debug, Serialize)]
pub struct ThesisHoldingHash<T>
where
    T: Serialize,
{
    thesis: T,
}

#[derive(Debug)]
pub struct OnlineHolding {
    call_number: String,
}

impl Serialize for OnlineHolding {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        let mut serializer = serializer.serialize_struct("OnlineHolding", 3)?;
        serializer.serialize_field("call_number", &self.call_number)?;
        serializer.serialize_field("call_number_browse", &self.call_number)?;
        serializer.serialize_field("dspace", &true)?;
        serializer.end()
    }
}

#[derive(Debug)]
pub struct PhysicalHolding {
    call_number: String,
}

impl Serialize for PhysicalHolding {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        let mut serializer = serializer.serialize_struct("PhysicalHolding", 6)?;
        serializer.serialize_field("location", "Mudd Manuscript Library")?;
        serializer.serialize_field("library", "Mudd Manuscript Library")?;
        serializer.serialize_field("location_code", "mudd$stacks")?;
        serializer.serialize_field("call_number", &self.call_number)?;
        serializer.serialize_field("call_number_browse", &self.call_number)?;
        serializer.serialize_field("dspace", &true)?;
        serializer.end()
    }
}

#[cfg(test)]
mod tests {
    use std::vec;

    use super::*;

    #[test]
    fn it_can_create_call_number() {
        assert_eq!(
            call_number(Some(&vec![
                "123".to_owned(),
                "456".to_owned(),
                "789".to_owned()
            ])),
            "AC102 123"
        );
        assert_eq!(call_number(Some(&vec![])), "AC102");
        assert_eq!(call_number(None), "AC102");
    }

    #[test]
    fn it_can_serialize_online_holding() {
        let hash = ThesisHoldingHash {
            thesis: OnlineHolding {
                call_number: "AC102".to_owned(),
            },
        };
        assert_eq!(
            serde_json::to_string(&hash).unwrap(),
            r#"{"thesis":{"call_number":"AC102","call_number_browse":"AC102","dspace":true}}"#
        );
    }

    #[test]
    fn it_can_serialize_physical_holding() {
        let hash = ThesisHoldingHash {
            thesis: PhysicalHolding {
                call_number: "AC102".to_owned(),
            },
        };
        assert_eq!(
            serde_json::to_string(&hash).unwrap(),
            r#"{"thesis":{"location":"Mudd Manuscript Library","library":"Mudd Manuscript Library","location_code":"mudd$stacks","call_number":"AC102","call_number_browse":"AC102","dspace":true}}"#
        );
    }

    #[test]
    fn it_is_onsite_only_when_embargo_terms_is_some() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = false;
        let class_year = vec![];
        let embargo_lift = None;
        let embargo_terms = Some(vec!["2100-01-01".to_owned()]);
        assert_eq!(
            on_site_only(
                location,
                access_rights,
                mudd_walkin,
                class_year,
                embargo_lift,
                embargo_terms
            ),
            true
        );
    }

    #[test]
    fn it_is_onsite_only_when_embargo_lift_is_some() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = false;
        let class_year = vec![];
        let embargo_lift = Some(vec!["2100-01-01".to_owned()]);
        let embargo_terms = None;
        assert_eq!(
            on_site_only(
                location,
                access_rights,
                mudd_walkin,
                class_year,
                embargo_lift,
                embargo_terms
            ),
            true
        );
    }

    #[test]
    fn it_is_not_onsite_only_when_embargo_lift_is_past() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = false;
        let class_year = vec![];
        let embargo_lift = Some(vec!["2000-01-01".to_owned()]);
        let embargo_terms = None;
        assert_eq!(
            on_site_only(
                location,
                access_rights,
                mudd_walkin,
                class_year,
                embargo_lift,
                embargo_terms
            ),
            false
        );
    }

    #[test]
    fn it_is_not_onsite_only_when_embargo_lift_is_past_and_walkin() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = true;
        let class_year = vec![];
        let embargo_lift = Some(vec!["2000-01-01".to_owned()]);
        let embargo_terms = None;
        assert_eq!(
            on_site_only(
                location,
                access_rights,
                mudd_walkin,
                class_year,
                embargo_lift,
                embargo_terms
            ),
            false
        );
    }

    #[test]
    fn it_is_onsite_only_when_prior_to_2013() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = true;
        let class_year = vec!["2012-01-01T00:00:00Z".to_owned()];
        let embargo_lift = Some(vec!["2000-01-01".to_owned()]);
        let embargo_terms = None;
        assert_eq!(
            on_site_only(
                location,
                access_rights,
                mudd_walkin,
                class_year,
                embargo_lift,
                embargo_terms
            ),
            true
        );
    }

    #[test]
    fn it_is_not_onsite_only_when_from_2013() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = true;
        let class_year = vec!["2013-01-01T00:00:00Z".to_owned()];
        let embargo_lift = Some(vec!["2000-01-01".to_owned()]);
        let embargo_terms = None;
        assert_eq!(
            on_site_only(
                location,
                access_rights,
                mudd_walkin,
                class_year,
                embargo_lift,
                embargo_terms
            ),
            false
        );
    }

    #[test]
    fn it_is_not_onsite_only_when_physical_location_is_true() {
        let location = true;
        let access_rights = false;
        let mudd_walkin = false;
        let class_year = vec![];
        let embargo_lift = None;
        let embargo_terms = None;
        assert_eq!(
            on_site_only(
                location,
                access_rights,
                mudd_walkin,
                class_year,
                embargo_lift,
                embargo_terms
            ),
            false
        );
    }

    #[test]
    fn it_is_not_onsite_only_when_no_restrictions_field() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = false;
        let class_year = vec![];
        let embargo_lift = None;
        let embargo_terms = None;
        assert_eq!(
            on_site_only(
                location,
                access_rights,
                mudd_walkin,
                class_year,
                embargo_lift,
                embargo_terms
            ),
            false
        );
    }

    #[test]
    fn it_can_determine_if_class_year_would_have_physical_holdings() {
        let class_years = vec!["2010".to_string()];
        assert_eq!(physical_class_year(class_years), true);
    }

    #[test]
    fn it_can_determine_if_class_year_is_too_new_for_physical_holdings() {
        let class_years = vec!["2013".to_string()];
        assert_eq!(physical_class_year(class_years), false);
    }
}
