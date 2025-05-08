use chrono::prelude::*;
use parse_datetime::parse_datetime;

pub fn has_current_embargo(
    lift_dates: Option<Vec<String>>,
    terms_dates: Option<Vec<String>>,
) -> bool {
    match parsed_embargo_date(lift_dates, terms_dates) {
        Some(date) => date > Utc::now(),
        None => false,
    }
}

pub fn embargo_text(
    lift_dates: Option<Vec<String>>,
    terms_dates: Option<Vec<String>>,
    doc_id: String,
) -> String {
    match embargo_date(lift_dates, terms_dates) {
        Some(date) => format!(
            "This content is embargoed until {}. For more information contact the \
            <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/{}\">\
            Mudd Manuscript Library</a>.",
            date, doc_id
        ),
        None => "".to_owned()
    }
}

pub fn embargo_date(
    lift_dates: Option<Vec<String>>,
    terms_dates: Option<Vec<String>>,
) -> Option<String> {
    parsed_embargo_date(lift_dates, terms_dates)
        .map(|date| format!("{}", date.format("%B %-d, %Y")))
}

pub fn has_embargo_date(lift_dates: Option<Vec<String>>, terms_dates: Option<Vec<String>>) -> bool {
    raw_embargo_date(lift_dates, terms_dates).is_some()
}

pub fn has_parseable_embargo_date(
    lift_dates: Option<Vec<String>>,
    terms_dates: Option<Vec<String>>,
) -> bool {
    parsed_embargo_date(lift_dates, terms_dates).is_some()
}

fn parsed_embargo_date(
    lift_dates: Option<Vec<String>>,
    terms_dates: Option<Vec<String>>,
) -> Option<DateTime<FixedOffset>> {
    match raw_embargo_date(lift_dates, terms_dates) {
        Some(date) => parse_datetime(date).ok(),
        None => None,
    }
}

fn raw_embargo_date(
    lift_dates: Option<Vec<String>>,
    terms_dates: Option<Vec<String>>,
) -> Option<String> {
    match (lift_dates, terms_dates) {
        (None, None) => return None,
        (Some(v), None) => v,
        (None, Some(v)) => v,
        (Some(v1), Some(v2)) => {
            let mut all_dates = v1.clone();
            all_dates.extend(v2);
            all_dates
        }
    }
    .first()
    .cloned()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_has_current_embargo() {
        assert!(has_current_embargo(
            None,
            Some(vec!["2100-07-13".to_owned()])
        ));
        assert!(has_current_embargo(
            Some(vec!["2100-07-13".to_owned()]),
            None
        ));
        assert!(has_current_embargo(
            Some(vec!["2100-07-13".to_owned()]),
            Some(vec!["2100-08-15".to_owned()])
        ));

        assert!(!has_current_embargo(None, None));
        assert!(!has_current_embargo(
            None,
            Some(vec!["1880-01-01".to_owned()])
        ));
        assert!(!has_current_embargo(
            None,
            Some(vec!["unparseable date".to_owned()])
        ));
    }

    #[test]
    fn test_embargo_date() {
        assert_eq!(
            embargo_date(None, Some(vec!["2100-07-13".to_owned()])).unwrap(),
            "July 13, 2100"
        );
        assert_eq!(
            embargo_date(Some(vec!["2100-07-13".to_owned()]), None).unwrap(),
            "July 13, 2100"
        );
        assert_eq!(
            embargo_date(
                Some(vec!["2100-07-13".to_owned()]),
                Some(vec!["2100-08-15".to_owned()])
            )
            .unwrap(),
            "July 13, 2100"
        );
        assert_eq!(
            embargo_date(None, Some(vec!["1880-01-01".to_owned()])),
            Some("January 1, 1880".to_owned())
        );

        assert_eq!(embargo_date(None, None), None);
        assert_eq!(
            embargo_date(None, Some(vec!["unparseable date".to_owned()])),
            None
        );
    }

    #[test]
    fn test_embargo_text() {
        assert_eq!(embargo_text(None, Some(vec!["2100-07-13".to_owned()]), "dsp01br86b694j".to_owned()),
        "This content is embargoed until July 13, 2100. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/dsp01br86b694j\">Mudd Manuscript Library</a>.");
    }
}
