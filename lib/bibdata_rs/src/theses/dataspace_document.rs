use crate::theses::{embargo, holdings, language, latex, solr};
use itertools::Itertools;
use serde::Deserialize;

// This is an intermediate representation of the data from dspace, representing the key value pairs taken from
// DSpace API metadata
#[derive(Debug, Deserialize)]
pub struct DataspaceDocument {
    id: Option<String>,

    #[serde(rename = "pu.certificate")]
    certificate: Option<Vec<String>>,

    #[serde(rename = "dc.contributor")]
    contributor: Option<Vec<String>>,

    #[serde(rename = "dc.contributor.advisor")]
    contributor_advisor: Option<Vec<String>>,

    #[serde(rename = "dc.contributor.author")]
    contributor_author: Option<Vec<String>>,

    #[serde(rename = "pu.date.classyear")]
    date_classyear: Option<Vec<String>>,

    #[serde(rename = "dc.description.abstract")]
    description_abstract: Option<Vec<String>>,

    #[serde(rename = "pu.department")]
    department: Option<Vec<String>>,

    #[serde(rename = "pu.embargo.lift")]
    embargo_lift: Option<Vec<String>>,

    #[serde(rename = "pu.embargo.terms")]
    embargo_terms: Option<Vec<String>>,

    #[serde(rename = "dc.format.extent")]
    format_extent: Option<Vec<String>>,

    #[serde(rename = "dc.identifier.other")]
    identifier_other: Option<Vec<String>>,

    #[serde(rename = "dc.identifier.uri")]
    identifier_uri: Option<Vec<String>>,

    #[serde(rename = "dc.language.iso")]
    language_iso: Option<Vec<String>>,

    #[serde(rename = "pu.location")]
    location: Option<Vec<String>>,

    #[serde(rename = "pu.mudd.walkin")]
    mudd_walkin: Option<Vec<String>>,

    #[serde(rename = "dc.rights.accessRights")]
    rights_access_rights: Option<Vec<String>>,

    #[serde(rename = "dc.title")]
    title: Option<Vec<String>>,
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

    pub fn with_contributor(mut self, contributor: Option<Vec<String>>) -> Self {
        self.contributor = contributor;
        self
    }

    pub fn with_contributor_advisor(mut self, contributor_advisor: Option<Vec<String>>) -> Self {
        self.contributor_advisor = contributor_advisor;
        self
    }

    pub fn with_contributor_author(mut self, contributor_author: Option<Vec<String>>) -> Self {
        self.contributor_author = contributor_author;
        self
    }

    pub fn with_date_classyear(mut self, date_classyear: Option<Vec<String>>) -> Self {
        self.date_classyear = date_classyear;
        self
    }

    pub fn with_description_abstract(mut self, description_abstract: Option<Vec<String>>) -> Self {
        self.description_abstract = description_abstract;
        self
    }

