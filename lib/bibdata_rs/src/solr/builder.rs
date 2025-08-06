// This module provides a convenient way to create a SolrDocument using the builder pattern

use super::{AccessFacet, ElectronicAccess, FormatFacet, LibraryFacet, SolrDocument};

#[derive(Debug, Default)]
pub struct SolrDocumentBuilder {
    author_s: Option<Vec<String>>,
    author_sort: Option<String>,
    author_display: Option<Vec<String>>,
    author_roles_1display: Option<String>,
    author_citation_display: Option<Vec<String>>,
    advisor_display: Option<Vec<String>>,
    format: Option<Vec<FormatFacet>>,
    geographic_facet: Option<Vec<String>>,
    id: String,
    title_t: Option<Vec<String>>,
    title_citation_display: Option<String>,
    title_display: Option<String>,
    title_sort: Option<String>,
    electronic_access_1display: Option<ElectronicAccess>,
    restrictions_display_text: Option<Vec<String>>,
    restrictions_note_display: Option<Vec<String>>,
    call_number_display: String,
    call_number_browse_s: String,
    homoit_subject_display: Option<Vec<String>>,
    homoit_subject_facet: Option<Vec<String>>,
    language_facet: Vec<String>,
    language_name_display: Vec<String>,
    lc_subject_display: Option<Vec<String>>,
    lc_subject_facet: Option<Vec<String>>,
    location: Option<LibraryFacet>,
    location_display: Option<String>,
    location_code_s: Option<String>,
    notes: Option<Vec<String>>,
    notes_display: Option<Vec<String>>,
    advanced_location_s: Option<Vec<String>>,
    access_facet: Option<AccessFacet>,
    holdings_1display: Option<String>,
    electronic_portfolio_s: Option<String>,
    class_year_s: Option<Vec<i16>>,
    other_title_display: Option<Vec<String>>,
    provenance_display: Option<String>,
    publication_location_citation_display: Option<Vec<String>>,
    publisher_no_display: Option<Vec<String>>,
    pub_created_display: Option<Vec<String>>,
    publisher_citation_display: Option<Vec<String>>,
    pub_date_start_sort: Option<i16>,
    pub_date_end_sort: Option<i16>,
    contributor_display: Option<Vec<String>>,
    department_display: Option<Vec<String>>,
    certificate_display: Option<Vec<String>>,
    description_display: Option<Vec<String>>,
    summary_note_display: Option<Vec<String>>,
}
impl SolrDocumentBuilder {
    pub fn with_id(&mut self, id: impl Into<String>) -> &mut Self {
        self.id = id.into();
        self
    }
    pub fn with_author_roles_1display(
        &mut self,
        author_roles_1display: Option<String>,
    ) -> &mut Self {
        self.author_roles_1display = author_roles_1display;
        self
    }
    pub fn with_author_citation_display(
        &mut self,
        author_citation_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.author_citation_display = author_citation_display;
        self
    }

    pub fn with_geographic_facet(
        &mut self,
        geographic_facet: Option<Vec<String>>,
    ) -> &mut Self {
        self.geographic_facet = geographic_facet;
        self
    }

    pub fn with_title_t(&mut self, title_t: Option<Vec<String>>) -> &mut Self {
        self.title_t = title_t;
        self
    }
    pub fn with_title_citation_display(
        &mut self,
        title_citation_display: Option<String>,
    ) -> &mut Self {
        self.title_citation_display = title_citation_display;
        self
    }
    pub fn with_title_display(&mut self, title_display: Option<String>) -> &mut Self {
        self.title_display = title_display;
        self
    }
    pub fn with_other_title_display(
        &mut self,
        other_title_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.other_title_display = other_title_display;
        self
    }
    pub fn with_publication_location_citation_display(
        &mut self,
        publication_location_citation_display: Vec<String>,
    ) -> &mut Self {
        self.publication_location_citation_display = Some(publication_location_citation_display);
        self
    }
    pub fn with_pub_created_display(
        &mut self,
        pub_created_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.pub_created_display = pub_created_display;
        self
    }
    pub fn with_publisher_no_display(
        &mut self,
        publisher_no_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.publisher_no_display = publisher_no_display;
        self
    }
    pub fn with_publisher_citation_display(
        &mut self,
        publisher_citation_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.publisher_citation_display = publisher_citation_display;
        self
    }
    pub fn with_title_sort(&mut self, title_sort: Option<String>) -> &mut Self {
        self.title_sort = title_sort;
        self
    }

