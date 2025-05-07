use ephemera::ephemera_item;
use magnus::{function, prelude::*, Error, Ruby};

mod config;
mod ephemera;
mod testing_support;
mod theses;

#[magnus::init]
fn init(ruby: &Ruby) -> Result<(), Error> {
    let module = ruby.define_module("BibdataRs")?;
    let submodule = module.define_module("Theses")?;
    let submodule_ephemera = submodule.define_module("Ephemera")?;
    submodule.define_singleton_method("json_document", function!(theses::json_document, 1))?;
    submodule_ephemera.define_singleton_method(
        "json_document",
        function!(ephemera_item::json_ephemera_document, 1),
    )?;
    submodule.define_singleton_method("map_program", function!(theses::map_program, 1))?;
    submodule.define_singleton_method("map_department", function!(theses::map_department, 1))?;
    submodule.define_singleton_method("normalize_latex", function!(theses::normalize_latex, 1))?;
    Ok(())
}
