// This module is responsible for normalizing data within a DataspaceDocument

use crate::{
    solr::{AccessFacet, LibraryFacet},
    theses::{
        dataspace::document::DataspaceDocument,
        department,
        embargo::{self, Embargo},
        holdings::{self, ThesisAvailability},
        language, program,
    },
};
use itertools::Itertools;
use regex::{Captures, Regex};
use std::sync::LazyLock;

impl DataspaceDocument {
    pub fn access_facet(&self) -> Option<AccessFacet> {
        match (self.embargo(), self.on_site_only()) {
            (embargo::Embargo::Current(_), _) => None,
            (_, ThesisAvailability::AvailableOffSite) => Some(AccessFacet::Online),
            (_, ThesisAvailability::OnSiteOnly) => Some(AccessFacet::InTheLibrary),
        }
    }

    pub fn advanced_location(&self) -> Option<Vec<String>> {
        match self.on_site_only() {
            ThesisAvailability::OnSiteOnly => Some(vec![
                "mudd$stacks".to_owned(),
                "Mudd Manuscript Library".to_owned(),
            ]),
            _ => None,
        }
    }

    pub fn all_authors(&self) -> Vec<String> {
        let mut authors = match &self.contributor_author {
            Some(authors) => authors.clone(),
            None => Vec::new(),
        };
        authors.extend(self.contributor_advisor.clone().unwrap_or_default());
        authors.extend(self.contributor.clone().unwrap_or_default());
        authors.extend(
            self.department
                .clone()
                .unwrap_or_default()
                .iter()
                .filter_map(|dept| department::map_department(dept)),
        );
        authors.extend(
            self.certificate
                .clone()
                .unwrap_or_default()
                .iter()
                .filter_map(|program| program::map_program(program)),
        );
        authors
    }

    pub fn ark_hash(&self) -> Option<String> {
        holdings::dataspace_url_with_metadata(
            self.identifier_uri.as_ref(),
            self.location.is_some(),
            self.rights_access_rights.is_some(),
            self.walkin_is_yes(),
            match &self.date_classyear {
                Some(class_year) => class_year,
                None => &[],
            },
            self.embargo(),
        )
    }

    pub fn authorized_ceritificates(&self) -> Option<Vec<String>> {
        self.certificate.as_ref().map(|certificates| {
            certificates
                .iter()
                .filter_map(|certificate| program::map_program(certificate))
                .collect()
        })
    }

    pub fn authorized_departments(&self) -> Option<Vec<String>> {
        self.department.as_ref().map(|departments| {
            departments
                .iter()
                .filter_map(|department| department::map_department(department))
                .collect()
        })
    }

