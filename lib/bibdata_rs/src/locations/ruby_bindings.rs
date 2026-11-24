use crate::locations::LocationRuby;
use magnus::{RModule, Ruby, function, method, prelude::*};

pub fn register_ruby_methods(ruby: &Ruby, parent_module: &RModule) -> Result<(), magnus::Error> {
    let class = parent_module.define_class("Location", ruby.class_object())?;
    class.define_method("label", method!(LocationRuby::label, 0))?;
    class.define_method("id", method!(LocationRuby::id, 0))?;
    class.define_method("code", method!(LocationRuby::code, 0))?;
    class.define_method("aeon_location", method!(LocationRuby::aeon_location, 0))?;
    class.define_method(
        "recap_electronic_delivery_location",
        method!(LocationRuby::recap_electronic_delivery_location, 0),
    )?;
    class.define_method("open", method!(LocationRuby::open, 0))?;
    class.define_method("requestable", method!(LocationRuby::requestable, 0))?;
    class.define_method(
        "always_requestable",
        method!(LocationRuby::always_requestable, 0),
    )?;
    class.define_method("circulates", method!(LocationRuby::circulates, 0))?;
    class.define_method("remote_storage", method!(LocationRuby::remote_storage, 0))?;
    class.define_method(
        "fulfillment_unit",
        method!(LocationRuby::fulfillment_unit, 0),
    )?;
    class.define_method("library_code", method!(LocationRuby::library_code, 0))?;
    class.define_method("library_label", method!(LocationRuby::library_label, 0))?;
    class.define_method(
        "holding_library_label",
        method!(LocationRuby::holding_library_label, 0),
    )?;
    class.define_method(
        "delivery_location_codes",
        method!(LocationRuby::delivery_location_codes, 0),
    )?;
    class.define_singleton_method(
        "holding_location",
        function!(LocationRuby::holding_location, 1),
    )?;
    class.define_singleton_method(
        "delivery_location",
        function!(LocationRuby::delivery_location, 1),
    )?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_get_a_location_label() {
        assert_eq!(
            LocationRuby::holding_location("engineer$stacks".to_owned())
                .unwrap()
                .label(),
            "Stacks"
        );
    }

    #[test]
    fn it_can_get_a_location_code() {
        assert_eq!(
            LocationRuby::holding_location("engineer$stacks".to_owned())
                .unwrap()
                .code(),
            "engineer$stacks"
        );
    }

    #[test]
    fn it_can_get_a_library_code() {
        assert_eq!(
            LocationRuby::holding_location("annex$doc".to_owned())
                .unwrap()
                .library_code(),
            "annex"
        );
    }

    #[test]
    fn it_can_get_a_library_label() {
        assert_eq!(
            LocationRuby::holding_location("annex$doc".to_owned())
                .unwrap()
                .library_label(),
            "Forrestal Annex"
        );
    }

    #[test]
    fn it_can_get_delivery_gfa_pickup_location_codes() {
        let codes = LocationRuby::holding_location("annex$doc".to_owned())
            .unwrap()
            .delivery_location_codes();
        assert_eq!(
            codes,
            vec![
                "QT".to_string(),
                "QA".to_string(),
                "PA".to_string(),
                "QC".to_string()
            ]
        );
    }

    #[test]
    fn it_returns_correct_delivery_location_gfa_pickup_codes_for_annex_locked() {
        let codes = LocationRuby::holding_location("annex$locked".to_owned())
            .unwrap()
            .delivery_location_codes();
        assert_eq!(
            codes,
            vec!["QT".to_string(), "QA".to_string(), "QC".to_string()]
        );
    }

    #[test]
    fn it_can_resolve_a_delivery_location_by_gfa_pickup_code() {
        assert!(LocationRuby::delivery_location("QT".to_owned()).is_some());
    }

    #[test]
    fn it_returns_none_for_unknown_delivery_location() {
        assert!(LocationRuby::delivery_location("ZZZ".to_owned()).is_none());
    }

    #[test]
    fn it_returns_none_for_unknown_holding_location() {
        assert!(LocationRuby::holding_location("ZZZ$nope".to_owned()).is_none());
    }

    #[test]
    fn it_exposes_every_field_for_a_holding_location() {
        let loc = LocationRuby::holding_location("annex$doc".to_owned()).unwrap();
        assert_eq!(
            loc.label(),
            "Documents Off-Site Storage; contact docstor@Princeton.edu"
        );
        assert_eq!(loc.code(), "annex$doc");
        assert_eq!(loc.library_label(), "Forrestal Annex");
        assert_eq!(loc.library_code(), "annex");
        assert_eq!(loc.holding_library_label(), None);
        assert!(!loc.aeon_location());
        assert!(!loc.recap_electronic_delivery_location());
        assert!(!loc.open());
        assert!(loc.requestable());
        assert!(!loc.always_requestable());
        assert!(loc.circulates());
        assert_eq!(loc.remote_storage(), "");
        assert_eq!(loc.fulfillment_unit(), Some("Closed".to_string()));
        assert_eq!(
            loc.delivery_location_codes(),
            vec![
                "QT".to_string(),
                "QA".to_string(),
                "PA".to_string(),
                "QC".to_string()
            ]
        );
    }

    #[test]
    fn it_exposes_holding_library_and_remote_storage() {
        let loc = LocationRuby::holding_location("arch$pw".to_owned()).unwrap();
        assert_eq!(
            loc.holding_library_label(),
            Some("Architecture Library".to_string())
        );
        assert_eq!(loc.library_code(), "arch");

        assert_eq!(loc.remote_storage(), "recap_rmt");
    }

    #[test]
    fn it_shows_aeon_and_non_circulating_branches() {
        let loc = LocationRuby::holding_location("marquand$fbx".to_owned()).unwrap();
        assert!(loc.aeon_location());
        assert!(loc.always_requestable());
        assert!(!loc.circulates());
        assert!(loc.delivery_location_codes().is_empty());
        assert_eq!(loc.fulfillment_unit(), Some("Closed".to_string()));
    }

    #[test]
    fn it_shows_non_requestable_and_non_circulating() {
        let loc = LocationRuby::holding_location("arch$res3hr".to_owned()).unwrap();
        assert!(!loc.requestable());
        assert!(!loc.circulates());
        assert_eq!(loc.fulfillment_unit(), Some("Reserves".to_string()));
        assert_eq!(loc.delivery_location_codes(), vec!["PW".to_string()]);
    }

    #[test]
    fn it_uses_gfa_pickup_as_code_for_delivery_locations() {
        let loc = LocationRuby::delivery_location("PQ".to_owned()).unwrap();
        assert_eq!(loc.code(), "PQ");
        assert_eq!(loc.label(), "Princeton Plasma Physics Laboratory");
        assert_eq!(loc.library_code(), "plasma");
        assert_eq!(
            loc.library_label(),
            "Harold P. Furth Plasma Physics Library"
        );
    }

    #[test]
    fn it_exposes_delivery_location_id() {
        let loc = LocationRuby::delivery_location("PQ".to_owned()).unwrap();
        assert_eq!(loc.id(), Some(1));
    }

    #[test]
    fn holding_locations_have_no_id() {
        let loc = LocationRuby::holding_location("annex$doc".to_owned()).unwrap();
        assert_eq!(loc.id(), None);
    }
}
