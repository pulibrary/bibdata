// This module is responsible for describing the holdings of a thesis

use crate::{solr::ElectronicAccess, theses::embargo};
use serde::{ser::SerializeStruct, Serialize};

use ThesisAvailability::*;

pub fn call_number(non_ark_ids: Option<&Vec<String>>) -> String {
    let ids = match non_ark_ids {
        Some(value) => value,
        None => &Vec::default(),
    };
    match ids.first() {
        Some(id) => format!("AC102 {}", id),
        None => "AC102".to_string(),
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

pub fn physical_holding_string(non_ark_ids: Option<&Vec<String>>) -> Option<String> {
    serde_json::to_string(&ThesisHoldingHash {
        thesis: PhysicalHolding {
            call_number: call_number(non_ark_ids),
        },
    })
    .ok()
}

fn physical_class_year(class_years: &[String]) -> bool {
    // For theses, there is no physical copy since 2013
    // anything 2012 and prior have a physical copy
    // See docs/theses.md
    match class_years.first() {
        Some(year) => year.as_str() < "2013",
        None => false,
    }
}

// Returns a string containing a JSON key/value.  The key is the Ark URL,
// the value is an array of details about what that URL provides.
pub fn dataspace_url_with_metadata(
    identifier_uri: Option<&Vec<String>>,
    location: bool,
    access_rights: bool,
    mudd_walkin: bool,
    class_year: &[String],
    embargo: embargo::Embargo,
) -> Option<ElectronicAccess> {
    let first_ark = identifier_uri?.first()?;
    Some(ElectronicAccess {
        url: first_ark.to_owned(),
        link_text: "Thesis Central".to_owned(),
        link_description: match on_site_only(
            location,
            access_rights,
            mudd_walkin,
            &class_year,
            embargo,
        ) {
            OnSiteOnly => Some("Citation only".to_owned()),
            AvailableOffSite => Some("Full text".to_owned()),
        },
        iiif_manifest_paths: None,
        digital_content: None,
    })
}

#[derive(Debug, PartialEq)]
pub enum ThesisAvailability {
    AvailableOffSite,
    OnSiteOnly,
}

pub fn on_site_only(
    location: bool,
    access_rights: bool,
    mudd_walkin: bool,
    class_year: &[String],
    embargo: embargo::Embargo,
) -> ThesisAvailability {
    if matches!(embargo, embargo::Embargo::Current(_)) {
        return OnSiteOnly;
    };
    if !physical_class_year(&class_year) {
        return AvailableOffSite;
    }
    if location || access_rights || mudd_walkin {
        return OnSiteOnly;
    }
    AvailableOffSite
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
        assert_eq!(call_number(Some(&vec!["2377".to_owned()])), "AC102 2377");
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
    fn it_is_onsite_only_when_current_embargo() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = false;
        let class_year = &[];
        let embargo =
            embargo::Embargo::Current("This content is embargoed until July 13, 2100".to_owned());
        assert_eq!(
            on_site_only(location, access_rights, mudd_walkin, class_year, embargo),
            OnSiteOnly
        );
    }

    #[test]
    fn it_is_not_onsite_only_when_embargo_is_expired() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = false;
        let class_year = &[];
        let embargo = embargo::Embargo::Expired;
        assert_eq!(
            on_site_only(location, access_rights, mudd_walkin, class_year, embargo),
            AvailableOffSite
        );
    }

    #[test]
    fn it_is_not_onsite_only_when_embargo_is_expired_and_walkin() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = true;
        let class_year = &[];
        let embargo = embargo::Embargo::Expired;
        assert_eq!(
            on_site_only(location, access_rights, mudd_walkin, class_year, embargo),
            AvailableOffSite
        );
    }

    #[test]
    fn it_is_onsite_only_when_prior_to_2013() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = true;
        let class_year = &["2012-01-01T00:00:00Z".to_owned()];
        let embargo = embargo::Embargo::Expired;
        assert_eq!(
            on_site_only(location, access_rights, mudd_walkin, class_year, embargo),
            OnSiteOnly
        );
    }

    #[test]
    fn it_is_not_onsite_only_when_from_2013() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = true;
        let class_year = &["2013-01-01T00:00:00Z".to_owned()];
        let embargo = embargo::Embargo::Expired;
        assert_eq!(
            on_site_only(location, access_rights, mudd_walkin, class_year, embargo),
            AvailableOffSite
        );
    }

    #[test]
    fn it_is_not_onsite_only_when_physical_location_is_true() {
        let location = true;
        let access_rights = false;
        let mudd_walkin = false;
        let class_year = &[];
        let embargo = embargo::Embargo::None;
        assert_eq!(
            on_site_only(location, access_rights, mudd_walkin, class_year, embargo),
            AvailableOffSite
        );
    }

    #[test]
    fn it_is_not_onsite_only_when_no_restrictions_field() {
        let location = false;
        let access_rights = false;
        let mudd_walkin = false;
        let class_year = &[];
        let embargo = embargo::Embargo::None;
        assert_eq!(
            on_site_only(location, access_rights, mudd_walkin, class_year, embargo),
            AvailableOffSite
        );
    }

    #[test]
    fn it_can_determine_if_class_year_would_have_physical_holdings() {
        assert!(physical_class_year(&["2010".to_string()]));
    }

    #[test]
    fn it_can_determine_if_class_year_is_too_new_for_physical_holdings() {
        assert!(!physical_class_year(&["2013".to_string()]));
    }
}
