// This module is responsible for describing the metadata in a catalog solr document
use serde::Serialize;

mod builder;
mod dataspace_solr_mapping;
mod ephemera_solr_mapping;
mod index;

#[derive(Debug, Default, Serialize)]
pub struct SolrDocument {
    #[serde(skip_serializing_if = "Option::is_none")]
    advanced_location_s: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    access_facet: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    advisor_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    author_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    author_s: Option<Vec<String>>,

    author_sort: Option<String>,

    call_number_browse_s: String,

    call_number_display: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    certificate_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    class_year_s: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    contributor_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    department_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    description_display: Option<Vec<String>>,

    electronic_access_1display: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    electronic_portfolio_s: Option<String>,

    format: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub holdings_1display: Option<String>,

    id: String,

    language_facet: Vec<String>,

    language_name_display: Vec<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    location: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    location_display: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    location_code_s: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    other_title_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub_date_end_sort: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub_date_start_sort: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    restrictions_display_text: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    restrictions_note_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    summary_note_display: Option<Vec<String>>,

    title_citation_display: Option<String>,

    title_display: Option<String>,

    title_sort: Option<String>,

    title_t: Option<Vec<String>>,
}

impl SolrDocument {
    pub fn builder() -> builder::SolrDocumentBuilder {
        Default::default()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_build_an_empty_solr_document() {
        let document = SolrDocument::builder().build();
        assert_eq!(document.location, None);
        assert_eq!(document.format, "Senior thesis");
    }

    #[test]
    fn test_build_a_solr_document_with_location() {
        let document = SolrDocument::builder()
            .with_location(Some("Mudd Manuscript Library".to_owned()))
            .build();
        assert_eq!(document.location.unwrap(), "Mudd Manuscript Library");
    }
}
