use itertools::Itertools;
use jiff::{Timestamp, Zoned, tz::TimeZone};
use marctk::{Record, Subfield};
use parse_datetime::parse_datetime_at_date;

use crate::marc::{
    alma::{AlmaElectronicPortfolio, AlmaHoldingId},
    extract_values::ExtractValues,
    scsb::is_scsb,
};

#[derive(Debug, PartialEq)]
struct Dates {
    start_year: Option<i16>,
    end_year: Option<i16>,
}

#[derive(Debug, PartialEq)]
struct RecordHasNoDates;

impl TryFrom<&Record> for Dates {
    type Error = RecordHasNoDates;

    fn try_from(record: &Record) -> Result<Self, Self::Error> {
        let field = record
            .control_fields()
            .iter()
            .find(|field| field.tag() == "008");
        match field {
            Some(field) => {
                let mut char_indices = field.content().char_indices();
                let (date1_start, _) = char_indices.nth(7).unwrap();
                let (date1_end, _) = char_indices.nth(3).unwrap();
                Ok(Dates {
                    start_year: Some(field.content()[date1_start..date1_end].parse().unwrap()),
                    end_year: None,
                })
            }
            None => Err(RecordHasNoDates),
        }
    }
}

pub fn cataloged_date(record: &Record) -> Option<String> {
    if is_scsb(record) {
        return None;
    }

    let item_edit_date = record
        .extract_field_values_by(
            |field| {
                field.tag() == "876"
                    && field
                        .first_subfield("0")
                        .is_some_and(|subfield| AlmaHoldingId::from(subfield).is_valid())
            },
            |field| field.first_subfield("d").map(Subfield::content),
        )
        .sorted();

    let electronic_edit_date = record
        .extract_field_values_by(
            |field| {
                matches!(
                    AlmaElectronicPortfolio::try_from(field),
                    Ok(AlmaElectronicPortfolio::Active)
                )
            },
            |field| field.first_subfield("w").map(Subfield::content),
        )
        .sorted();

    let record_edit_date = record
        .extract_field_values_by(
            |field| field.tag() == "950",
            |field| field.first_subfield("b").map(Subfield::content),
        )
        .sorted();

    item_edit_date
        .chain(electronic_edit_date)
        .chain(record_edit_date)
        .filter_map(|raw_date| {
            parse_datetime_at_date(Zoned::new(Timestamp::UNIX_EPOCH, TimeZone::UTC), raw_date)
                .ok()
                .map(|parsed| {
                    parsed
                        .timestamp()
                        .strftime("%Y-%m-%dT%H:%M:%SZ")
                        .to_string()
                })
        })
        .next()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_gets_cataloged_date_from_876() {
        let record =
            Record::from_breaker("=876 \\$022710806450006421$d2021-07-13 12:24:58").unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }

    #[test]
    fn it_gets_first_date_when_multiple_876() {
        let record = Record::from_breaker(
            "=876 \\$022710806450006421$d2021-07-15 12:24:58
=876 \\$022710806450006421$d2021-07-13 12:24:58
=876 \\$022710806450006421$d2021-07-17 12:24:58
=876 \\$022710806450006421$d2021-07-16 12:24:58",
        )
        .unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }

    #[test]
    fn it_gets_cataloged_date_from_active_951_portfolio() {
        let record =
            Record::from_breaker("=951 \\$aAvailable$8531026240820006421$w2021-07-13 12:24:58")
                .unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }

    #[test]
    fn it_gets_cataloged_date_from_950_record_date() {
        let record = Record::from_breaker("=950 \\$b2021-07-13 12:24:58").unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }

    #[test]
    fn it_prefers_the_876_date() {
        let record = Record::from_breaker(
            "=876 \\$022710806450006421$d2021-07-13 12:24:58
=951 \\$aAvailable$8531026240820006421$1995-07-13 12:24:58
=950 \\$b2030-07-13 12:24:58",
        )
        .unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }

    #[test]
    fn it_can_get_start_year_from_008() {
        let record = Record::from_breaker("=008 990924u1977uuuumiuuu p 0 a0eng^^").unwrap();
        assert_eq!(
            Dates::try_from(&record),
            Ok(Dates {
                start_year: Some(1977),
                end_year: None
            })
        );
    }
}
