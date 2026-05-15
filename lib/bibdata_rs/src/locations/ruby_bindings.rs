use crate::locations::LocationRuby;
use magnus::{RModule, Ruby, function, method, prelude::*};

pub fn register_ruby_methods(ruby: &Ruby, parent_module: &RModule) -> Result<(), magnus::Error> {
    let class = parent_module.define_class("Location", ruby.class_object())?;
    class.define_method("label", method!(LocationRuby::label, 0))?;
    class.define_method("code", method!(LocationRuby::code, 0))?;
    class.define_singleton_method(
        "holding_location",
        function!(LocationRuby::holding_location, 1),
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
}
