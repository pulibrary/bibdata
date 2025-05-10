extern crate serde;

use crate::theses::{embargo, holdings, language, latex, solr};
use itertools::Itertools;
use serde::{Deserialize, Serialize};
use serde::de::Deserializer;

// This is an intermediate representation of the data from dspace, representing the key value pairs taken from
// DSpace API metadata
#[derive(Debug, Serialize)]
pub struct DataspaceDocument {
    id: Option<String>,
    certificate: Option<Vec<String>>,
    contributor: Option<Vec<String>>,
    contributor_advisor: Option<Vec<String>>,
    contributor_author: Option<Vec<String>>,
    date_classyear: Option<Vec<String>>,
    description_abstract: Option<Vec<String>>,
    department: Option<Vec<String>>,
    embargo_lift: Option<Vec<String>>,
    embargo_terms: Option<Vec<String>>,
    format_extent: Option<Vec<String>>,
    identifier_other: Option<Vec<String>>,
    identifier_uri: Option<Vec<String>>,
    language_iso: Option<Vec<String>>,
    location: Option<Vec<String>>,
    mudd_walkin: Option<Vec<String>>,
    rights_access_rights: Option<Vec<String>>,
    title: Option<Vec<String>>,
}

impl<'de> Deserialize<'de> for DataspaceDocument {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        #[derive(Deserialize)]
        struct KeyValuePair {
            key: String,
            value: String,
        }

        #[derive(Deserialize)]
        struct RawDocument {
            handle: String,
            metadata: Vec<KeyValuePair>,
        }

        let raw = RawDocument::deserialize(deserializer)?;
        let mut builder = DataspaceDocument::builder();

        builder = builder.with_id(Some(raw.handle.split_once("/").unwrap_or_default().1.to_owned()));

        for entry in raw.metadata {
            match entry.key.as_str() {
                "dc.contributor" => builder = builder.with_contributor(entry.value),
                "dc.contributor.advisor" => builder = builder.with_contributor_advisor(entry.value),
                "dc.contributor.author" => builder = builder.with_contributor_author(entry.value),
                "dc.format.extent" => builder = builder.with_format_extent(entry.value),
                "dc.identifier.uri" => builder = builder.with_identifier_uri(entry.value),
                "dc.language.iso" => builder = builder.with_language_iso(entry.value),
                "dc.rights.accessRights" => builder = builder.with_rights_access_rights(entry.value),
                "dc.title" => builder = builder.with_title(entry.value),
                "pu.certificate" => builder = builder.with_certificate(entry.value),
                "pu.date.classyear" => builder = builder.with_date_classyear(entry.value),
                "pu.department" => builder = builder.with_department(entry.value),
                "pu.location" => builder = builder.with_location(entry.value),
                "pu.mudd.walkin" => builder = builder.with_mudd_walkin(entry.value),
                _ => (),
            };
        }
        Ok(builder.build())
    }
}

impl DataspaceDocument {
    pub fn builder() -> DataspaceDocumentBuilder {
        DataspaceDocumentBuilder::new()
    }
}

#[derive(Default)]
pub struct DataspaceDocumentBuilder {
    id: Option<String>,
    certificate: Option<Vec<String>>,
    contributor: Option<Vec<String>>,
    contributor_advisor: Option<Vec<String>>,
    contributor_author: Option<Vec<String>>,
    date_classyear: Option<Vec<String>>,
    description_abstract: Option<Vec<String>>,
    department: Option<Vec<String>>,
    embargo_lift: Option<Vec<String>>,
    embargo_terms: Option<Vec<String>>,
    format_extent: Option<Vec<String>>,
    identifier_other: Option<Vec<String>>,
    identifier_uri: Option<Vec<String>>,
    language_iso: Option<Vec<String>>,
    location: Option<Vec<String>>,
    mudd_walkin: Option<Vec<String>>,
    rights_access_rights: Option<Vec<String>>,
    title: Option<Vec<String>>,
}

