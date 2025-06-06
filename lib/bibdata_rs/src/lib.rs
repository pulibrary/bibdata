use ephemera::ephemera_folder_item;
use magnus::{function, prelude::*, Error, Ruby};
use solr::index;
use theses::dataspace::collection;

mod ephemera;
pub mod solr;
pub mod theses;

fn is_literary(xml: String) -> bool {
    let record = marctk::Record::from_xml(&xml).next().unwrap().unwrap();
    record.get_control_fields("008").iter().any(|field| match field.content().chars().nth(33) {
        Some(litf) if ['1', 'd', 'e', 'f', 'j', 'p'].contains(&litf)  => true,
        _ => false
    })
}

#[cfg(test)]
mod testing_support;

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("BibdataRs")?;
    module.define_singleton_method("literary_work?", function!(is_literary, 1))?;
    let submodule_theses = module.define_module("Theses")?;
    let submodule_ephemera = module.define_module("Ephemera")?;
    submodule_ephemera.define_singleton_method(
        "json_ephemera_document",
        function!(ephemera_folder_item::json_ephemera_document, 1),
    )?;
    submodule_ephemera
        .define_singleton_method("index_string", function!(index::index_string, 3))?;
    submodule_theses.define_singleton_method(
        "all_documents_as_solr",
        function!(collection::collections_as_solr, 3),
    )?;
    Ok(())
}
