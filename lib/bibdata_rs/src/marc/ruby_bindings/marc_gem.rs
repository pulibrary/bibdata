/// This module is responsible for converting Marc data from Ruby's Marc gem to
/// Rust's marctk
use magnus::{
    Object, RArray, RClass, RObject, RString, Ruby,
    value::{InnerRef, Lazy, LazyId, ReprValue},
};
use marctk::{Controlfield, Field, Subfield};
use std::borrow::Cow;

// No need to map fields that we don't use to Marctk
const UNUSED_FIELDS: [&str; 7] = ["902", "904", "911", "947", "952", "979", "999"];

// Define the ruby symbols that we will use in this module
static CODE: LazyId = LazyId::new("@code");
static FIELDS: LazyId = LazyId::new("@fields");
static INDICATOR_1: LazyId = LazyId::new("@indicator1");
static INDICATOR_2: LazyId = LazyId::new("@indicator2");
static LEADER: LazyId = LazyId::new("@leader");
static SUBFIELDS: LazyId = LazyId::new("@subfields");
static TAG: LazyId = LazyId::new("@tag");
static VALUE: LazyId = LazyId::new("@value");

// Define the ruby classes that we will use in this module
static CONTROLFIELD_CLASS: Lazy<RClass> =
    Lazy::new(|ruby| ruby.eval("MARC::ControlField").unwrap());
static DATAFIELD_CLASS: Lazy<RClass> = Lazy::new(|ruby| ruby.eval("MARC::DataField").unwrap());

/// Convert a ruby MARC::Record to a marctk::Record
pub fn marctk_from_ruby_marc_record(
    ruby: &Ruby,
    ruby_marc_record: &RObject,
) -> Result<marctk::Record, magnus::Error> {
    let leader_from_ruby: String =
        ruby_marc_record.ivar_get(LazyId::get_inner_with(&LEADER, ruby))?;
    let fields_from_ruby: RArray =
        ruby_marc_record.ivar_get(LazyId::get_inner_with(&FIELDS, ruby))?;

    let mut marctk_record = marctk::Record::new();
    marctk_record
        .set_leader(normalize_leader(&leader_from_ruby))
        .map_err(|_err| {
            magnus::Error::new(ruby.exception_runtime_error(), "Could not set leader")
        })?;

    fields_from_ruby
        .into_iter()
        .filter_map(RObject::from_value)
        .for_each(|field| {
            if field.is_kind_of(*DATAFIELD_CLASS.get_inner_ref_with(ruby))
                && let Some(data_field) = marctk_data_field_from_ruby_marc(ruby, &field)
            {
                marctk_record.fields_mut().push(data_field);
            } else if field.is_kind_of(*CONTROLFIELD_CLASS.get_inner_ref_with(ruby))
                && let Some(control_field) = marctk_control_field_from_ruby_marc(ruby, &field)
            {
                marctk_record.insert_control_field(control_field);
            }
        });
    Ok(marctk_record)
}

/// Convert a ruby MARC::ControlField to a marctk::Controlfield
fn marctk_control_field_from_ruby_marc(ruby: &Ruby, field: &RObject) -> Option<Controlfield> {
    let tag: String = field.ivar_get(LazyId::get_inner_with(&TAG, ruby)).ok()?;
    let value: String = field.ivar_get(LazyId::get_inner_with(&VALUE, ruby)).ok()?;
    Controlfield::new(tag, value).ok()
}

/// Convert a ruby MARC::DataField to a marctk::Field
pub fn marctk_data_field_from_ruby_marc(ruby: &Ruby, field: &RObject) -> Option<Field> {
    let tag: String = field.ivar_get(LazyId::get_inner_with(&TAG, ruby)).ok()?;
    if UNUSED_FIELDS.contains(&tag.as_str()) {
        return None;
    };
    let ind1: char = field
        .ivar_get(LazyId::get_inner_with(&INDICATOR_1, ruby))
        .unwrap_or(' ');
    let ind2: char = field
        .ivar_get(LazyId::get_inner_with(&INDICATOR_2, ruby))
        .unwrap_or(' ');
    let ruby_subfields: RArray = field
        .ivar_get(LazyId::get_inner_with(&SUBFIELDS, ruby))
        .unwrap_or(ruby.ary_new());

    let mut field = Field::new(tag).ok()?;
    field.set_ind1(ind1).ok()?;
    field.set_ind2(ind2).ok()?;

    let subfields = ruby_subfields
        .into_iter()
        .filter_map(RObject::from_value)
        .filter_map(|object| marctk_subfield_from_ruby_marc(ruby, &object));
    field.subfields_mut().extend(subfields);
    Some(field)
}

/// Convert a ruby MARC::Subfield to a marctk::Subfield
fn marctk_subfield_from_ruby_marc(ruby: &Ruby, subfield: &RObject) -> Option<Subfield> {
    let code: char = subfield
        .ivar_get(LazyId::get_inner_with(&CODE, ruby))
        .ok()?;
    let content: RString = subfield
        .ivar_get(LazyId::get_inner_with(&VALUE, ruby))
        .ok()?;
    Subfield::new(code, content.to_string().ok()?).ok()
}

/// Make sure that the leader is the correct number of chars
fn normalize_leader(original: &str) -> Cow<'_, str> {
    if original.len() < 24 {
        Cow::Owned(original.to_owned() + &" ".repeat(24 - original.len()))
    } else if original.len() > 24 {
        Cow::Owned(original.chars().take(24).collect())
    } else {
        Cow::Borrowed(original)
    }
}

#[cfg(test)]
mod tests {
    use magnus::eval;
    use marctk::Controlfield;
    use rb_sys_test_helpers::ruby_test;

    use super::*;

    #[ruby_test]
    fn it_maps_the_leader() {
        let ruby = unsafe { Ruby::get_unchecked() };
        let ruby_marc_record: RObject = eval!(ruby, "require 'marc';record = MARC::Record.new;record.leader='03968nam a22004693i 4500';record").unwrap();
        let marctk_record = marctk_from_ruby_marc_record(&ruby, &ruby_marc_record).unwrap();
        assert_eq!(marctk_record.leader(), "03968nam a22004693i 4500");
    }

    #[ruby_test]
    fn it_maps_control_fields() {
        let ruby = unsafe { Ruby::get_unchecked() };
        let ruby_marc_record: RObject = eval!(ruby, "require 'marc';record = MARC::Record.new;record.append(MARC::ControlField.new('008','970529s1743 gw 000 0 ger d'));record").unwrap();
        let marctk_record = marctk_from_ruby_marc_record(&ruby, &ruby_marc_record).unwrap();
        assert_eq!(
            marctk_record.get_control_fields("008"),
            vec![&Controlfield::new("008", "970529s1743 gw 000 0 ger d").unwrap()]
        );
    }

    #[ruby_test]
    fn it_maps_data_fields() {
        let ruby = unsafe { Ruby::get_unchecked() };
        let ruby_marc_record: RObject = eval!(ruby, "require 'marc';record = MARC::Record.new;record.append(MARC::DataField.new( '100', '2', '0', ['a', 'Fred']));record").unwrap();
        let marctk_record = marctk_from_ruby_marc_record(&ruby, &ruby_marc_record).unwrap();
        let mut expected_field = Field::new("100").unwrap();
        expected_field.set_ind1("2").unwrap();
        expected_field.set_ind2("0").unwrap();
        expected_field.add_subfield("a", "Fred").unwrap();
        assert_eq!(marctk_record.get_fields("100"), vec![&expected_field]);
    }
}