impl DataspaceDocumentBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn with_id(mut self, id: Option<String>) -> Self {
        self.id = id;
        self
    }

    pub fn with_certificate(mut self, certificate: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.certificate {
            vec.push(certificate.into())
        } else {
            self.certificate = Some(vec![certificate.into()]);
        };
        self
    }

    pub fn with_contributor(mut self, contributor: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.contributor {
            vec.push(contributor.into())
        } else {
            self.contributor = Some(vec![contributor.into()]);
        };
        self
    }

    pub fn with_contributor_advisor(mut self, contributor_advisor: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.contributor_advisor {
            vec.push(contributor_advisor.into())
        } else {
            self.contributor_advisor = Some(vec![contributor_advisor.into()]);
        };
        self
    }

    pub fn with_contributor_author(mut self, contributor_author: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.contributor_author {
            vec.push(contributor_author.into())
        } else {
            self.contributor_author = Some(vec![contributor_author.into()]);
        };
        self
    }

    pub fn with_date_classyear(mut self, date_classyear: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.date_classyear {
            vec.push(date_classyear.into())
        } else {
            self.date_classyear = Some(vec![date_classyear.into()]);
        };
        self
    }

    pub fn with_description_abstract(mut self, description_abstract: Option<Vec<String>>) -> Self {
        self.description_abstract = description_abstract;
        self
    }

    pub fn with_department(mut self, department: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.department {
            vec.push(department.into())
        } else {
            self.department = Some(vec![department.into()]);
        };
        self
    }

    pub fn with_embargo_lift(mut self, embargo_lift: Option<Vec<String>>) -> Self {
        self.embargo_lift = embargo_lift;
        self
    }

    pub fn with_embargo_terms(mut self, embargo_terms: Option<Vec<String>>) -> Self {
        self.embargo_terms = embargo_terms;
        self
    }

    pub fn with_format_extent(mut self, format_extent: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.format_extent {
            vec.push(format_extent.into())
        } else {
            self.format_extent = Some(vec![format_extent.into()]);
        };
        self
    }

    pub fn with_identifier_uri(mut self, identifier_uri: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.identifier_uri {
            vec.push(identifier_uri.into())
        } else {
            self.identifier_uri = Some(vec![identifier_uri.into()]);
        };
        self
    }

    pub fn with_language_iso(mut self, language_iso: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.language_iso {
            vec.push(language_iso.into())
        } else {
            self.language_iso = Some(vec![language_iso.into()]);
        };
        self
    }

    pub fn with_location(mut self, location: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.location {
            vec.push(location.into())
        } else {
            self.location = Some(vec![location.into()]);
        };
        self
    }

    pub fn with_mudd_walkin(mut self, mudd_walkin: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.mudd_walkin {
            vec.push(mudd_walkin.into())
        } else {
            self.mudd_walkin = Some(vec![mudd_walkin.into()]);
        };
        self
    }

    pub fn with_rights_access_rights(mut self, rights_access_rights: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.rights_access_rights {
            vec.push(rights_access_rights.into())
        } else {
            self.rights_access_rights = Some(vec![rights_access_rights.into()]);
        };
        self
    }

    pub fn with_title(mut self, title: String) -> Self {
        if let Some(ref mut vec) = self.title {
            vec.push(title)
        } else {
            self.title = Some(vec![title]);
        };
        self
    }

    pub fn build(self) -> DataspaceDocument {
        DataspaceDocument {
            id: self.id,
            certificate: self.certificate,
            contributor: self.contributor,
            contributor_advisor: self.contributor_advisor,
            contributor_author: self.contributor_author,
            date_classyear: self.date_classyear,
            description_abstract: self.description_abstract,
            department: self.department,
            embargo_lift: self.embargo_lift,
            embargo_terms: self.embargo_terms,
            format_extent: self.format_extent,
            identifier_other: self.identifier_other,
            identifier_uri: self.identifier_uri,
            language_iso: self.language_iso,
            location: self.location,
            mudd_walkin: self.mudd_walkin,
            rights_access_rights: self.rights_access_rights,
            title: self.title,
        }
    }
}

/// Take first title, strip out latex expressions when present to include along
/// with non-normalized version (allowing users to get matches both when LaTex
/// is pasted directly into the search box and when sub/superscripts are placed
/// adjacent to regular characters
fn title_search_versions(possible_titles: &Option<Vec<String>>) -> Option<Vec<String>> {
    match possible_titles {
        Some(titles) => {
            titles.first().map(|title| vec![title.to_string(), latex::normalize_latex(title.to_string())]
                        .into_iter()
                        .unique()
                        .collect())
        }
        None => None,
    }
}


