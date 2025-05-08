use serde::{ser::SerializeStruct, Serialize};

pub fn call_number(non_ark_ids: Option<Vec<String>>) -> String {
    let ids = non_ark_ids.unwrap_or_default();
    if !ids.is_empty() {
        format!("AC102 {}", ids.first().unwrap())
    } else {
        "AC102".to_string()
    }
}

pub fn online_holding_string(non_ark_ids: Option<Vec<String>>) -> Option<String> {
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
            call_number: call_number(non_ark_ids),
        },
    })
    .ok()
}

pub fn physical_class_year(class_years: Vec<String>) -> bool {
    match class_years.first() {
        Some(year) => year < &"2013".to_string(),
        None => false
    }
}

// let location = "pu.location";
// let access_rights = "pu.rights.accessRights";
// let mudd_walkin = "pu.mudd.walkin";
// let classyear = "pu.date.classyear";
// let embargo_lift = "pu.embargo.lift";
// let embargo_terms = "pu.embargo.terms";
pub fn on_site_only(
    location: Option<Vec<String>>,
    access_rights: Option<String>,
    mudd_walkin: Option<Vec<String>>,
    class_year: Option<Vec<String>>,
    embargo_lift: Option<Vec<String>>,
    embargo_terms: Option<Vec<String>>,
) -> bool {

    true
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
    use super::*;

    #[test]
    fn it_can_create_call_number() {
        assert_eq!(
            call_number(Some(vec![
                "123".to_owned(),
                "456".to_owned(),
                "789".to_owned()
            ])),
            "AC102 123"
        );
        assert_eq!(call_number(Some(vec![])), "AC102");
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
    fn it_can_determine_if_onsite_only() {
        let location = Some(vec!["physical location".to_string()]);
        let access_rights = None;
        let mudd_walkin = None;
        let class_year = None;
        let embargo_lift = None;
        let embargo_terms = None;
        assert_eq!(on_site_only(location, access_rights, mudd_walkin, class_year, embargo_lift, embargo_terms), true)
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
