use crate::marc::{
    extract_values::ExtractValues,
    holdings::{
        Field852, Field876, Item,
        holding_location::{library_label, location_label},
        textual_holdings,
    },
};
use marctk::{Field, Record};
use serde::Serialize;

// This module is responsible for handling holdings from our SCSB partners

// This is also called the CGD
#[derive(Clone, Copy, Debug, PartialEq, Serialize)]
pub enum CollectionGroup {
    Committed,
    Open,
    Private,
    Shared,
    Uncommittable,
}

#[derive(Debug)]
pub struct InvalidCollectionGroup;

impl TryFrom<&str> for CollectionGroup {
    type Error = InvalidCollectionGroup;

    fn try_from(s: &str) -> Result<Self, Self::Error> {
        match s.trim().to_lowercase().as_str() {
            "committed" => Ok(Self::Committed),
            "open" => Ok(Self::Open),
            "private" => Ok(Self::Private),
            "shared" => Ok(Self::Shared),
            "uncommittable" => Ok(Self::Uncommittable),
            _ => Err(InvalidCollectionGroup),
        }
    }
}

pub fn partner_holdings(record: &Record) -> impl Iterator<Item = PartnerHolding<'_>> {
    record.extract_field_values_by(
        |field| field.tag() == "852",
        |field| {
            let field = Field852(field);
            let holding_id = field.get("0")?;

            let items: Vec<PartnerItem<'_>> = record
                .extract_field_values_by(
                    |field| field.tag() == "876" && field_has_scsb_holding_id(field, holding_id),
                    |field| {
                        let item = PartnerItem::from(Field876(field));
                        if item.cgd == Some(CollectionGroup::Private) {
                            None
                        } else {
                            Some(item)
                        }
                    },
                )
                .collect();
            if items.is_empty() {
                return None;
            }

            let location_code = field.get("b");
            let location = location_code
                .and_then(|code| location_label(code))
                .or(location_code);
            let library = location_code
                .and_then(|code| library_label(code))
                .or(location_code);
            let call_number = field.call_number();
            let call_number_browse = field.call_number();
            let sub_location = field.get("k").map(|value| vec![value]);
            let shelving_title = field.get("l").map(|value| vec![value]);
            let location_note = field.get("z").map(|value| vec![value]);

            let location_has = record
                .extract_field_values_by(
                    |field| field.tag() == "866" && field_has_scsb_holding_id(field, holding_id),
                    textual_holdings,
                )
                .collect();
            let supplements = record
                .extract_field_values_by(
                    |field| field.tag() == "867" && field_has_scsb_holding_id(field, holding_id),
                    textual_holdings,
                )
                .collect();
            let indexes = record
                .extract_field_values_by(
                    |field| field.tag() == "868" && field_has_scsb_holding_id(field, holding_id),
                    textual_holdings,
                )
                .collect();

            Some(PartnerHolding {
                holding_id,
                location_code,
                location,
                library,
                call_number,
                call_number_browse,
                sub_location,
                shelving_title,
                location_note,
                items,
                location_has,
                supplements,
                indexes,
            })
        },
    )
}

// Does the field match the SCSB holding id?
fn field_has_scsb_holding_id(field: &Field, holding_id: &str) -> bool {
    field
        .first_subfield("0")
        .is_some_and(|id_subfield| id_subfield.content() == holding_id)
}

#[derive(Debug, Default, PartialEq, Serialize)]
pub struct PartnerHolding<'a> {
    pub holding_id: &'a str,
    location_code: Option<&'a str>,
    location: Option<&'a str>,
    library: Option<&'a str>,
    call_number: Option<String>,
    call_number_browse: Option<String>,
    sub_location: Option<Vec<&'a str>>,
    shelving_title: Option<Vec<&'a str>>,
    location_note: Option<Vec<&'a str>>,
    items: Vec<PartnerItem<'a>>,
    location_has: Vec<String>,
    supplements: Vec<String>,
    indexes: Vec<String>,
}

#[derive(Copy, Clone, Debug, Default, PartialEq, Serialize)]
pub struct PartnerItem<'a> {
    holding_id: Option<&'a str>,
    description: Option<&'a str>,
    id: Option<&'a str>,
    status_at_load: Option<&'a str>,
    barcode: Option<&'a str>,
    copy_number: Option<&'a str>,
    use_statement: Option<&'a str>,
    storage_location: Option<&'a str>,
    cgd: Option<CollectionGroup>,
    collection_code: Option<&'a str>,
}

impl<'a> From<Field876<'a>> for PartnerItem<'a> {
    fn from(field: Field876<'a>) -> Self {
        let holding_id = field.get("0");
        let description = field.get("3");
        let id = field.get("a");
        let status_at_load = field.get("j");
        let barcode = field.get("p");
        let copy_number = field.get("t");
        let use_statement = field.get("h");
        let storage_location = field.get("l");
        let cgd = field.get("x").and_then(|cgd| cgd.try_into().ok());
        let collection_code = field.get("z");
        Self {
            holding_id,
            description,
            id,
            status_at_load,
            barcode,
            copy_number,
            use_statement,
            storage_location,
            cgd,
            collection_code,
        }
    }
}

impl<'a> Item for PartnerItem<'a> {}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_creates_a_simple_partner_holding() {
        let record = Record::from_breaker(
            r#"=852 8\ $hReCAP .b173860199$06769856$bscsbnypl
=876 \\ $06769856$a10924375$jAvailable$p33333081091841$t1$xShared$zNH$lRECAP"#,
        )
        .unwrap();
        let holdings: Vec<PartnerHolding<'_>> = partner_holdings(&record).collect();
        assert_eq!(
            holdings,
            vec![PartnerHolding {
                holding_id: "6769856",
                location_code: Some("scsbnypl"),
                location: Some("Remote Storage"),
                library: Some("ReCAP"),
                call_number: Some("ReCAP .b173860199".to_string()),
                call_number_browse: Some("ReCAP .b173860199".to_string()),
                items: vec![PartnerItem {
                    holding_id: Some("6769856"),
                    id: Some("10924375"),
                    status_at_load: Some("Available"),
                    barcode: Some("33333081091841"),
                    copy_number: Some("1"),
                    storage_location: Some("RECAP"),
                    cgd: Some(CollectionGroup::Shared),
                    collection_code: Some("NH"),
                    ..Default::default()
                }],
                ..Default::default()
            }]
        )
    }

    #[test]
    fn it_can_find_indexes() {
        let record = Record::from_breaker(
            r#"=852 8\ $06769856
=868 \\ $06769856$a1937-1942, 1946-1968, plus 1969/1978 cumulative vol.
=876 \\ $06769856$xShared"#,
        )
        .unwrap();
        let holdings: Vec<PartnerHolding<'_>> = partner_holdings(&record).collect();
        assert_eq!(
            holdings,
            vec![PartnerHolding {
                holding_id: "6769856",
                items: vec![PartnerItem {
                    holding_id: Some("6769856"),
                    cgd: Some(CollectionGroup::Shared),
                    ..Default::default()
                }],
                indexes: vec!["1937-1942, 1946-1968, plus 1969/1978 cumulative vol.".to_string()],
                ..Default::default()
            }]
        )
    }
}