impl DataspaceDocument {
    pub fn ark_hash(&self) -> Option<String> {
        holdings::ark_hash(
            self.identifier_uri.clone(),
            self.location.is_some(),
            self.rights_access_rights.is_some(),
            self.mudd_walkin.clone(),
            self.date_classyear.clone()?,
            self.embargo_lift.clone(),
            self.embargo_terms.clone(),
        )
    }

    pub fn call_number(&self) -> String {
        holdings::call_number(self.identifier_other.clone())
    }
    pub fn languages(&self) -> Vec<String> {
        language::codes_to_english_names(self.language_iso.clone())
    }

    pub fn class_year(&self) -> Option<Vec<String>> {
        let years = self.date_classyear.clone().unwrap_or_default();
        let year = years.first()?;
        if year.chars().all(|c| c.is_numeric()) {
            Some(vec![year.to_string()])
        } else {
            None
        }
    }

    pub fn all_authors(&self) -> Vec<String> {
        let mut authors = self.contributor_author.clone().unwrap_or_default().clone();
        authors.extend(self.contributor_advisor.clone().unwrap_or_default());
        authors.extend(self.contributor.clone().unwrap_or_default());
        authors.extend(self.department.clone().unwrap_or_default());
        authors.extend(self.certificate.clone().unwrap_or_default());
        authors
    }

    pub fn location(&self) -> Option<String> {
        if self.has_current_embargo() || self.on_site_only() {
            Some("Mudd Manuscript Library".to_owned())
        } else {
            None
        }
    }

    pub fn location_code(&self) -> Option<String> {
        if self.has_current_embargo() || self.on_site_only() {
            Some("mudd$stacks".to_owned())
        } else {
            None
        }
    }

    pub fn advanced_location(&self) -> Option<Vec<String>> {
        if self.has_current_embargo() || self.on_site_only() {
            Some(vec![
                "mudd$stacks".to_owned(),
                "Mudd Manuscript Library".to_owned(),
            ])
        } else {
            None
        }
    }

    pub fn access_facet(&self) -> Option<String> {
        if self.has_current_embargo() {
            None
        } else if self.on_site_only() {
            Some("In the Library".to_owned())
        } else {
            Some("Online".to_owned())
        }
    }

    fn has_current_embargo(&self) -> bool {
        embargo::has_current_embargo(self.embargo_lift.clone(), self.embargo_terms.clone())
    }

    fn on_site_only(&self) -> bool {
        holdings::on_site_only(
            self.location.is_some(),
            self.rights_access_rights.is_some(),
            self.mudd_walkin.clone(),
            self.date_classyear.clone().unwrap_or_default(),
            self.embargo_lift.clone(),
            self.embargo_terms.clone(),
        )
    }
}

impl From<DataspaceDocument> for solr::SolrDocument {
    fn from(value: DataspaceDocument) -> Self {
        let binding = value.title.clone().unwrap_or_default();
        let first_title = binding.first();
        solr::SolrDocument::builder()
            .with_id(value.id.clone().unwrap_or_default())
            .with_access_facet(value.access_facet())
            .with_advanced_location_s(value.advanced_location())
            .with_advisor_display(value.contributor_advisor.clone())
            .with_author_display(value.contributor_author.clone())
            .with_author_s(value.all_authors())
            .with_author_sort(&value.contributor_author.clone().unwrap_or_default().first())
            .with_call_number_browse_s(value.call_number())
            .with_call_number_display(value.call_number())
            .with_certificate_display(value.certificate.clone())
            .with_contributor_display(value.contributor.clone())
            .with_department_display(value.department.clone())
            .with_holdings_1display(holdings::physical_holding_string(value.identifier_uri.clone()))
            .with_location(value.location())
            .with_location_code_s(value.location_code())
            .with_location_display(value.location())
            .with_electronic_access_1display(&value.ark_hash())
            .with_electronic_portfolio_s(holdings::online_holding_string(value.identifier_other.clone()))
            .with_title_citation_display(&first_title)
            .with_title_display(&first_title)
            .with_title_sort(&title_sort(&value.title))
            .with_title_t(&title_search_versions(&value.title))
            .with_language_facet(value.languages())
            .with_language_name_display(value.languages())
            .with_class_year_s(&value.class_year())
            .with_pub_date_start_sort(&value.class_year())
            .with_pub_date_end_sort(&value.class_year())
            .with_description_display(value.format_extent)
            .with_summary_note_display(value.description_abstract)
            .build()
    }
}

