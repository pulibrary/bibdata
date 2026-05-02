use std::{collections::HashMap, sync::LazyLock};

use marctk::{Field, Record};
use serde::Deserialize;

use crate::marc::alma_code_start_22;

const HOLDING_LOCATION_JSON: &str =
    include_str!("../../../../../config/locations/holding_locations.json");

#[derive(Deserialize)]
pub struct Library<'a> {
    label: &'a str,
}

#[derive(Deserialize)]
pub struct Location<'a> {
    label: &'a str,
    code: &'a str,
    library: Library<'a>,
}

static LOCATIONS: LazyLock<HashMap<&str, Location>> = LazyLock::new(|| {
    let locations: Vec<Location> = serde_json::from_str(HOLDING_LOCATION_JSON)
        .expect("Could not parse the holding_locations.json");
    let mut hash = HashMap::new();
    for location in locations {
        hash.insert(location.code, location);
    }
    hash
});

pub fn location_label(code: &str) -> Option<&str> {
    LOCATIONS.get(code).map(|location| location.label)
}

pub fn library_label(code: &str) -> Option<&str> {
    LOCATIONS.get(code).map(|location| location.library.label)
}

pub fn location_codes(record: &Record) -> Vec<String> {
    let mut codes = Vec::new();
    for field_852_ref in record.get_fields("852") {
        let field_852 = field_852_ref.clone();

        let holding_id = field_852
            .first_subfield("8")
            .map(|sf| sf.content().to_string());

        let field_876 = holding_id.as_ref().and_then(|id| {
            let all_876 = record.get_fields("876");

            all_876
                .iter()
                .find(|field_876| {
                    field_876
                        .first_subfield("0")
                        .map(|sf| sf.content().to_string())
                        == Some(id.clone())
                })
                .cloned()
        });

        // Calculate permanent and current location codes
        let perm_code = permanent_location_code(&field_852);
        let curr_code = field_876.and_then(current_location_code);

        let location_code = match (curr_code, perm_code) {
            (Some(curr), Some(perm)) if curr == "RES_SHARE$IN_RS_REQ" => Some(perm),
            (Some(curr), Some(perm)) if curr != perm => Some(curr),
            (Some(curr), _) => Some(curr),
            (None, Some(perm)) => Some(perm),
            _ => None,
        };
        if let Some(c) = location_code {
            codes.push(c);
        }
    }
    codes
}

pub fn permanent_location_code(field: &Field) -> Option<String> {
    match field.first_subfield("8") {
        Some(alma_code) if alma_code_start_22(alma_code.content().to_string()) => {
            let b = field
                .first_subfield("b")
                .map(|subfield| subfield.content())
                .unwrap_or_default();
            let c = field
                .first_subfield("c")
                .map(|subfield| subfield.content())
                .unwrap_or_default();
            if c.is_empty() {
                Some(b.to_string())
            } else {
                Some(format!("{b}${c}"))
            }
        }
        None if field.first_subfield("0").is_some() => field
            .first_subfield("b")
            .map(|subfield| subfield.content().to_string()),
        _ => None,
    }
}

pub fn current_location_code(field: &Field) -> Option<String> {
    match (field.first_subfield("y"), field.first_subfield("z")) {
        (Some(y), Some(z)) => Some(format!("{}${}", y.content(), z.content())),
        _ => None,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_get_the_location_label() {
        assert_eq!(location_label("scsbcul"), Some("Remote Storage"));
    }

    #[test]
    fn it_can_get_the_library_label() {
        assert_eq!(library_label("scsbcul"), Some("ReCAP"));
    }
}