    pub fn with_author_sort(&mut self, author_sort: Option<String>) -> &mut Self {
        self.author_sort = author_sort;
        self
    }
    pub fn with_electronic_access_1display(
        &mut self,
        electronic_access_1display: Option<ElectronicAccess>,
    ) -> &mut Self {
        self.electronic_access_1display = electronic_access_1display;
        self
    }

    pub fn with_call_number_display(
        &mut self,
        call_number_display: impl Into<String>,
    ) -> &mut Self {
        self.call_number_display = call_number_display.into();
        self
    }

    pub fn with_call_number_browse_s(
        &mut self,
        call_number_browse_s: impl Into<String>,
    ) -> &mut Self {
        self.call_number_browse_s = call_number_browse_s.into();
        self
    }

    pub fn with_format(&mut self, format: Vec<FormatFacet>) -> &mut Self {
        self.format = Some(format);
        self
    }

    pub fn with_language_facet(&mut self, language_facet: impl Into<Vec<String>>) -> &mut Self {
        self.language_facet = language_facet.into();
        self
    }

    pub fn with_language_name_display(
        &mut self,
        language_name_display: impl Into<Vec<String>>,
    ) -> &mut Self {
        self.language_name_display = language_name_display.into();
        self
    }
    pub fn with_homoit_subject_display(
        &mut self,
        homoit_subject_display: Vec<String>,
    ) -> &mut Self {
        self.homoit_subject_display = Some(homoit_subject_display);
        self
    }
    pub fn with_homoit_subject_facet(&mut self, homoit_subject_facet: Vec<String>) -> &mut Self {
        self.homoit_subject_facet = Some(homoit_subject_facet);
        self
    }
    pub fn with_lc_subject_display(&mut self, lc_subject_display: Vec<String>) -> &mut Self {
        self.lc_subject_display = Some(lc_subject_display);
        self
    }

    pub fn with_lc_subject_facet(&mut self, lc_subject_facet: Vec<String>) -> &mut Self {
        self.lc_subject_facet = Some(lc_subject_facet);
        self
    }

    pub fn with_location(&mut self, location: Option<LibraryFacet>) -> &mut Self {
        self.location = location;
        self
    }
    pub fn with_location_display(&mut self, location_display: Option<String>) -> &mut Self {
        self.location_display = location_display;
        self
    }
    pub fn with_location_code_s(&mut self, location_code_s: Option<String>) -> &mut Self {
        self.location_code_s = location_code_s;
        self
    }
    pub fn with_notes(&mut self, notes: Option<Vec<String>>) -> &mut Self {
        self.notes = notes;
        self
    }
    pub fn with_notes_display(&mut self, notes_display: Option<Vec<String>>) -> &mut Self {
        self.notes_display = notes_display;
        self
    }
    pub fn with_advanced_location_s(
        &mut self,
        advanced_location_s: Option<Vec<String>>,
    ) -> &mut Self {
        self.advanced_location_s = advanced_location_s;
        self
    }
    pub fn with_access_facet(&mut self, access_facet: Option<AccessFacet>) -> &mut Self {
        self.access_facet = access_facet;
        self
    }
    pub fn with_holdings_1display(&mut self, holdings_1display: Option<String>) -> &mut Self {
        self.holdings_1display = holdings_1display;
        self
    }
    pub fn with_electronic_portfolio_s(
        &mut self,
        electronic_portfolio_s: Option<String>,
    ) -> &mut Self {
        self.electronic_portfolio_s = electronic_portfolio_s;
        self
    }
    pub fn with_class_year_s(&mut self, class_year_s: Option<Vec<i16>>) -> &mut Self {
        self.class_year_s = class_year_s;
        self
    }
    pub fn with_provenance_display(&mut self, provenance_display: Option<String>) -> &mut Self {
        self.provenance_display = provenance_display;
        self
    }
    pub fn with_pub_date_start_sort(&mut self, pub_date_start_sort: Option<i16>) -> &mut Self {
        self.pub_date_start_sort = pub_date_start_sort;
        self
    }
    pub fn with_pub_date_end_sort(&mut self, pub_date_end_sort: Option<i16>) -> &mut Self {
        self.pub_date_end_sort = pub_date_end_sort;
        self
    }
    pub fn with_author_display(&mut self, author_display: Option<Vec<String>>) -> &mut Self {
        self.author_display = author_display;
        self
    }
    pub fn with_author_s(&mut self, author_s: Vec<String>) -> &mut Self {
        self.author_s = Some(author_s);
        self
    }