fn title_sort(titles: &Option<Vec<String>>) -> Option<String> {
    match titles {
        Some(title_vec) => {
            let first = title_vec.first()?;
            Some(
                first
                    .to_lowercase()
                    .chars()
                    .filter(|c| !c.is_ascii_punctuation())
                    .collect::<String>()
                    .trim_start_matches("a ")
                    .trim_start_matches("an ")
                    .trim_start_matches("the ")
                    .chars()
                    .filter(|c| !c.is_whitespace())
                    .collect::<String>()
            )
        }
        None => None,
    }
}

pub fn ruby_json_to_solr_json(ruby: String) -> String {
    let metadata: DataspaceDocument = serde_json::from_str(&ruby).unwrap();
    serde_json::to_string(&solr::SolrDocument::from(metadata)).unwrap()
}

// DELETE ME: just a temporary function for testing in Ruby
pub fn parse_dspace_api_json(api: String) -> String {
    let documents: Vec<DataspaceDocument> = serde_json::from_str(&api).unwrap();
    serde_json::to_string(&documents).unwrap()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_build_a_document() {
        let metadata = DataspaceDocument::builder()
            .with_id(Some("123456".to_string()))
            .with_embargo_lift(Some(vec!["2010-07-01".to_string()]))
            .with_mudd_walkin("yes")
            .build();

        assert_eq!(metadata.id.unwrap(), "123456");
        assert_eq!(metadata.embargo_lift.unwrap(), vec!["2010-07-01"]);
        assert_eq!(metadata.mudd_walkin.unwrap(), vec!["yes"]);
    }

    #[test]
    fn it_can_convert_into_solr_document() {
        let metadata = DataspaceDocument::builder()
            .with_id(Some("dsp01b2773v788".to_string()))
            .with_description_abstract(Some(vec!["Summary".to_string()]))
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_format_extent("102 pages")
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act".to_string())
            .build();

        let solr = solr::SolrDocument::from(metadata);

        assert_eq!(solr.id, "dsp01b2773v788");
        assert_eq!(solr.title_t.unwrap(), vec!["Dysfunction: A Play in One Act"]);
        assert_eq!(solr.title_citation_display.unwrap(), "Dysfunction: A Play in One Act");
        assert_eq!(solr.title_display.unwrap(), "Dysfunction: A Play in One Act");
        assert_eq!(solr.title_sort.unwrap(), "dysfunctionaplayinoneact");
    }

    #[test]
    fn ark_hash_gets_the_ark_with_fulltext_link_display_when_restrictions() {
        let metadata = DataspaceDocument::builder()
            .with_id(Some("dsp01b2773v788".to_string()))
            .with_description_abstract(Some(vec!["Summary".to_string()]))
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_identifier_uri("http://arks.princeton.edu/ark:/88435/dsp01b2773v788")
            .with_format_extent("102 pages")
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act".to_string())
            .build();

        assert_eq!(
            metadata.ark_hash().unwrap(),
            r#"{"http://arks.princeton.edu/ark:/88435/dsp01b2773v788":["DataSpace","Full text"]}"#
        );
    }

    #[test]
    fn ark_hash_gets_the_ark_with_fulltext_link_display_when_no_restrictions() {
        let metadata = DataspaceDocument::builder()
            .with_id(Some("dsp01b2773v788".to_string()))
            .with_description_abstract(Some(vec!["Summary".to_string()]))
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_identifier_uri("http://arks.princeton.edu/ark:/88435/dsp01b2773v788")
            .with_format_extent("102 pages")
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act".to_string())
            .build();

        assert_eq!(
            metadata.ark_hash().unwrap(),
            r#"{"http://arks.princeton.edu/ark:/88435/dsp01b2773v788":["DataSpace","Full text"]}"#
        );
    }

    #[test]
    fn ark_hash_returns_none_when_no_url() {
        let metadata = DataspaceDocument::builder()
            .with_id(Some("dsp01b2773v788".to_string()))
            .with_description_abstract(Some(vec!["Summary".to_string()]))
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_format_extent("102 pages".to_string())
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act".to_string())
            .build();

        assert_eq!(metadata.ark_hash(), None);
    }

    #[test]
    fn it_can_create_sortable_version_of_title() {
        assert_eq!(
            title_sort(&Some(vec!["\"Some quote\" : Blah blah".to_owned()])).unwrap(),
            "somequoteblahblah",
            "it should strip punctuation"
        );
        assert_eq!(
            title_sort(&Some(vec!["A title : blah blah".to_owned()])).unwrap(),
            "titleblahblah",
            "it should strip articles"
        );
        assert_eq!(
            title_sort(&Some(vec!["\"A quote\" : Blah blah".to_owned()])).unwrap(),
            "quoteblahblah",
            "it should strip punctuation and articles"
        );
        assert_eq!(
            title_sort(&Some(vec!["thesis".to_owned()])).unwrap(),
            "thesis",
            "it should leave words that start with articles alone"
        );
    }

    #[test]
    fn on_site_only() {
        assert!(DataspaceDocument::builder().with_embargo_terms(Some(vec!["2100-01-01".to_string()])).build().on_site_only(), "doc with embargo terms field should return true");
        assert!(DataspaceDocument::builder().with_embargo_lift(Some(vec!["2100-01-01".to_string()])).build().on_site_only(), "doc with embargo lift field should return true");
        assert!(DataspaceDocument::builder()
            .with_embargo_lift(Some(vec!["2000-01-01".to_string()]))
            .with_mudd_walkin("yes")
            .with_date_classyear("2012-01-01T00:00:00Z")
            .build()
            .on_site_only(), "with a specified accession date prior to 2013, it should return true");

        assert!(!DataspaceDocument::builder().with_location("physical location").build().on_site_only(), "doc with location field should return false");
        assert!(!DataspaceDocument::builder().with_embargo_lift(Some(vec!["2000-01-01".to_string()])).build().on_site_only(), "doc with expired embargo lift field should return false");
        assert!(!DataspaceDocument::builder()
            .with_embargo_lift(Some(vec!["2000-01-01".to_string()]))
            .with_mudd_walkin("yes")
            .build()
            .on_site_only(), "without a specified accession date, it should return false");
        assert!(!DataspaceDocument::builder()
            .with_embargo_lift(Some(vec!["2000-01-01".to_string()]))
            .with_mudd_walkin("yes")
            .with_date_classyear("2013-01-01T00:00:00Z")
            .build()
            .on_site_only(), "with a specified accession date in 2013, it should return false");
        assert!(!DataspaceDocument::builder().build().on_site_only(), "doc with no access-related fields should return false");
        assert!(!DataspaceDocument::builder().build().on_site_only());
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
        let metadata: Vec<DataspaceDocument> = serde_json::from_str(&json).unwrap();
        assert_eq!(metadata.len(), 1);
        assert_eq!(metadata[0].id, Some("dsp01b2773v788".to_owned()));
        assert_eq!(metadata[0].title, Some(vec!["Dysfunction: A Play in One Act".to_owned()]));
        assert_eq!(metadata[0].contributor, Some(vec!["Wolff, Tamsen".to_owned(), "2nd contributor".to_owned()]));
        assert_eq!(metadata[0].contributor_advisor, Some(vec!["Sandberg, Robert".to_owned()]));
        assert_eq!(metadata[0].contributor_author, Some(vec!["Clark, Hillary".to_owned()]));
        assert_eq!(metadata[0].identifier_uri, Some(vec!["http://arks.princeton.edu/ark:/88435/dsp01b2773v788".to_owned()]));
        assert_eq!(metadata[0].format_extent, Some(vec!["102 pages".to_owned()]));
        assert_eq!(metadata[0].language_iso, Some(vec!["en_US".to_owned()]));
        assert_eq!(metadata[0].date_classyear, Some(vec!["2013".to_owned()]));
        assert_eq!(metadata[0].department, Some(vec!["English".to_owned(), "NA".to_owned()]));
        assert_eq!(metadata[0].certificate, Some(vec!["Creative Writing Program".to_owned(), "NA".to_owned()]));
        assert_eq!(metadata[0].rights_access_rights, Some(vec!["Walk-in Access...".to_owned()]));
    }
}
