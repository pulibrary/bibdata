// This module describes the dates from the 008

use std::{fmt::Display, str::FromStr, sync::LazyLock};

use marctk::Record;
use regex::Regex;

#[derive(Debug, PartialEq)]
pub enum DateType {
    NoDatesGivenBCDateInvolved,
    ContinuousResourceCurrentlyPublished,
    ContinuousResourceCeasedPublication,
    DetailedDate,
    InclusiveDatesOfCollection,
    RangeOfYearsOfBulkOfCollection,
    MultipleDates,
    DatesUnknown,
    DateOfDistributionReleaseIssueAndProductionRecordingSessionWhenDifferent,
    QuestionableDate,
    ReprintReissueDateAndOriginalDate,
    SingleKnownDateProbableDate,
    PublicationDateAndCopyrightDate,
    ContinuingResourceStatusUnknown,
    None,
}

impl From<char> for DateType {
    fn from(value: char) -> Self {
        match value {
            'b' => Self::NoDatesGivenBCDateInvolved,
            'c' => Self::ContinuousResourceCurrentlyPublished,
            'd' => Self::ContinuousResourceCeasedPublication,
            'e' => Self::DetailedDate,
            'i' => Self::InclusiveDatesOfCollection,
            'k' => Self::RangeOfYearsOfBulkOfCollection,
            'm' => Self::MultipleDates,
            'n' => Self::DatesUnknown,
            'p' => Self::DateOfDistributionReleaseIssueAndProductionRecordingSessionWhenDifferent,
            'r' => Self::ReprintReissueDateAndOriginalDate,
            's' => Self::SingleKnownDateProbableDate,
            't' => Self::PublicationDateAndCopyrightDate,
            'u' => Self::ContinuingResourceStatusUnknown,
            _ => Self::None,
        }
    }
}

impl From<&Record> for DateType {
    fn from(record: &Record) -> Self {
        match record
            .get_control_fields("008")
            .into_iter()
            .next()
            .and_then(|field| field.content().chars().nth(6))
        {
            Some(code) => DateType::from(code),
            None => DateType::None,
        }
    }
}

#[derive(Debug, PartialEq)]
pub enum Date {
    KnownYear(String),          // e.g. 1995
    PartiallyKnownYear(String), // e.g. 198u
    UnknownYear,                // e.g. uuuu
    YearNotAvailable,           // e.g. 9999
}

#[derive(Debug)]
pub struct InvalidDateString;

impl FromStr for Date {
    type Err = InvalidDateString;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "9999" => Ok(Self::YearNotAvailable),
            "uuuu" => Ok(Self::UnknownYear),
            s if is_known_year(s) => Ok(Self::KnownYear(s.to_string())),
            s if is_partially_known_year(s) => Ok(Self::PartiallyKnownYear(s.to_string())),
            _ => Err(InvalidDateString),
        }
    }
}

fn is_known_year(s: &str) -> bool {
    s.len() == 4 && s.chars().all(|char| char.is_numeric())
}

fn is_partially_known_year(s: &str) -> bool {
    static PARTIALLY_KNOWN_YEAR: LazyLock<Regex> =
        LazyLock::new(|| Regex::new(r"^[u\d]{4}$").unwrap());
    PARTIALLY_KNOWN_YEAR.is_match(s)
}

#[derive(Debug, PartialEq)]
pub struct EndDate(Date);

#[derive(Debug)]
pub struct NoEndDate;

impl TryFrom<&Record> for EndDate {
    type Error = NoEndDate;

    fn try_from(record: &Record) -> Result<Self, Self::Error> {
        let year = record
            .get_control_fields("008")
            .into_iter()
            .next()
            .ok_or(NoEndDate)?
            .content()
            .get(11..15)
            .ok_or(NoEndDate)?;

        match Date::from_str(year) {
            Ok(date) => Ok(Self(date)),
            Err(_) => Err(NoEndDate),
        }
    }
}

impl Display for EndDate {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match &self.0 {
            Date::KnownYear(year) => {
                write!(f, "{year}")
            }
            Date::PartiallyKnownYear(year) => {
                // assume 9, since we are in EndDate and it is the latest possible
                write!(f, "{}", year.replace("u", "9"))
            }
            _ => Ok(()),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_gets_the_end_date_from_a_record() {
        let record = Record::from_breaker("=008 940720d19761979it mr 0 a0ita d").unwrap();
        let end_date = EndDate::try_from(&record).unwrap();
        assert_eq!(end_date, EndDate(Date::KnownYear("1979".to_owned())));
    }

    #[test]
    fn it_gets_partially_unknown_end_date_from_a_record() {
        let record = Record::from_breaker("=008 940720d1976197uit mr 0 a0ita d").unwrap();
        let end_date = EndDate::try_from(&record).unwrap();
        assert_eq!(
            end_date,
            EndDate(Date::PartiallyKnownYear("197u".to_owned()))
        );
    }

    #[test]
    fn it_gets_unknown_end_date_from_a_record() {
        let record = Record::from_breaker("=008 940720d1976uuuuit mr 0 a0ita d").unwrap();
        let end_date = EndDate::try_from(&record).unwrap();
        assert_eq!(end_date, EndDate(Date::UnknownYear));
    }

    #[test]
    fn it_gets_end_date_year_not_available_from_a_record() {
        let record = Record::from_breaker("=008 940720d19769999it mr 0 a0ita d").unwrap();
        let end_date = EndDate::try_from(&record).unwrap();
        assert_eq!(end_date, EndDate(Date::YearNotAvailable));
    }

    #[test]
    fn it_does_not_get_the_end_date_from_a_record_with_no_008() {
        let record = Record::new();
        assert!(EndDate::try_from(&record).is_err());
    }

    #[test]
    fn it_does_not_get_the_end_date_from_an_incomplete_008() {
        let record = Record::from_breaker("=008 940720d1976197").unwrap();
        assert!(EndDate::try_from(&record).is_err());
    }
}
