use serde::{Deserialize, Serialize};

use super::{
    access_facet::AccessFacet, ElectronicAccess, FormatFacet, LibraryFacet, SolrDocumentBuilder,
};

#[derive(Debug, Default, Deserialize, Serialize)]
pub struct SolrDocument {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub advanced_location_s: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub access_facet: Option<AccessFacet>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub advisor_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub author_citation_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub author_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub author_roles_1display: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub author_s: Option<Vec<String>>,

    pub author_sort: Option<String>,

    pub call_number_browse_s: String,

    pub call_number_display: String,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub certificate_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub class_year_s: Option<Vec<i16>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub contributor_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub department_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub description_display: Option<Vec<String>>,

    pub electronic_access_1display: Option<ElectronicAccess>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub electronic_portfolio_s: Option<String>,

    pub format: Option<Vec<FormatFacet>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub geographic_facet: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub holdings_1display: Option<String>,

    pub homoit_subject_display: Option<Vec<String>>,

    pub homoit_subject_facet: Option<Vec<String>>,

    pub id: String,

    pub language_facet: Vec<String>,

    pub language_name_display: Vec<String>,

    pub lc_subject_display: Option<Vec<String>>,

    pub lc_subject_facet: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub location: Option<LibraryFacet>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub location_display: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub location_code_s: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub notes_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub other_title_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub provenance_display: Option<String>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub pub_citation_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub pub_created_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub pub_date_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub pub_date_end_sort: Option<i16>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub pub_date_start_sort: Option<i16>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub publisher_citation_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub publisher_no_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub restrictions_display_text: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub restrictions_note_display: Option<Vec<String>>,

    #[serde(skip_serializing_if = "Option::is_none")]
    pub summary_note_display: Option<Vec<String>>,

    pub title_citation_display: Option<String>,

    pub title_display: Option<String>,

    pub title_sort: Option<String>,

    pub title_t: Option<Vec<String>>,
}

impl SolrDocument {
    pub fn builder() -> SolrDocumentBuilder {
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
    }

    #[test]
    fn test_build_a_solr_document_with_location() {
        let document = SolrDocument::builder()
            .with_location(Some(LibraryFacet::Mudd))
            .build();
        assert_eq!(document.location.unwrap(), LibraryFacet::Mudd);
    }

    #[test]
    fn it_can_serialize_an_electronic_access() {
        let document = SolrDocument::builder()
            .with_electronic_access_1display(Some(ElectronicAccess {
                url: "http://arks.princeton.edu/ark:/88435/dsp01b2773v788".to_owned(),
                link_text: "DataSpace".to_owned(),
                link_description: Some("Full text".to_owned()),
                iiif_manifest_paths: None,
                digital_content: None,
            }))
            .build();
        let serialized = serde_json::to_string(&document).unwrap();
        assert!(serialized.contains(
            r#""electronic_access_1display":"{\"http://arks.princeton.edu/ark:/88435/dsp01b2773v788\":[\"DataSpace\",\"Full text\"]}""#
        ))
    }
}
