mod builder;
mod dataspace_solr_mapping;
mod ephemera_solr_mapping;
mod format;
pub mod index;
pub mod solr_document;

pub use builder::SolrDocumentBuilder;
pub use format::Format;
pub use solr_document::SolrDocument;