    pub fn call_number(&self) -> String {
        holdings::call_number(self.identifier_other.as_ref())
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

    pub fn languages(&self) -> Vec<String> {
        language::codes_to_english_names(self.language_iso.clone())
    }

    pub fn location(&self) -> Option<LibraryFacet> {
        match self.on_site_only() {
            ThesisAvailability::OnSiteOnly => Some(LibraryFacet::Mudd),
            _ => None,
        }
    }

    pub fn location_display(&self) -> Option<String> {
        match self.on_site_only() {
            ThesisAvailability::OnSiteOnly => Some("Mudd Manuscript Library".to_owned()),
            _ => None,
        }
    }

    pub fn location_code(&self) -> Option<String> {
        match self.on_site_only() {
            ThesisAvailability::OnSiteOnly => Some("mudd$stacks".to_owned()),
            _ => None,
        }
    }

    pub fn on_site_only(&self) -> ThesisAvailability {
        holdings::on_site_only(
            self.location.is_some(),
            self.rights_access_rights.is_some(),
            self.walkin_is_yes(),
            match &self.date_classyear {
                Some(class_year) => class_year,
                None => &[],
            },
            self.embargo(),
        )
    }

    pub fn online_portfolio_statements(&self) -> Option<String> {
        if self.on_site_only() == ThesisAvailability::OnSiteOnly
            || matches!(self.embargo(), Embargo::Current(_))
        {
            None
        } else {
            holdings::online_holding_string(self.identifier_other.as_ref())
        }
    }

    pub fn physical_holding_string(&self) -> Option<String> {
        match self.on_site_only() {
            ThesisAvailability::AvailableOffSite => None,
            ThesisAvailability::OnSiteOnly => {
                holdings::physical_holding_string(self.identifier_other.as_ref())
            }
        }
    }

    pub fn restrictions_note_display(&self) -> Option<Vec<String>> {
        match &self.rights_access_rights {
            Some(rights) => rights.first().map(|s| vec![s.clone()]),
            None => {
                if self.walkin_is_yes() {
                    Some(vec!["Walk-in Access. This thesis can only be viewed on computer terminals at the '<a href=\"http://mudd.princeton.edu\">Mudd Manuscript Library</a>.".to_owned()])
                } else {
                    match self.embargo() {
                    Embargo::Current(text) => Some(vec![text]),
                    Embargo::None => None,
                    Embargo::Expired => None,
                    Embargo::Invalid => Some(vec![
                        format!("This content is currently under embargo. For more information contact the <a href=\"mailto:dspadmin@princeton.edu?subject=Regarding embargoed DataSpace Item 88435/{}\"> Mudd Manuscript Library</a>.", self.id.clone().unwrap_or_default())
                    ]),
                }
                }
            }
        }
    }

    /// Take first title, strip out latex expressions when present to include along
    /// with non-normalized version (allowing users to get matches both when LaTex
    /// is pasted directly into the search box and when sub/superscripts are placed
    /// adjacent to regular characters
    pub fn title_search_versions(&self) -> Option<Vec<String>> {
        match &self.title {
            Some(titles) => titles.first().map(|title| {
                vec![title.to_string(), normalize_latex(title)]
                    .into_iter()
                    .unique()
                    .collect()
            }),
            None => None,
        }
    }

    fn embargo(&self) -> embargo::Embargo {
        embargo::Embargo::from_dates(
            self.embargo_lift.as_ref(),
            self.embargo_terms.as_ref(),
            self.id.as_ref().map_or("", |v| v),
        )
    }

    fn walkin_is_yes(&self) -> bool {
        matches!(&self.mudd_walkin, Some(vec) if vec.first().is_some_and(|walkin| walkin == "yes"))
    }
}

fn normalize_latex(original: &str) -> String {
    static LATEX_REGEX: LazyLock<Regex> = LazyLock::new(|| Regex::new(r"\\\(.*?\\\)").unwrap());
    LATEX_REGEX
        .replace_all(original, |captures: &Captures| {
            captures[0]
                .chars()
                .filter(|c| c.is_alphanumeric())
                .collect::<String>()
        })
        .to_string()
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn it_normalizes_latex() {
        assert_eq!(
            normalize_latex("2D \\(^{1}\\)H-\\(^{14}\\)N HSQC inverse-detection experiments"),
            "2D 1H-14N HSQC inverse-detection experiments"
        );
    }

    #[test]
    fn ark_hash_gets_the_ark_with_fulltext_link_display_when_restrictions() {
        let metadata = DataspaceDocument::builder()
            .with_id("dsp01b2773v788")
            .with_description_abstract("Summary")
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_identifier_uri("http://arks.princeton.edu/ark:/88435/dsp01b2773v788")
            .with_format_extent("102 pages")
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act")
            .build();

        assert_eq!(
            metadata.ark_hash().unwrap(),
            r#"{"http://arks.princeton.edu/ark:/88435/dsp01b2773v788":["DataSpace","Full text"]}"#
        );
    }

    #[test]
    fn ark_hash_gets_the_ark_with_fulltext_link_display_when_no_restrictions() {
        let metadata = DataspaceDocument::builder()
            .with_id("dsp01b2773v788")
            .with_description_abstract("Summary")
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_identifier_uri("http://arks.princeton.edu/ark:/88435/dsp01b2773v788")
            .with_format_extent("102 pages")
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act")
            .build();

        assert_eq!(
            metadata.ark_hash().unwrap(),
            r#"{"http://arks.princeton.edu/ark:/88435/dsp01b2773v788":["DataSpace","Full text"]}"#
        );
    }

    #[test]
    fn ark_hash_returns_none_when_no_url() {
        let metadata = DataspaceDocument::builder()
            .with_id("dsp01b2773v788")
            .with_description_abstract("Summary")
            .with_contributor("Wolff, Tamsen".to_string())
            .with_contributor_advisor("Sandberg, Robert".to_string())
            .with_contributor_author("Clark, Hillary".to_string())
            .with_date_classyear("2014")
            .with_department("Princeton University. Department of English")
            .with_department("Princeton University. Program in Theater")
            .with_format_extent("102 pages".to_string())
            .with_language_iso("en_US")
            .with_title("Dysfunction: A Play in One Act")
            .build();

        assert_eq!(metadata.ark_hash(), None);
    }

    #[test]
    fn on_site_only() {
        assert_eq!(
            DataspaceDocument::builder()
                .with_embargo_terms("2100-01-01")
                .build()
                .on_site_only(),
            ThesisAvailability::OnSiteOnly,
            "doc with embargo terms field should return OnSiteOnly"
        );
        assert_eq!(
            DataspaceDocument::builder()
                .with_embargo_lift("2100-01-01")
                .build()
                .on_site_only(),
            ThesisAvailability::OnSiteOnly,
            "doc with embargo lift field should return OnSiteOnly"
        );
        assert_eq!(
            DataspaceDocument::builder()
                .with_embargo_lift("2000-01-01")
                .with_mudd_walkin("yes")
                .with_date_classyear("2012-01-01T00:00:00Z")
                .build()
                .on_site_only(),
            ThesisAvailability::OnSiteOnly,
            "with a specified accession date prior to 2013, it should return OnSiteOnly"
        );

        assert_eq!(
            DataspaceDocument::builder()
                .with_location("physical location")
                .build()
                .on_site_only(),
            ThesisAvailability::AvailableOffSite,
            "doc with location field should return AvailableOffSite"
        );
        assert_eq!(
            DataspaceDocument::builder()
                .with_embargo_lift("2000-01-01")
                .build()
                .on_site_only(),
            ThesisAvailability::AvailableOffSite,
            "doc with expired embargo lift field should return AvailableOffSite"
        );
        assert_eq!(
            DataspaceDocument::builder()
                .with_embargo_lift("2000-01-01")
                .with_mudd_walkin("yes")
                .build()
                .on_site_only(),
            ThesisAvailability::AvailableOffSite,
            "without a specified accession date, it should return AvailableOffSite"
        );
        assert_eq!(
            DataspaceDocument::builder()
                .with_embargo_lift("2000-01-01")
                .with_mudd_walkin("yes")
                .with_date_classyear("2013-01-01T00:00:00Z")
                .build()
                .on_site_only(),
            ThesisAvailability::AvailableOffSite,
            "with a specified accession date in 2013, it should return AvailableOffSite"
        );
        assert_eq!(
            DataspaceDocument::builder().build().on_site_only(),
            ThesisAvailability::AvailableOffSite,
            "doc with no access-related fields should return AvailableOffSite"
        );
        assert_eq!(
            DataspaceDocument::builder().build().on_site_only(),
            ThesisAvailability::AvailableOffSite
        );
    }

    mod all_authors {
        use super::*;

        #[test]
        fn it_includes_author() {
            let document = DataspaceDocument::builder()
                .with_contributor_author("Turing, Alan")
                .build();
            assert_eq!(document.all_authors(), vec!["Turing, Alan".to_owned()]);
        }

        #[test]
        fn it_includes_normalized_department() {
            let document = DataspaceDocument::builder()
                .with_department("Astrophysical Sciences")
                .build();
            assert_eq!(
                document.all_authors(),
                vec!["Princeton University. Department of Astrophysical Sciences".to_owned()]
            );
        }

        #[test]
        fn it_includes_normalized_certificate() {
            let document = DataspaceDocument::builder()
                .with_certificate("Hellenic Studies Program")
                .build();
            assert_eq!(
                document.all_authors(),
                vec!["Princeton University. Program in Hellenic Studies".to_owned()]
            );
        }
    }
}
