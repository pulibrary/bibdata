use serde::Deserialize;
use std::{collections::HashMap, sync::LazyLock};
pub mod ruby_bindings;
pub use ruby_bindings::register_ruby_methods;

fn default_true() -> bool {
    true
}

fn default_bool() -> bool {
    false
}
#[derive(Deserialize)]
pub struct Library<'a> {
    pub label: &'a str,
    #[serde(default)]
    pub code: &'a str,
}

// Location struct is responsible to deserialize both
// holding and delivery locations.
#[derive(Deserialize)]
pub struct Location<'a> {
    pub label: &'a str,
    #[serde(default)]
    pub code: Option<&'a str>,
    #[serde(default)]
    pub gfa_pickup: Option<&'a str>,
    pub library: Library<'a>,
    #[serde(default)]
    pub holding_library: Option<Library<'a>>,
    #[serde(default = "default_bool")]
    pub aeon_location: bool,
    #[serde(default)]
    pub recap_electronic_delivery_location: bool,
    #[serde(default = "default_true")]
    pub open: bool,
    #[serde(default = "default_true")]
    pub requestable: bool,
    #[serde(default)]
    pub always_requestable: bool,
    #[serde(default = "default_true")]
    pub circulates: bool,
    #[serde(default)]
    pub remote_storage: String,
    #[serde(default)]
    pub fulfillment_unit: Option<String>,
    #[serde(default)]
    pub delivery_locations: Vec<&'a str>,
}

#[magnus::wrap(class = "BibdataRs::Library", free_immediately, size)]
#[derive(Clone)]
pub struct LibraryRuby {
    pub label: String,
    pub code: String,
}

#[magnus::wrap(class = "BibdataRs::Location", free_immediately, size)]
#[derive(Clone)]
pub struct LocationRuby {
    pub label: String,
    pub code: String,
    pub library: LibraryRuby,
    pub holding_library: Option<LibraryRuby>,
    pub aeon_location: bool,
    pub recap_electronic_delivery_location: bool,
    pub open: bool,
    pub requestable: bool,
    pub always_requestable: bool,
    pub circulates: bool,
    pub remote_storage: String,
    pub fulfillment_unit: Option<String>,
    pub delivery_locations: Vec<String>,
}

impl<'a> From<&Location<'a>> for LocationRuby {
    fn from(location: &Location<'a>) -> Self {
        LocationRuby {
            label: location.label.to_string(),
            code: location
                .code
                .or(location.gfa_pickup)
                .unwrap_or_default()
                .to_string(),
            library: LibraryRuby {
                label: location.library.label.to_string(),
                code: location.library.code.to_string(),
            },
            holding_library: location.holding_library.as_ref().map(|l| LibraryRuby {
                label: l.label.to_string(),
                code: l.code.to_string(),
            }),
            aeon_location: location.aeon_location,
            recap_electronic_delivery_location: location.recap_electronic_delivery_location,
            open: location.open,
            requestable: location.requestable,
            always_requestable: location.always_requestable,
            circulates: location.circulates,
            remote_storage: location.remote_storage.clone(),
            fulfillment_unit: location.fulfillment_unit.clone(),
            delivery_locations: location
                .delivery_locations
                .iter()
                .map(|c| c.to_string())
                .collect(),
        }
    }
}

impl LocationRuby {
    fn label(&self) -> String {
        self.label.clone()
    }

    fn code(&self) -> String {
        self.code.clone()
    }
    fn aeon_location(&self) -> bool {
        self.aeon_location
    }
    fn recap_electronic_delivery_location(&self) -> bool {
        self.recap_electronic_delivery_location
    }
    fn open(&self) -> bool {
        self.open
    }
    fn requestable(&self) -> bool {
        self.requestable
    }
    fn always_requestable(&self) -> bool {
        self.always_requestable
    }
    fn circulates(&self) -> bool {
        self.circulates
    }
    fn remote_storage(&self) -> String {
        self.remote_storage.clone()
    }
    fn fulfillment_unit(&self) -> Option<String> {
        self.fulfillment_unit.clone()
    }
    fn library_code(&self) -> String {
        self.library.code.clone()
    }
    fn library_label(&self) -> String {
        self.library.label.clone()
    }
    fn holding_library_label(&self) -> Option<String> {
        self.holding_library.as_ref().map(|l| l.label.clone())
    }
    fn delivery_location_codes(&self) -> Vec<String> {
        self.delivery_locations.clone()
    }

    fn holding_location(code: String) -> Option<Self> {
        HOLDING_LOCATIONS.get(code.as_str()).map(LocationRuby::from)
    }

    fn delivery_location(gfa_pickup: String) -> Option<Self> {
        DELIVERY_LOCATIONS
            .get(gfa_pickup.as_str())
            .map(LocationRuby::from)
    }
}

const HOLDING_LOCATION_JSON: &str =
    include_str!("../../../config/locations/holding_locations.json");

const DELIVERY_LOCATION_JSON: &str =
    include_str!("../../../config/locations/delivery_locations.json");

pub static HOLDING_LOCATIONS: LazyLock<HashMap<&str, Location>> = LazyLock::new(|| {
    let locations: Vec<Location> = serde_json::from_str(HOLDING_LOCATION_JSON)
        .expect("Could not parse the holding_locations.json");
    let mut hash = HashMap::new();
    for location in locations {
        let key = location.code.unwrap_or_default();
        hash.insert(key, location);
    }
    hash
});

pub static DELIVERY_LOCATIONS: LazyLock<HashMap<&str, Location>> = LazyLock::new(|| {
    let locations: Vec<Location> = serde_json::from_str(DELIVERY_LOCATION_JSON)
        .expect("Could not parse the delivery_locations.json");
    let mut hash = HashMap::new();
    for location in locations {
        let key = location.gfa_pickup.unwrap_or_default();
        hash.insert(key, location);
    }
    hash
});

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_get_a_location_label() {
        assert_eq!(
            HOLDING_LOCATIONS.get("engineer$stacks").unwrap().label,
            "Stacks"
        );
    }
    #[test]
    fn it_can_get_if_it_is_aeon_location() {
        assert_eq!(
            HOLDING_LOCATIONS
                .get("engineer$stacks")
                .unwrap()
                .aeon_location,
            false
        );
    }

    #[test]
    fn it_can_get_a_location_code() {
        assert_eq!(
            HOLDING_LOCATIONS.get("engineer$stacks").unwrap().code,
            Some("engineer$stacks")
        );
    }

    #[test]
    fn delivery_locations_have_no_code_but_are_keyed_by_gfa_pickup() {
        let loc = DELIVERY_LOCATIONS
            .get("PQ")
            .expect("PQ should be a delivery location");
        assert_eq!(loc.code, None);
        assert_eq!(loc.gfa_pickup, Some("PQ"));
        assert_eq!(loc.label, "Princeton Plasma Physics Laboratory");
        assert_eq!(loc.library.code, "plasma");
    }

    #[test]
    fn holding_locations_have_no_gfa_pickup() {
        let loc = HOLDING_LOCATIONS
            .get("annex$doc")
            .expect("annex$doc should exist");
        assert_eq!(loc.gfa_pickup, None);
        assert_eq!(loc.code, Some("annex$doc"));
    }
}
