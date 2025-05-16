// This module is responsible for handling embargoed theses

use chrono::prelude::*;
use parse_datetime::parse_datetime;

#[derive(Debug, PartialEq)]
pub enum Embargo {
    None,
    Current(String),
    Expired,
    Invalid,
}

impl Embargo {
    pub fn from_dates(
        lift_dates: Option<&Vec<String>>,
        terms_dates: Option<&Vec<String>>,
        doc_id: &str,
    ) -> Embargo {
        match raw_embargo_date(lift_dates, terms_dates) {
            Some(date) => match parse_datetime(date) {
                Ok(parsed) => {
                    if parsed > Utc::now() {
                        Self::Current(embargo_text(lift_dates, terms_dates, doc_id))
                    } else {
                        Self::Expired
                    }
                }
                Err(_) => Self::Invalid,
            },
            None => Self::None,
        }
    }
}

fn embargo_text(
    lift_dates: Option<&Vec<String>>,
    terms_dates: Option<&Vec<String>>,
    doc_id: &str,
) -> String {
    match embargo_date(lift_dates, terms_dates) {
        Some(date) => format!(
            "This content is embargoed until {}. For more information contact the \
            <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/{}\">\
            Mudd Manuscript Library</a>.",
            date, doc_id
        ),
        None => String::default()
    }
}

fn embargo_date(
    lift_dates: Option<&Vec<String>>,
    terms_dates: Option<&Vec<String>>,
) -> Option<String> {
    parsed_embargo_date(lift_dates, terms_dates)
        .map(|date| format!("{}", date.format("%B %-d, %Y")))
}

fn parsed_embargo_date(
    lift_dates: Option<&Vec<String>>,
    terms_dates: Option<&Vec<String>>,
) -> Option<DateTime<FixedOffset>> {
    match raw_embargo_date(lift_dates, terms_dates) {
        Some(date) => parse_datetime(date).ok(),
        None => None,
    }
}

fn raw_embargo_date(
    lift_dates: Option<&Vec<String>>,
    terms_dates: Option<&Vec<String>>,
) -> Option<String> {
    lift_dates
        .unwrap_or(&Vec::new())
        .iter()
        .chain(terms_dates.unwrap_or(&Vec::new()).iter())
        .next()
        .cloned()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_embargo_from_dates() {
        assert!(matches!(
            Embargo::from_dates(None, Some(&vec!["2100-07-13".to_owned()]), "123"),
            Embargo::Current(_)
        ));
        assert!(matches!(
            Embargo::from_dates(Some(&vec!["2100-07-13".to_owned()]), None, "123"),
            Embargo::Current(_)
        ));
        assert!(matches!(
            Embargo::from_dates(
                Some(&vec!["2100-07-13".to_owned()]),
                Some(&vec!["2100-08-15".to_owned()]),
                "123"
            ),
            Embargo::Current(_)
        ));

        assert_eq!(Embargo::from_dates(None, None, "123"), Embargo::None);
        assert_eq!(
            Embargo::from_dates(None, Some(&vec!["1880-01-01".to_owned()]), "123"),
            Embargo::Expired
        );
        assert_eq!(
            Embargo::from_dates(None, Some(&vec!["unparseable date".to_owned()]), "123"),
            Embargo::Invalid
        );
    }

    #[test]
    fn test_embargo_date() {
        assert_eq!(
            embargo_date(None, Some(&vec!["2100-07-13".to_owned()])).unwrap(),
            "July 13, 2100"
        );
        assert_eq!(
            embargo_date(Some(&vec!["2100-07-13".to_owned()]), None).unwrap(),
            "July 13, 2100"
        );
        assert_eq!(
            embargo_date(
                Some(&vec!["2100-07-13".to_owned()]),
                Some(&vec!["2100-08-15".to_owned()])
            )
            .unwrap(),
            "July 13, 2100"
        );
        assert_eq!(
            embargo_date(None, Some(&vec!["1880-01-01".to_owned()])),
            Some("January 1, 1880".to_owned())
        );

        assert_eq!(embargo_date(None, None), None);
        assert_eq!(
            embargo_date(None, Some(&vec!["unparseable date".to_owned()])),
            None
        );
    }

    #[test]
    fn test_embargo_text() {
        assert_eq!(embargo_text(None, Some(&vec!["2100-07-13".to_owned()]), "dsp01br86b694j"),
        "This content is embargoed until July 13, 2100. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/dsp01br86b694j\">Mudd Manuscript Library</a>.");
    }
}