    pub fn with_department(mut self, department: Option<Vec<String>>) -> Self {
        self.department = department;
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

    pub fn with_format_extent(mut self, format_extent: Option<Vec<String>>) -> Self {
        self.format_extent = format_extent;
        self
    }

    pub fn with_identifier_uri(mut self, identifier_uri: Option<Vec<String>>) -> Self {
        self.identifier_uri = identifier_uri;
        self
    }

    pub fn with_language_iso(mut self, language_iso: Option<Vec<String>>) -> Self {
        self.language_iso = language_iso;
        self
    }

    pub fn with_location(mut self, location: Option<Vec<String>>) -> Self {
        self.location = location;
        self
    }

    pub fn with_mudd_walkin(mut self, mudd_walkin: Option<Vec<String>>) -> Self {
        self.mudd_walkin = mudd_walkin;
        self
    }

    pub fn with_title(mut self, title: Option<Vec<String>>) -> Self {
        self.title = title;
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_build_a_document() {
        let metadata = DataspaceDocument::builder()
            .with_id(Some("123456".to_string()))
            .with_embargo_lift(Some(vec!["2010-07-01".to_string()]))
            .with_mudd_walkin(Some(vec!["yes".to_string()]))
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
            .with_contributor(Some(vec!["Wolff, Tamsen".to_string()]))
            .with_contributor_advisor(Some(vec!["Sandberg, Robert".to_string()]))
            .with_contributor_author(Some(vec!["Clark, Hillary".to_string()]))
            .with_date_classyear(Some(vec!["2014".to_string()]))
            .with_department(Some(vec![
                "Princeton University. Department of English".to_string(),
                "Princeton University. Program in Theater".to_string(),
            ]))
            .with_format_extent(Some(vec!["102 pages".to_string()]))
            .with_language_iso(Some(vec!["en_US".to_string()]))
            .with_title(Some(vec!["Dysfunction: A Play in One Act".to_string()]))
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
            .with_contributor(Some(vec!["Wolff, Tamsen".to_string()]))
            .with_contributor_advisor(Some(vec!["Sandberg, Robert".to_string()]))
            .with_contributor_author(Some(vec!["Clark, Hillary".to_string()]))
            .with_date_classyear(Some(vec!["2014".to_string()]))
            .with_department(Some(vec![
                "Princeton University. Department of English".to_string(),
                "Princeton University. Program in Theater".to_string(),
            ]))
            .with_identifier_uri(Some(vec![
                "http://arks.princeton.edu/ark:/88435/dsp01b2773v788".to_string(),
            ]))
            .with_format_extent(Some(vec!["102 pages".to_string()]))
            .with_language_iso(Some(vec!["en_US".to_string()]))
            .with_title(Some(vec!["Dysfunction: A Play in One Act".to_string()]))
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
            .with_contributor(Some(vec!["Wolff, Tamsen".to_string()]))
            .with_contributor_advisor(Some(vec!["Sandberg, Robert".to_string()]))
            .with_contributor_author(Some(vec!["Clark, Hillary".to_string()]))
            .with_date_classyear(Some(vec!["2014".to_string()]))
            .with_department(Some(vec![
                "Princeton University. Department of English".to_string(),
                "Princeton University. Program in Theater".to_string(),
            ]))
            .with_identifier_uri(Some(vec![
                "http://arks.princeton.edu/ark:/88435/dsp01b2773v788".to_string(),
            ]))
            .with_format_extent(Some(vec!["102 pages".to_string()]))
            .with_language_iso(Some(vec!["en_US".to_string()]))
            .with_title(Some(vec!["Dysfunction: A Play in One Act".to_string()]))
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
            .with_contributor(Some(vec!["Wolff, Tamsen".to_string()]))
            .with_contributor_advisor(Some(vec!["Sandberg, Robert".to_string()]))
            .with_contributor_author(Some(vec!["Clark, Hillary".to_string()]))
            .with_date_classyear(Some(vec!["2014".to_string()]))
            .with_department(Some(vec![
                "Princeton University. Department of English".to_string(),
                "Princeton University. Program in Theater".to_string(),
            ]))
            .with_format_extent(Some(vec!["102 pages".to_string()]))
            .with_language_iso(Some(vec!["en_US".to_string()]))
            .with_title(Some(vec!["Dysfunction: A Play in One Act".to_string()]))
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
            .with_mudd_walkin(Some(vec!["yes".to_string()]))
            .with_date_classyear(Some(vec!["2012-01-01T00:00:00Z".to_string()]))
            .build()
            .on_site_only(), "with a specified accession date prior to 2013, it should return true");

        assert!(!DataspaceDocument::builder().with_location(Some(vec!["physical location".to_string()])).build().on_site_only(), "doc with location field should return false");
        assert!(!DataspaceDocument::builder().with_embargo_lift(Some(vec!["2000-01-01".to_string()])).build().on_site_only(), "doc with expired embargo lift field should return false");
        assert!(!DataspaceDocument::builder()
            .with_embargo_lift(Some(vec!["2000-01-01".to_string()]))
            .with_mudd_walkin(Some(vec!["yes".to_string()]))
            .build()
            .on_site_only(), "without a specified accession date, it should return false");
        assert!(!DataspaceDocument::builder()
            .with_embargo_lift(Some(vec!["2000-01-01".to_string()]))
            .with_mudd_walkin(Some(vec!["yes".to_string()]))
            .with_date_classyear(Some(vec!["2013-01-01T00:00:00Z".to_string()]))
            .build()
            .on_site_only(), "with a specified accession date in 2013, it should return false");
        assert!(!DataspaceDocument::builder().build().on_site_only(), "doc with no access-related fields should return false");
        assert!(!DataspaceDocument::builder().build().on_site_only());
    }
}
