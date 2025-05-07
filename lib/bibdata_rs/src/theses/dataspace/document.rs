// This module is responsible for representing Dataspace Document's metadata

use serde::de::Deserializer;
use serde::{Deserialize, Serialize};

mod builder;
mod normalize;
mod restrictions;

#[derive(Clone, Debug, Serialize)]
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

impl<'de> Deserialize<'de> for DataspaceDocument {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        #[derive(Deserialize)]
        struct KeyValuePair {
            key: String,
            value: Option<String>,
        }

        #[derive(Deserialize)]
        struct RawDocument {
            handle: String,
            metadata: Vec<KeyValuePair>,
        }

        let raw = RawDocument::deserialize(deserializer)?;
        let mut builder = DataspaceDocument::builder();

        builder = builder.with_id(raw.handle.split_once("/").unwrap_or_default().1);

        for entry in raw.metadata {
            if let Some(val) = entry.value {
                match entry.key.as_str() {
                    "dc.contributor" => builder = builder.with_contributor(val),
                    "dc.contributor.advisor" => builder = builder.with_contributor_advisor(val),
                    "dc.contributor.author" => builder = builder.with_contributor_author(val),
                    "dc.format.extent" => builder = builder.with_format_extent(val),
                    "dc.identifier.uri" => builder = builder.with_identifier_uri(val),
                    "dc.language.iso" => builder = builder.with_language_iso(val),
                    "dc.rights.accessRights" => builder = builder.with_rights_access_rights(val),
                    "dc.title" => builder = builder.with_title(val),
                    "pu.certificate" => builder = builder.with_certificate(val),
                    "pu.date.classyear" => builder = builder.with_date_classyear(val),
                    "pu.department" => builder = builder.with_department(val),
                    "pu.location" => builder = builder.with_location(val),
                    "pu.mudd.walkin" => builder = builder.with_mudd_walkin(val),
                    _ => (),
                };
            };
        }
        Ok(builder.build())
    }
}

impl DataspaceDocument {
    pub fn builder() -> builder::DataspaceDocumentBuilder {
        builder::DataspaceDocumentBuilder::new()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_build_a_document() {
        let metadata = DataspaceDocument::builder()
            .with_id("123456")
            .with_embargo_lift("2010-07-01")
            .with_mudd_walkin("yes")
            .build();

        assert_eq!(metadata.id.unwrap(), "123456");
        assert_eq!(metadata.embargo_lift.unwrap(), vec!["2010-07-01"]);
        assert_eq!(metadata.mudd_walkin.unwrap(), vec!["yes"]);
    }

    #[test]
    fn it_can_parse_json() {
        // TODO: put this json in its own file
        let json = r#"[{"id":4350,"name":"Dysfunction: A Play in One Act","handle":"88435/dsp01b2773v788","type":"item","link":"/rest/items/4350",
            "expand":["parentCollection","parentCollectionList","parentCommunityList","bitstreams","all"],"lastModified":"2014-09-09 14:03:06.28",
            "parentCollection":null,"parentCollectionList":null,"parentCommunityList":null,"metadata":[
            {"key":"dc.contributor","value":"Wolff, Tamsen","language":null},{"key":"dc.contributor","value":"2nd contributor","language":null},
            {"key":"dc.contributor.advisor","value":"Sandberg, Robert","language":null},
            {"key":"dc.contributor.author","value":"Clark, Hillary","language":null},{"key":"dc.date.accessioned","value":"2013-07-11T14:31:58Z",
            "language":null},{"key":"dc.date.available","value":"2013-07-11T14:31:58Z","language":null},
            {"key":"dc.date.created","value":"2013-04-02","language":null},{"key":"dc.date.issued","value":"2013-07-11","language":null},
            {"key":"dc.identifier.uri","value":"http://arks.princeton.edu/ark:/88435/dsp01b2773v788","language":null},
            {"key":"dc.format.extent","value":"102 pages","language":"en_US"},{"key":"dc.language.iso","value":"en_US","language":"en_US"},
            {"key":"dc.title","value":"Dysfunction: A Play in One Act","language":"en_US"},
            {"key":"dc.type","value":"Princeton University Senior Theses","language":null},{"key":"pu.date.classyear","value":"2013","language":"en_US"},
            {"key":"pu.department","value":"English","language":"en_US"},{"key":"pu.department","value":"NA","language":"en_US"},
            {"key":"pu.certificate","value":"Creative Writing Program","language":"en_US"},{"key":"pu.certificate","value":"NA","language":"en_US"},
            {"key":"pu.pdf.coverpage","value":"SeniorThesisCoverPage","language":null},{"key":"dc.rights.accessRights","value":"Walk-in Access...","language":null}],
            "bitstreams":null,"archived":"true","withdrawn":"false"}]"#;
        let documents: Vec<DataspaceDocument> = serde_json::from_str(&json).unwrap();
        assert_eq!(documents.len(), 1);
        assert_eq!(documents[0].id, Some("dsp01b2773v788".to_owned()));
        assert_eq!(
            documents[0].title,
            Some(vec!["Dysfunction: A Play in One Act".to_owned()])
        );
        assert_eq!(
            documents[0].contributor,
            Some(vec![
                "Wolff, Tamsen".to_owned(),
                "2nd contributor".to_owned()
            ])
        );
        assert_eq!(
            documents[0].contributor_advisor,
            Some(vec!["Sandberg, Robert".to_owned()])
        );
        assert_eq!(
            documents[0].contributor_author,
            Some(vec!["Clark, Hillary".to_owned()])
        );
        assert_eq!(
            documents[0].identifier_uri,
            Some(vec![
                "http://arks.princeton.edu/ark:/88435/dsp01b2773v788".to_owned()
            ])
        );
        assert_eq!(
            documents[0].format_extent,
            Some(vec!["102 pages".to_owned()])
        );
        assert_eq!(documents[0].language_iso, Some(vec!["en_US".to_owned()]));
        assert_eq!(documents[0].date_classyear, Some(vec!["2013".to_owned()]));
        assert_eq!(
            documents[0].department,
            Some(vec!["English".to_owned(), "NA".to_owned()])
        );
        assert_eq!(
            documents[0].certificate,
            Some(vec!["Creative Writing Program".to_owned(), "NA".to_owned()])
        );
        assert_eq!(
            documents[0].rights_access_rights,
            Some(vec!["Walk-in Access...".to_owned()])
        );
    }

    #[test]
    fn it_can_handle_null_values() {
        let json = r#"[{"handle":"88435/dsp01b2773v788","metadata":[{"key":"dc.contributor", "value":null}]}]"#;
        let documents: Vec<DataspaceDocument> = serde_json::from_str(&json).unwrap();
        assert_eq!(documents.len(), 1);
        assert!(documents[0].contributor.is_none());
    }
}
