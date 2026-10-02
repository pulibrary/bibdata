//! This module handles fields whose only purpose is to improve search

use crate::marc::variable_length_field::extract_marc;
use marctk::Record;

/// An assortment of all kinds of search terms with low weights, they will
/// go into the solr `text` field
pub fn general_search_terms(record: &Record) -> Vec<String> {
    extract_marc!("024a")(record)
}
