use serde::Deserialize;
use std::{collections::HashMap, sync::LazyLock};
pub mod ruby_bindings;
pub use ruby_bindings::register_ruby_methods;
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

#[magnus::wrap(class = "BibdataRs::Library", free_immediately, size)]
#[derive(Clone)]
pub struct LibraryRuby {
    pub label: String,
}

#[magnus::wrap(class = "BibdataRs::Location", free_immediately, size)]
#[derive(Clone)]
pub struct LocationRuby {
    pub label: String,
    pub code: String,
    pub library: LibraryRuby,
}

impl<'a> From<&Location<'a>> for LocationRuby {
    fn from(location: &Location<'a>) -> Self {
        LocationRuby {
            label: location.label.to_string(),
            code: location.code.to_string(),
            library: LibraryRuby {
                label: location.library.label.to_string(),
            },
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

    fn holding_location(code: String) -> Option<Self> {
        HOLDING_LOCATIONS.get(code.as_str()).map(LocationRuby::from)
    }
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
    fn it_can_get_a_location_code() {
        assert_eq!(
            HOLDING_LOCATIONS.get("engineer$stacks").unwrap().code,
            "engineer$stacks"
        );
    }
}
