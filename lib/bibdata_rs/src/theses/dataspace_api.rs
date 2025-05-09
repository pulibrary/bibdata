use serde::Deserialize;
use crate::theses::{language, solr, holdings};
use crate::theses::latex;
use itertools::Itertools;

// This is an intermediate representation of the data from dspace, representing the key value pairs taken from
// DSpace API metadata
#[derive(Debug, Deserialize)]
struct Metadata {
    id: Option<String>,
    #[serde(rename="dc.contributor")]
    contributor: Option<Vec<String>>,
    #[serde(rename="dc.contributor.advisor")]
    contributor_advisor: Option<Vec<String>>,
    #[serde(rename="dc.contributor.author")]
    contributor_author: Option<Vec<String>>,
    #[serde(rename="dc.date.accessioned")]
    date_accessioned: Option<Vec<String>>,
    #[serde(rename="dc.date.available")]
    date_available: Option<Vec<String>>,
    #[serde(rename="pu.date.classyear")]
    date_classyear: Option<Vec<String>>,
    #[serde(rename="dc.description.abstract")]
    description_abstract: Option<Vec<String>>,
    #[serde(rename="pu.department")]
    department: Option<Vec<String>>,
    #[serde(rename="pu.embargo.lift")]
    embargo_lift: Option<Vec<String>>,
    #[serde(rename="pu.embargo.terms")]
    embargo_terms: Option<Vec<String>>,
    #[serde(rename="dc.format.extent")]
    format_extent: Option<Vec<String>>,
    #[serde(rename="dc.identifier.other")]
    identifier_other: Option<Vec<String>>,
    #[serde(rename="dc.identifier.uri")]
    identifier_uri: Option<Vec<String>>,
    #[serde(rename="dc.language.iso")]
    language_iso: Option<Vec<String>>,
    #[serde(rename="pu.location")]
    location: Option<Vec<String>>,
    #[serde(rename="pu.mudd.walkin")]
    mudd_walkin: Option<Vec<String>>,
    #[serde(rename="dc.rights.accessRights")]
    rights_access_rights: Option<Vec<String>>,
    #[serde(rename="dc.title")]
    title: Option<Vec<String>>,
}

/// Take first title, strip out latex expressions when present to include along
/// with non-normalized version (allowing users to get matches both when LaTex
/// is pasted directly into the search box and when sub/superscripts are placed
/// adjacent to regular characters
fn title_search_versions(possible_titles: &Option<Vec<String>>) -> Option<Vec<String>> {
    match possible_titles {
        Some(titles) => {
            if let Some(title) = titles.first() {
                Some(vec![title.to_string(), latex::normalize_latex(title.to_string())].into_iter().unique().collect())
            } else { None }
        },
        None => None
    }
}

pub fn fake_title_search_versions(possible_titles: Option<Vec<String>>) -> Option<Vec<String>> {
    match possible_titles {
        Some(titles) => {
            if let Some(title) = titles.first() {
                Some(vec![title.to_string(), latex::normalize_latex(title.to_string())].into_iter().unique().collect())
            } else { None }
        },
        None => None
    }
}
impl Metadata {
    pub fn ark_hash(&self) -> Option<String> {
        holdings::ark_hash(
            self.identifier_uri.clone(),
            self.location.is_some(),
            self.rights_access_rights.is_some(),
            self.mudd_walkin.clone(),
            self.date_classyear.clone()?,
            self.embargo_lift.clone(),
            self.embargo_terms.clone()
        )
    }

    pub fn call_number(&self) -> String {
        holdings::call_number(self.identifier_other.clone())
    }
    pub fn languages(&self) -> Vec<String> {
        language::codes_to_english_names(self.language_iso.clone())
    }
}

impl From<Metadata> for solr::SolrDocument {
    fn from(value: Metadata) -> Self {
        let binding = value.title.clone().unwrap_or_default();
        let first_title = binding.first();
        solr::SolrDocument::builder()
            .with_id(value.id.clone().unwrap_or_default())
            .with_title_t(&title_search_versions(&value.title))
            .with_title_citation_display(&first_title)
            .with_title_display(&first_title)
            .with_title_sort(&title_sort(&value.title))
            .with_electronic_access_1display(&value.ark_hash())
            .with_call_number_browse_s(value.call_number())
            .with_call_number_display(value.call_number())
            .with_language_facet(value.languages())
            .with_language_name_display(value.languages())
            .build()
    }
}

fn title_sort(titles: &Option<Vec<String>>) -> Option<String> {
    match titles {
        Some(title_vec) => {
            let first = title_vec.first()?;
            Some(first.to_lowercase()
            .trim_start_matches("a ")
            .trim_start_matches("an ")
            .trim_start_matches("the ")
            .chars()
            .filter(|c| !c.is_whitespace() && !c.is_ascii_punctuation())
            .collect::<String>())
        },
        None => None
    }
}

pub fn ruby_json_to_solr_json(ruby: String) -> String {
    let metadata: Metadata = serde_json::from_str(&ruby).unwrap();
    serde_json::to_string(&solr::SolrDocument::from(metadata)).unwrap()
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn it_can_parse_json() {
        let metadata: Metadata = serde_json::from_str(r#"{"id":"123456","pu.embargo.lift":["2010-07-01"],"pu.mudd.walkin":["yes"]}"#).unwrap();
        assert_eq!(metadata.id.unwrap(), "123456");
        assert_eq!(metadata.embargo_lift.unwrap(), vec!["2010-07-01"]);
        assert_eq!(metadata.mudd_walkin.unwrap(), vec!["yes"]);
    }

    #[test]
    fn it_can_convert_into_solr_document() {
        let metadata: Metadata = serde_json::from_str(r#"{"id":"dsp01b2773v788","dc.description.abstract":["Summary"],"dc.contributor":["Wolff, Tamsen"],
        "dc.contributor.advisor":["Sandberg, Robert"],"dc.contributor.author":["Clark, Hillary"],"dc.date.accessioned":["2013-07-11T14:31:58Z"],"dc.date.available":["2013-07-11T14:31:58Z"],
        "dc.date.created":["2013-04-02"],"dc.date.issued":["2013-07-11"],"dc.identifier.uri":["http://arks.princeton.edu/ark:/88435/dsp01b2773v788"],
        "dc.format.extent":["102 pages"],"dc.language.iso":["en_US"],"dc.title":["Dysfunction: A Play in One Act"],
        "dc.type":["Princeton University Senior Theses"],"pu.date.classyear":["2014"],
        "pu.department":["Princeton University. Department of English","Princeton University. Program in Theater"],"pu.pdf.coverpage":["SeniorThesisCoverPage"],
        "dc.rights.accessRights":["Walk-in Access..."]}"#).unwrap();
        let solr = solr::SolrDocument::from(metadata);

        assert_eq!(solr.id, "dsp01b2773v788");
        assert_eq!(solr.title_t.unwrap(), vec!["Dysfunction: A Play in One Act"]);
        assert_eq!(solr.title_citation_display.unwrap(), "Dysfunction: A Play in One Act");
        assert_eq!(solr.title_display.unwrap(), "Dysfunction: A Play in One Act");
        assert_eq!(solr.title_sort.unwrap(), "dysfunctionaplayinoneact");
    }


    #[test]
    fn it_can_create_sortable_version_of_title() {
        assert_eq!(title_sort(&Some(vec!["\"Some quote\" : Blah blah".to_owned()])).unwrap(), "somequoteblahblah");
    }
}
