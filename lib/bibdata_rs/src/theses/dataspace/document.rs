// This module is responsible for representing Dataspace Document's metadata

use std::collections::HashMap;

use serde::de::Deserializer;
use serde::{Deserialize, Serialize};

mod builder;
mod normalize;

#[derive(Clone, Debug, Default, Serialize)]
pub struct DataspaceDocument {
    pub id: Option<String>,
    pub contributor: Option<Vec<Option<String>>>,
    pub contributor_advisor: Option<Vec<Option<String>>>,
    pub contributor_author: Option<Vec<Option<String>>>,
    pub description_abstract: Option<Vec<Option<String>>>,
    pub format_extent: Option<Vec<Option<String>>>,
    pub identifier_other: Option<Vec<Option<String>>>,
    pub identifier_uri: Option<Vec<Option<String>>>,
    pub title: Option<Vec<Option<String>>>,

    certificate: Option<Vec<Option<String>>>,
    date_classyear: Option<Vec<Option<String>>>,
    department: Option<Vec<Option<String>>>,
    embargo_lift: Option<Vec<Option<String>>>,
    embargo_terms: Option<Vec<Option<String>>>,
    language_iso: Option<Vec<Option<String>>>,
    location: Option<Vec<Option<String>>>,
    mudd_walkin: Option<Vec<Option<String>>>,
    rights_access_rights: Option<Vec<Option<String>>>,
}

#[derive(Clone, Debug, Default, Deserialize)]
pub struct Metadatum {
    pub value: Option<String>,
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
            metadata: HashMap<String, Vec<Metadatum>>
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

    use super::*;

    fn metadatum_vec_from_string(value: &str) -> Vec<Metadatum> {
        vec![Metadatum { value: Some(value.to_string()) }]
    }

    #[test]
    fn it_can_build_a_document() {
        let metadata = DataspaceDocument::builder()
            .with_id("123456")
            .with_embargo_lift(metadatum_vec_from_string("2010-07-01"))
            .with_mudd_walkin(metadatum_vec_from_string("yes"))
            .build();

        assert_eq!(metadata.id.unwrap(), "123456");
        assert_eq!(metadata.embargo_lift.unwrap(), vec![Some("2010-07-01".to_string())]);
        assert_eq!(metadata.mudd_walkin.unwrap(), vec![Some("yes".to_string())]);

    }

    #[test]
    fn it_can_parse_json() {
        let fixture = File::open("../../spec/fixtures/files/theses/api_client_search.json").unwrap();
        let reader = BufReader::new(fixture);
        let documents: Vec<DataspaceDocument> = serde_json::from_reader(reader).unwrap();
        assert_eq!(documents.len(), 1);
        assert_eq!(documents[0].id, Some("dsp01b2773v788".to_owned()));
        assert_eq!(
            documents[0].title,
            Some(vec![Some("Dysfunction: A Play in One Act".to_owned())])
        );
        assert_eq!(
            documents[0].contributor,
            Some(vec![
                Some("Wolff, Tamsen".to_owned()),
                Some("2nd contributor".to_owned())
            ])
        );
        assert_eq!(
            documents[0].contributor_advisor,
            Some(vec![Some("Sandberg, Robert".to_owned())])
        );
        assert_eq!(
            documents[0].contributor_author,
            Some(vec![Some("Clark, Hillary".to_owned())])
        );
        assert_eq!(
            documents[0].identifier_uri,
            Some(vec![
                Some("http://arks.princeton.edu/ark:/88435/dsp01b2773v788".to_owned())
            ])
        );
        assert_eq!(
            documents[0].format_extent,
            Some(vec![Some("102 pages".to_owned())])
        );
        assert_eq!(documents[0].language_iso, Some(vec![Some("en_US".to_owned())]));
        assert_eq!(documents[0].date_classyear, Some(vec![Some("2013".to_owned())]));
        assert_eq!(
            documents[0].department,
            Some(vec![Some("English".to_owned()), Some("NA".to_owned())])
        );
        assert_eq!(
            documents[0].certificate,
            Some(vec![Some("Creative Writing Program".to_owned()), Some("NA".to_owned())])
        );
        assert_eq!(
            documents[0].rights_access_rights,
            Some(vec![Some("Walk-in Access...".to_owned())])
        );
    }

    #[test]
    fn it_can_parse_identifier_other() {
        let json = r#"{"handle":"88435/dsp01b2773v788","metadata":{"dc.identifier.other": [{ "value":"2377" }]}}"#;
        let document: DataspaceDocument = serde_json::from_str(json).unwrap();
        // assert_eq!(documents.len(), 1);
        assert_eq!(document.identifier_other, Some(vec![Some("2377".to_owned())]));
    }

    #[test]
    fn it_can_handle_null_values() {
        let json = r#"{"handle":"88435/dsp01b2773v788","metadata":{"dc.contributor":[{ "value":null}]}}"#;
        let document: DataspaceDocument = serde_json::from_str(json).unwrap();
        // assert_eq!(documents.len(), 1);
        assert!(document.contributor.is_none());
    }
}
