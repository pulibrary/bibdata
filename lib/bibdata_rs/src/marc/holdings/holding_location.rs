use std::{collections::HashMap, sync::LazyLock};

use serde::Deserialize;

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
