use chrono::prelude::*;
use parse_datetime::parse_datetime;

pub fn has_current_embargo(lift_dates: Option<Vec<String>>, terms_dates: Option<Vec<String>>) -> bool {
    let raw_dates = match (lift_dates, terms_dates) {
        (None, None) => { return false },
        (Some(v), None) => v,
        (None, Some(v)) => v,
        (Some(v1), Some(v2)) => {
            let mut all_dates = v1.clone();
            all_dates.extend(v2);
            all_dates
        }
    };
    match raw_dates.first() {
        Some(date) => {
            if let Ok(parsed) = parse_datetime(date) {
                parsed > Utc::now()
            } else { false }
        }
        None => false
    }
}


#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_has_current_embargo() {
        assert!(has_current_embargo(None, Some(vec!["2100-07-13".to_string()])));
        assert!(has_current_embargo(Some(vec!["2100-07-13".to_string()]), None));
        assert!(has_current_embargo(Some(vec!["2100-07-13".to_string()]), Some(vec!["2100-08-15".to_string()])));
        assert!(!has_current_embargo(None, None));
        assert!(!has_current_embargo(None, Some(vec!["1880-01-01".to_string()])));
        assert!(!has_current_embargo(None, Some(vec!["unparseable date".to_string()])));
    }
}
