// This module extracts publication place information from MARC records.

use std::collections::HashMap;

use marctk::Record;
use serde_json::Value;
use std::sync::LazyLock;

pub static MARC_COUNTRIES: LazyLock<HashMap<String, String>> = LazyLock::new(|| {
    let raw = include_str!("data/marc_countries.json");
    let map: HashMap<String, String> =
        serde_json::from_str(raw).expect("Failed to parse marc_countries.json");
    map
});

/// Hierarchical pipe mapping from MARC country codes to parent/child paths.
///
/// E.g. "miu" → ["United States", "United States|||Michigan"],
/// "ja" → "Japan"
pub static MARC_COUNTRIES_HIERARCHICAL_PIPE: LazyLock<HashMap<String, Value>> =
    LazyLock::new(|| {
        let raw = include_str!("data/marc_countries_hierarchical_pipe.json");
        let map: HashMap<String, Value> = serde_json::from_str(raw)
            .expect("Failed to parse marc_countries_hierarchical_pipe.json");
        map
    });

pub fn publication_place_facet(record: &Record) -> Option<Vec<String>> {
    let code = country_code(record)?;
    MARC_COUNTRIES.get(&code).map(|name| vec![name.clone()])
}

pub fn publication_place_hierarchical_pipe_facet(record: &Record) -> Option<Vec<String>> {
    let code = country_code(record)?;
    let value = MARC_COUNTRIES_HIERARCHICAL_PIPE.get(&code)?;
    match value {
        Value::String(s) => Some(vec![s.clone()]),
        Value::Array(arr) => {
            let names: Vec<String> = arr
                .iter()
                .filter_map(|v| v.as_str().map(|s| s.to_string()))
                .collect();
            if names.is_empty() { None } else { Some(names) }
        }
        _ => None,
    }
}

fn country_code(record: &Record) -> Option<String> {
    let content = record.get_control_fields("008").first()?.content();
    let stripped: String = content.chars().skip(15).take(3).collect();
    let stripped = stripped.trim();
    maybe_not_empty(stripped.to_string())
}

#[cfg(test)]
mod tests {
    use super::*;
    use marctk::Record;

    fn record_with_008(content: &str) -> Record {
        let marc = format!("=008 {content}");
        Record::from_breaker(&marc).unwrap()
    }

    #[test]
    fn test_publication_place_facet_miu() {
        let record = record_with_008("801010s1964    miua    ab    000 0 eng  ");
        assert_eq!(
            publication_place_facet(&record),
            Some(vec!["Michigan".to_string()])
        );
    }

    #[test]
    fn test_publication_place_facet_ja() {
        let record = record_with_008("980402s1996    ja a     bc   000 0djpnod");
        assert_eq!(
            publication_place_facet(&record),
            Some(vec!["Japan".to_string()])
        );
    }

    #[test]
    fn test_publication_place_facet_unknown_code() {
        let record = record_with_008("801010s1964    ψψψ     ab    000 0 eng  ");
        assert_eq!(publication_place_facet(&record), None);
    }

    #[test]
    fn test_publication_place_facet_no_008() {
        let record = Record::new();
        assert_eq!(publication_place_facet(&record), None);
    }

    #[test]
    fn test_publication_place_facet_empty_position() {
        let record = record_with_008("801010s1964           ab    000 0 eng  ");
        assert_eq!(publication_place_facet(&record), None);
    }

    #[test]
    fn test_publication_place_hierarchical_pipe_facet_miu() {
        let record = record_with_008("801010s1964    miua    ab    000 0 eng  ");
        assert_eq!(
            publication_place_hierarchical_pipe_facet(&record),
            Some(vec![
                "United States".to_string(),
                "United States|||Michigan".to_string()
            ])
        );
    }

    #[test]
    fn test_publication_place_hierarchical_pipe_facet_ja() {
        let record = record_with_008("980402s1996    ja a     bc   000 0djpnod");
        assert_eq!(
            publication_place_hierarchical_pipe_facet(&record),
            Some(vec!["Japan".to_string()])
        );
    }

    #[test]
    fn test_publication_place_hierarchical_pipe_facet_unknown_code() {
        let record = record_with_008("801010s1964    zzz     ab    000 0 eng  ");
        assert_eq!(publication_place_hierarchical_pipe_facet(&record), None);
    }

    #[test]
    fn test_publication_place_hierarchical_pipe_facet_no_008() {
        let record = Record::new();
        assert_eq!(publication_place_hierarchical_pipe_facet(&record), None);
    }

    #[test]
    fn test_country_code_extraction() {
        // "xx" at position 15-16 with space at 17 → strip → "xx"
        let record = record_with_008("801010s1964    xx        ab    000 0 eng  ");
        assert_eq!(country_code(&record), Some("xx".to_string()));
    }

    #[test]
    fn test_marc_countries_map_loaded() {
        assert!(!MARC_COUNTRIES.is_empty());
        assert_eq!(MARC_COUNTRIES.get("miu"), Some(&"Michigan".to_string()));
        assert_eq!(MARC_COUNTRIES.get("ja"), Some(&"Japan".to_string()));
    }

    #[test]
    fn test_marc_countries_hierarchical_pipe_map_loaded() {
        assert!(!MARC_COUNTRIES_HIERARCHICAL_PIPE.is_empty());
        let miu = MARC_COUNTRIES_HIERARCHICAL_PIPE.get("miu").unwrap();
        assert_eq!(
            miu,
            &Value::Array(vec![
                Value::String("United States".to_string()),
                Value::String("United States|||Michigan".to_string())
            ])
        );
        let ja = MARC_COUNTRIES_HIERARCHICAL_PIPE.get("ja").unwrap();
        assert_eq!(ja, &Value::String("Japan".to_string()));
    }
}
