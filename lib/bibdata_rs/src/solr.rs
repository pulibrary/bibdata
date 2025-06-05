pub mod index;
pub mod solr_document;

mod access_facet;
mod builder;
mod dataspace_solr_mapping;
mod ephemera_solr_mapping;
mod format_facet;

pub use access_facet::AccessFacet;
pub use builder::SolrDocumentBuilder;
pub use format_facet::FormatFacet;
pub use solr_document::SolrDocument;
