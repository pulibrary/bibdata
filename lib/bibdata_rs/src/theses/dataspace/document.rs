// This module is responsible for representing Dataspace Document's metadata

use std::collections::HashMap;

use serde::de::Deserializer;
use serde::{Deserialize, Serialize};

mod builder;
mod normalize;

#[derive(Clone, Debug, Default, Serialize)]
pub struct DataspaceDocument {
    pub id: Option<String>,
    pub contributor: Option<Vec<String>>,
    pub contributor_advisor: Option<Vec<String>>,
    pub contributor_author: Option<Vec<String>>,
    pub description_abstract: Option<Vec<String>>,
    pub format_extent: Option<Vec<String>>,
    pub identifier_other: Option<Vec<String>>,
    pub identifier_uri: Option<Vec<String>>,
    pub title: Option<Vec<String>>,

    certificate: Option<Vec<String>>,
    date_classyear: Option<Vec<String>>,
    department: Option<Vec<String>>,
    embargo_lift: Option<Vec<String>>,
    embargo_terms: Option<Vec<String>>,
    language_iso: Option<Vec<String>>,
    location: Option<Vec<String>>,
    mudd_walkin: Option<Vec<String>>,
    rights_access_rights: Option<Vec<String>>,
}

#[derive(Clone, Debug, Default, Deserialize)]
pub struct Metadatum {
    pub value: Option<String>,
}

impl From<&str> for Metadatum {
    fn from(str: &str) -> Self {
        Metadatum {
            value: Some(str.to_string()),
        }
    }
}

// The lifetime specifier is needed due to how serde deserializes,
// see https://serde.rs/lifetimes.html#understanding-deserializer-lifetimes
impl<'de> Deserialize<'de> for DataspaceDocument {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        #[derive(Deserialize)]
        struct RawDocument {
            handle: String,
            metadata: HashMap<String, Vec<Metadatum>>,
        }

        let raw = RawDocument::deserialize(deserializer)?;
        let mut builder = DataspaceDocument::builder();

        builder = builder.with_id(raw.handle.split_once("/").unwrap_or_default().1);

        for (key, val) in raw.metadata {
            match key.as_str() {
                "dc.contributor" => builder = builder.with_contributor(val),
                "dc.contributor.advisor" => builder = builder.with_contributor_advisor(val),
                "dc.contributor.author" => builder = builder.with_contributor_author(val),
                "dc.description.display" => builder = builder.with_description_abstract(val),
                "dc.format.extent" => builder = builder.with_format_extent(val),
                "dc.identifier.other" => builder = builder.with_identifier_other(val),
                "dc.identifier.uri" => builder = builder.with_identifier_uri(val),
                "dc.language.iso" => builder = builder.with_language_iso(val),
                "dc.rights.accessRights" => builder = builder.with_rights_access_rights(val),
                "dc.title" => builder = builder.with_title(val),
                "pu.certificate" => builder = builder.with_certificate(val),
                "pu.date.classyear" => builder = builder.with_date_classyear(val),
                "pu.department" => builder = builder.with_department(val),
                "pu.embargo.lift" => builder = builder.with_embargo_lift(val),
                "pu.embargo.terms" => builder = builder.with_embargo_terms(val),
                "pu.location" => builder = builder.with_location(val),
                "pu.mudd.walkin" => builder = builder.with_mudd_walkin(val),
                _ => (),
            };
        }
        Ok(builder.build())
    }
}

impl DataspaceDocument {
    pub fn builder() -> builder::DataspaceDocumentBuilder {
        Default::default()
    }
}

#[cfg(test)]
mod tests {
    use std::{fs::File, io::BufReader};

    use crate::theses::dataspace::collection::SearchResponse;

    use super::*;

    fn metadatum_vec_from_string(value: &str) -> Vec<Metadatum> {
        vec![Metadatum {
            value: Some(value.to_string()),
        }]
    }

    #[test]
    fn it_can_build_a_document() {
        let metadata = DataspaceDocument::builder()
            .with_id("123456")
            .with_embargo_lift(metadatum_vec_from_string("2010-07-01"))
            .with_mudd_walkin(metadatum_vec_from_string("yes"))
            .build();

        assert_eq!(metadata.id, Some("123456".to_string()));
        assert_eq!(metadata.embargo_lift, Some(vec!["2010-07-01".to_string()]));
        assert_eq!(metadata.embargo_lift, Some(vec!["2010-07-01".to_string()]));
        assert_eq!(metadata.mudd_walkin, Some(vec!["yes".to_string()]));
    }

    #[test]
    fn it_can_parse_json() {
        let fixture =
            File::open("../../spec/fixtures/files/theses/api_client_search.json").unwrap();
        let reader = BufReader::new(fixture);
        let response: SearchResponse = serde_json::from_reader(reader).unwrap();
        let documents = response._embedded.search_result._embedded.objects;
        let document = documents[0]._embedded.indexable_object.clone();
        assert_eq!(documents.len(), 20);
        assert_eq!(document.id, Some("dsp01s1784q17j".to_owned()));
        assert_eq!(
            document.title,
            Some(vec!["Charging Ahead, Left Behind?\nBalancing Local Labor Market Trade-Offs of Recent U.S. Power Plant Retirements and Renewable Energy Expansion".to_owned()])
        );
        assert_eq!(
            document.contributor_advisor,
            Some(vec!["Reichman, Nancy".to_owned()])
        );
        assert_eq!(
            document.contributor_author,
            Some(vec!["Brunnermeier, Anjali".to_owned()])
        );
        assert_eq!(
            document.identifier_uri,
            Some(vec![
                "https://theses-dissertations.princeton.edu/handle/88435/dsp01s1784q17j".to_owned()
            ])
        );
        assert_eq!(document.language_iso, Some(vec!["en_US".to_owned()]));
        assert_eq!(document.date_classyear, Some(vec!["2025".to_owned()]));
        assert_eq!(
            document.department,
            Some(vec!["Economics".to_owned(), "NA".to_owned()])
        );
        assert_eq!(
            document.certificate,
            Some(vec!["Creative Writing Program".to_owned(), "NA".to_owned()])
        );
        assert_eq!(
            document.rights_access_rights,
            Some(vec!["Walk-in Access...".to_owned()])
        );
    }

    #[test]
    fn it_can_parse_identifier_other() {
        let json = r#"[{"handle":"88435/dsp01b2773v788","metadata":{"dc.identifier.other":[{ "value":"2377", "test":"test string" }]}}]"#;
        let documents: Vec<DataspaceDocument> = serde_json::from_str(json).unwrap();
        assert_eq!(documents.len(), 1);
        assert_eq!(documents[0].id, Some("dsp01b2773v788".to_owned()));
        assert_eq!(documents[0].identifier_other, Some(vec!["2377".to_owned()]));
    }

    #[test]
    fn it_can_handle_null_values() {
        let json = r#"[{"handle":"88435/dsp01b2773v788","metadata":{"dc.contributor":[{ "value":null }]}}]"#;
        let documents: Vec<DataspaceDocument> = serde_json::from_str(json).unwrap();
        assert_eq!(documents.len(), 1);
        assert_eq!(documents[0].contributor, Some(vec!("".to_string())));
    }
}
