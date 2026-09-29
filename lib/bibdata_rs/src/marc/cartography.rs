//! This module is responsible for extracting cartographic data from a MARC record

use crate::marc::variable_length_field::VariableLengthField;
use marctk::{Field, Record};
use regex::Regex;
use std::fmt::{self, Display};
use std::ops::Deref;
use std::str::FromStr;
use std::sync::LazyLock;

pub fn coverage_display(record: &Record) -> Option<String> {
    BoundingBox::try_from(record)
        .ok()
        .map(|bounding_box| bounding_box.to_string())
}

struct Field034<'a>(&'a Field);
impl<'a> Field034<'a> {
    pub fn westernmost_longitude(&'a self) -> Option<&'a str> {
        self.get("d")
    }

    pub fn easternmost_longitude(&'a self) -> Option<&'a str> {
        self.get("e")
    }

    pub fn northernmost_latitude(&'a self) -> Option<&'a str> {
        self.get("f")
    }

    pub fn southernmost_latitude(&'a self) -> Option<&'a str> {
        self.get("g")
    }
}

impl Deref for Field034<'_> {
    type Target = Field;

    fn deref(&self) -> &Self::Target {
        self.0
    }
}

#[derive(Debug, PartialEq)]
pub enum CartographicParsingError {
    NoData,
    IncompleteData,
    InvalidFormat,
}

const COVERAGE_DETAILS: &str = "units=degrees; projection=EPSG:4326";

static VALID_DECIMAL_COORDINATE: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"^[-+]?[0-9]*\.?[0-9]+$").unwrap());

#[derive(Debug, Clone, PartialEq)]
/// A single latitude or longitude measurement
pub struct Coordinate(String);

impl FromStr for Coordinate {
    type Err = CartographicParsingError;

    fn from_str(raw: &str) -> Result<Self, Self::Err> {
        if VALID_DECIMAL_COORDINATE.is_match(raw) {
            Ok(Self(raw.to_owned()))
        } else {
            Err(Self::Err::InvalidFormat)
        }
    }
}

impl fmt::Display for Coordinate {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&self.0)
    }
}

#[derive(Debug, Clone, PartialEq)]
pub struct BoundingBox {
    pub west: Coordinate,
    pub east: Coordinate,
    pub north: Coordinate,
    pub south: Coordinate,
}

impl<'a> TryFrom<Field034<'a>> for BoundingBox {
    type Error = CartographicParsingError;

    fn try_from(field: Field034<'a>) -> Result<Self, Self::Error> {
        Ok(BoundingBox {
            west: field
                .westernmost_longitude()
                .ok_or(Self::Error::IncompleteData)
                .and_then(|raw| raw.parse())?,
            east: field
                .easternmost_longitude()
                .ok_or(Self::Error::IncompleteData)
                .and_then(|raw| raw.parse())?,
            north: field
                .northernmost_latitude()
                .ok_or(Self::Error::IncompleteData)
                .and_then(|raw| raw.parse())?,
            south: field
                .southernmost_latitude()
                .ok_or(Self::Error::IncompleteData)
                .and_then(|raw| raw.parse())?,
        })
    }
}

impl Display for BoundingBox {
    /// A string representing the box using the DCMI Box Encoding Scheme
    /// See https://www.dublincore.org/specifications/dublin-core/dcmi-box/
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.write_str(&format!(
            "northlimit={}; eastlimit={}; southlimit={}; westlimit={}; {COVERAGE_DETAILS}",
            self.north, self.east, self.south, self.west
        ))
    }
}

impl TryFrom<&Record> for BoundingBox {
    type Error = CartographicParsingError;

    fn try_from(record: &Record) -> Result<Self, Self::Error> {
        let fields = record.get_fields("034");
        match fields.first() {
            Some(field) => BoundingBox::try_from(Field034(field)),
            None => Err(CartographicParsingError::NoData),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_formats_a_complete_bounding_box() {
        let record = Record::from_breaker("=034 \\ $d-89.0$e20.2355$f25.221$g-0.2444").unwrap();
        assert_eq!(
            coverage_display(&record).as_deref(),
            Some(
                "northlimit=25.221; eastlimit=20.2355; southlimit=-0.2444; westlimit=-89.0; units=degrees; projection=EPSG:4326"
            )
        );
    }

    #[test]
    fn it_preserves_the_original_coordinate_representation() {
        let record = Record::from_breaker("=034 \\ $d-89$e20.2355$f25.221$g-0.2444").unwrap();
        assert_eq!(
            coverage_display(&record).as_deref(),
            Some(
                "northlimit=25.221; eastlimit=20.2355; southlimit=-0.2444; westlimit=-89; units=degrees; projection=EPSG:4326"
            )
        );
    }

    #[test]
    fn it_returns_none_for_a_record_without_a_034_field() {
        let record = Record::from_breaker("=245 10 $aJust a book.$bNothing cartographic.").unwrap();
        assert_eq!(coverage_display(&record), None);
    }

    #[test]
    fn it_rejects_non_numeric_coordinates() {
        let record = Record::from_breaker("=034 \\ $d-89$e20.2355$fcafé$g-0.2444").unwrap();
        assert!(coverage_display(&record).is_none());
    }

    #[test]
    fn it_requires_all_four_coordinates() {
        // This 034 field is missing subfield $g (southernmost latitude)
        let record = Record::from_breaker("=034 \\ $d-89$e20.2355$f25.221").unwrap();
        assert!(coverage_display(&record).is_none());
    }

    #[test]
    fn it_uses_the_first_of_multiple_034_fields() {
        let record =
            Record::from_breaker("=034 \\ $d-1$e1$f1$g-1\n=034 \\ $d-2$e2$f2$g-2").unwrap();
        assert_eq!(
            coverage_display(&record).as_deref(),
            Some(
                "northlimit=1; eastlimit=1; southlimit=-1; westlimit=-1; units=degrees; projection=EPSG:4326"
            )
        );
    }

    #[test]
    fn it_can_parse_coordinates() {
        assert!("-89".parse::<Coordinate>().is_ok());
        assert!("5".parse::<Coordinate>().is_ok());
        assert!(".5".parse::<Coordinate>().is_ok());
        assert!("+.5".parse::<Coordinate>().is_ok());
        assert!("25.221".parse::<Coordinate>().is_ok());
        assert!("-0.2444".parse::<Coordinate>().is_ok());
    }

    #[test]
    fn it_rejects_invalid_coordinate_strings() {
        assert!("5.".parse::<Coordinate>().is_err());
        assert!("".parse::<Coordinate>().is_err());
        assert!("-".parse::<Coordinate>().is_err());
        assert!("N0820000".parse::<Coordinate>().is_err());
        assert!("café".parse::<Coordinate>().is_err());
        assert!("1.2.3".parse::<Coordinate>().is_err());
        assert!(" 12".parse::<Coordinate>().is_err());
        assert!("12 ".parse::<Coordinate>().is_err());
    }
}
