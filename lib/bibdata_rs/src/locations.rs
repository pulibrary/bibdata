use std::{collections::HashMap, sync::LazyLock};
use serde::Deserialize;

#[derive(Deserialize)]
pub struct Library<'a> {
    pub label: &'a str,
}

#[derive(Deserialize)]
pub struct Location<'a> {
    pub label: &'a str,
    pub code: &'a str,
    pub library: Library<'a>,
}

const HOLDING_LOCATION_JSON: &str =
    include_str!("../../../config/locations/holding_locations.json");

pub static HOLDING_LOCATIONS: LazyLock<HashMap<&str, Location>> = LazyLock::new(|| {
    let locations: Vec<Location> = serde_json::from_str(HOLDING_LOCATION_JSON)
        .expect("Could not parse the holding_locations.json");
    let mut hash = HashMap::new();
    for location in locations {
        hash.insert(location.code, location);
    }
    hash
});