    pub fn with_advisor_display(&mut self, advisor_display: Option<Vec<String>>) -> &mut Self {
        self.advisor_display = advisor_display;
        self
    }
    pub fn with_contributor_display(
        &mut self,
        contributor_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.contributor_display = contributor_display;
        self
    }
    pub fn with_department_display(
        &mut self,
        department_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.department_display = department_display;
        self
    }
    pub fn with_certificate_display(
        &mut self,
        certificate_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.certificate_display = certificate_display;
        self
    }
    pub fn with_description_display(
        &mut self,
        description_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.description_display = description_display;
        self
    }
    pub fn with_restrictions_note_display(
        &mut self,
        restrictions_note_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.restrictions_note_display = restrictions_note_display;
        self
    }
    pub fn with_summary_note_display(
        &mut self,
        summary_note_display: Option<Vec<String>>,
    ) -> &mut Self {
        self.summary_note_display = summary_note_display;
        self
    }
    pub fn build(&self) -> SolrDocument {
        SolrDocument {
            access_facet: self.access_facet,
            advanced_location_s: self.advanced_location_s.clone(),
            advisor_display: self.advisor_display.clone(),
            author_s: self.author_s.clone(),
            author_display: self.author_display.clone(),
            author_roles_1display: self.author_roles_1display.clone(),
            author_citation_display: self.author_citation_display.clone(),
            author_sort: self.author_sort.clone(),
            call_number_display: self.call_number_display.clone(),
            call_number_browse_s: self.call_number_browse_s.clone(),
            electronic_access_1display: self.electronic_access_1display.clone(),
            geographic_facet: self.geographic_facet.clone(),
            id: self.id.clone(),
            restrictions_display_text: self.restrictions_display_text.clone(),
            language_facet: self.language_facet.clone(),
            language_name_display: self.language_name_display.clone(),
            format: self.format.clone(),
            homoit_subject_display: self.homoit_subject_display.clone(),
            homoit_subject_facet: self.homoit_subject_facet.clone(),
            lc_subject_display: self.lc_subject_display.clone(),
            lc_subject_facet: self.lc_subject_facet.clone(),
            location: self.location,
            location_display: self.location_display.clone(),
            location_code_s: self.location_code_s.clone(),
            notes: self.notes.clone(),
            notes_display: self.notes_display.clone(),
            holdings_1display: self.holdings_1display.clone(),
            electronic_portfolio_s: self.electronic_portfolio_s.clone(),
            class_year_s: self.class_year_s.clone(),
            provenance_display: self.provenance_display.clone(),
            publisher_no_display: self.publisher_no_display.clone(),
            pub_created_display: self.pub_created_display.clone(),
            publisher_citation_display: self.publisher_citation_display.clone(),
            pub_date_start_sort: self.pub_date_start_sort,
            pub_date_end_sort: self.pub_date_end_sort,
            title_citation_display: self.title_citation_display.clone(),
            title_display: self.title_display.clone(),
            title_sort: self.title_sort.clone(),
            title_t: self.title_t.clone(),
            contributor_display: self.contributor_display.clone(),
            department_display: self.department_display.clone(),
            certificate_display: self.certificate_display.clone(),
            description_display: self.description_display.clone(),
            restrictions_note_display: self.restrictions_note_display.clone(),
            other_title_display: self.other_title_display.clone(),
            summary_note_display: self.summary_note_display.clone(),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_build_document_with_other_title_display() {
        let document = SolrDocumentBuilder::default()
            .with_other_title_display(Some(vec!["Aspen".to_string()]))
            .build();
        assert_eq!(
            document.other_title_display,
            Some(vec!["Aspen".to_string()])
        );
    }
}
