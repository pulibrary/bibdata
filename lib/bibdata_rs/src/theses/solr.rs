use crate::theses::{embargo, holdings};
use serde::Serialize;

#[derive(Debug, Default, Serialize)]
struct SolrDocument {
    id: String,
    title_t: Option<String>,
    title_citation_display: Option<String>,
    title_display: Option<String>,
    title_sort: Option<String>,
    author_sort: Option<String>,
    electronic_access_1display: Option<String>,
    restrictions_display_text: Option<Vec<String>>,
    call_number_display: String,
    call_number_browse_s: String,
    language_facet: Vec<String>,
    language_name_display: Vec<String>,
    format: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    location: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    location_display: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    location_code_s: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    advanced_location_s: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    access_facet: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    holdings_1display: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    electronic_portfolio_s: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    class_year_s: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub_date_start_sort: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub_date_end_sort: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    author_display: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    author_s: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    advisor_display: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    contributor_display: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    department_display: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    certificate_display: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    description_display: Option<Vec<String>>,
    #[serde(skip_serializing_if = "Option::is_none")]
    summary_note_display: Option<Vec<String>>,
}

impl SolrDocument {
    pub fn builder() -> SolrDocumentBuilder {
        SolrDocumentBuilder::default()
    }
}

#[derive(Default)]
struct SolrDocumentBuilder {
    id: String,
    title_t: Option<String>,
    title_citation_display: Option<String>,
    title_display: Option<String>,
    title_sort: Option<String>,
    author_sort: Option<String>,
    electronic_access_1display: Option<String>,
    restrictions_display_text: Option<Vec<String>>,
    call_number_display: String,
    call_number_browse_s: String,
    language_facet: Vec<String>,
    language_name_display: Vec<String>,
    location: Option<String>,
    location_display: Option<String>,
    location_code_s: Option<String>,
    advanced_location_s: Option<Vec<String>>,
    access_facet: Option<String>,
    holdings_1display: Option<String>,
    electronic_portfolio_s: Option<String>,
    class_year_s: Option<Vec<String>>,
    pub_date_start_sort: Option<Vec<String>>,
    pub_date_end_sort: Option<Vec<String>>,
    author_display: Option<Vec<String>>,
    author_s: Option<Vec<String>>,
    advisor_display: Option<Vec<String>>,
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
    pub fn with_title_t(&mut self, title_t: impl Into<String>) -> &mut Self {
        self.title_t = Some(title_t.into());
        self
    }
    pub fn with_title_citation_display(&mut self, title_citation_display: impl Into<String>) -> &mut Self {
        self.title_citation_display = Some(title_citation_display.into());
        self
    }
    pub fn with_title_display(&mut self, title_display: impl Into<String>) -> &mut Self {
        self.title_display = Some(title_display.into());
        self
    }
    pub fn with_title_sort(&mut self, title_sort: impl Into<String>) -> &mut Self {
        self.title_sort = Some(title_sort.into());
        self
    }
    pub fn with_author_sort(&mut self, author_sort: impl Into<String>) -> &mut Self {
        self.author_sort = Some(author_sort.into());
        self
    }
    pub fn with_electronic_access_1display(&mut self, electronic_access_1display: impl Into<String>) -> &mut Self {
        self.electronic_access_1display = Some(electronic_access_1display.into());
        self
    }

    pub fn with_restrictions_display_text(&mut self, restrictions_display_text: impl Into<Vec<String>>) -> &mut Self {
        self.restrictions_display_text = Some(restrictions_display_text.into());
        self
    }

    pub fn with_call_number_display(&mut self, call_number_display: impl Into<String>) -> &mut Self {
        self.call_number_display = call_number_display.into();
        self
    }

    pub fn with_call_number_browse_s(&mut self, call_number_browse_s: impl Into<String>) -> &mut Self {
        self.call_number_browse_s = call_number_browse_s.into();
        self
    }

    pub fn with_language_facet(&mut self, language_facet: impl Into<Vec<String>>) -> &mut Self {
        self.language_facet = language_facet.into();
        self
    }

    pub fn with_language_name_display(&mut self, language_name_display: impl Into<Vec<String>>) -> &mut Self {
        self.language_name_display = language_name_display.into();
        self
    }

    pub fn with_location(&mut self, location: impl Into<String>) -> &mut Self {
        self.location = Some(location.into());
        self
    }
    pub fn with_location_display(&mut self, location_display: impl Into<String>) -> &mut Self {
        self.location_display = Some(location_display.into());
        self
    }
    pub fn with_location_code_s(&mut self, location_code_s: impl Into<String>) -> &mut Self {
        self.location_code_s = Some(location_code_s.into());
        self
    }
    pub fn with_advanced_location_s(
        &mut self,
        advanced_location_s: impl Into<Vec<String>>,
    ) -> &mut Self {
        self.advanced_location_s = Some(advanced_location_s.into());
        self
    }
    pub fn with_access_facet(&mut self, access_facet: impl Into<String>) -> &mut Self {
        self.access_facet = Some(access_facet.into());
        self
    }
    pub fn with_holdings_1display(&mut self, holdings_1display: impl Into<String>) -> &mut Self {
        self.holdings_1display = Some(holdings_1display.into());
        self
    }
    pub fn with_electronic_portfolio_s(
        &mut self,
        electronic_portfolio_s: impl Into<String>,
    ) -> &mut Self {
        self.electronic_portfolio_s = Some(electronic_portfolio_s.into());
        self
    }
    pub fn with_class_year_s(&mut self, class_year_s: impl Into<Vec<String>>) -> &mut Self {
        self.class_year_s = Some(class_year_s.into());
        self
    }
    pub fn with_pub_date_start_sort(
        &mut self,
        pub_date_start_sort: impl Into<Vec<String>>,
    ) -> &mut Self {
        self.pub_date_start_sort = Some(pub_date_start_sort.into());
        self
    }
    pub fn with_pub_date_end_sort(
        &mut self,
        pub_date_end_sort: impl Into<Vec<String>>,
    ) -> &mut Self {
        self.pub_date_end_sort = Some(pub_date_end_sort.into());
        self
    }
    pub fn with_author_display(&mut self, author_display: impl Into<Vec<String>>) -> &mut Self {
        self.author_display = Some(author_display.into());
        self
    }
    pub fn with_author_s(&mut self, author_s: impl Into<String>) -> &mut Self {
        if self.author_s.is_none() {
            self.author_s = Some(Vec::new());
        }
        self.author_s.as_mut().unwrap().push(author_s.into());
        self
    }
    pub fn with_advisor_display(&mut self, advisor_display: impl Into<Vec<String>>) -> &mut Self {
        self.advisor_display = Some(advisor_display.into());
        self
    }
    pub fn with_contributor_display(
        &mut self,
        contributor_display: impl Into<Vec<String>>,
    ) -> &mut Self {
        self.contributor_display = Some(contributor_display.into());
        self
    }
    pub fn with_department_display(
        &mut self,
        department_display: impl Into<Vec<String>>,
    ) -> &mut Self {
        self.department_display = Some(department_display.into());
        self
    }
    pub fn with_certificate_display(
        &mut self,
        certificate_display: impl Into<Vec<String>>,
    ) -> &mut Self {
        self.certificate_display = Some(certificate_display.into());
        self
    }
    pub fn with_description_display(
        &mut self,
        description_display: impl Into<Vec<String>>,
    ) -> &mut Self {
        self.description_display = Some(description_display.into());
        self
    }
    pub fn with_summary_note_display(
        &mut self,
        summary_note_display: impl Into<Vec<String>>,
    ) -> &mut Self {
        self.summary_note_display = Some(summary_note_display.into());
        self
    }
    pub fn build(&self) -> SolrDocument {
        SolrDocument {
            id: self.id.clone(),
            title_t: self.title_t.clone(),
    title_citation_display: self.title_citation_display.clone(),
    title_display: self.title_display.clone(),
    title_sort: self.title_sort.clone(),
    author_sort: self.author_sort.clone(),
    electronic_access_1display: self.electronic_access_1display.clone(),
    restrictions_display_text: self.restrictions_display_text.clone(),
    call_number_display: self.call_number_display.clone(),
    call_number_browse_s: self.call_number_browse_s.clone(),
    language_facet: self.language_facet.clone(),
    language_name_display: self.language_name_display.clone(),
            format: "Senior thesis".to_owned(),
            location: self.location.clone(),
            location_display: self.location_display.clone(),
            location_code_s: self.location_code_s.clone(),
            advanced_location_s: self.advanced_location_s.clone(),
            access_facet: self.access_facet.clone(),
            holdings_1display: self.holdings_1display.clone(),
            electronic_portfolio_s: self.electronic_portfolio_s.clone(),
            class_year_s: self.class_year_s.clone(),
            pub_date_start_sort: self.pub_date_start_sort.clone(),
            pub_date_end_sort: self.pub_date_end_sort.clone(),
            author_display: self.author_display.clone(),
            author_s: self.author_s.clone(),
            advisor_display: self.advisor_display.clone(),
            contributor_display: self.contributor_display.clone(),
            department_display: self.department_display.clone(),
            certificate_display: self.certificate_display.clone(),
            description_display: self.description_display.clone(),
            summary_note_display: self.summary_note_display.clone(),
        }
    }
}

pub fn holding_access_string(
    location: bool,
    access_rights: bool,
    mudd_walkin: Option<Vec<String>>,
    class_year: Vec<String>,
    embargo_lift: Option<Vec<String>>,
    embargo_terms: Option<Vec<String>>,
    call_number_identifiers: Option<Vec<String>>,
) -> String {
    let mut builder = SolrDocument::builder();
    // TODO: Remove the clone, has_current_embargo should also (only?) accept references
    if embargo::has_current_embargo(embargo_lift.clone(), embargo_terms.clone()) {
        builder
            .with_location("Mudd Manuscript Library")
            .with_location_display("Mudd Manuscript Library")
            .with_location_code_s("mudd$stacks")
            .with_advanced_location_s(vec![
                "mudd$stacks".to_owned(),
                "Mudd Manuscript Library".to_owned(),
            ]);
    } else if holdings::on_site_only(
        location,
        access_rights,
        mudd_walkin,
        class_year,
        embargo_lift,
        embargo_terms,
    ) {
        builder
            .with_location("Mudd Manuscript Library")
            .with_location_display("Mudd Manuscript Library")
            .with_location_code_s("mudd$stacks")
            .with_advanced_location_s(vec![
                "mudd$stacks".to_owned(),
                "Mudd Manuscript Library".to_owned(),
            ])
            .with_access_facet("In the Library");
        if let Some(holdings_1display) = holdings::physical_holding_string(call_number_identifiers)
        {
            builder.with_holdings_1display(holdings_1display);
        }
    } else {
        builder.with_access_facet("Online");
        if let Some(electronic_portfolio_s) =
            holdings::online_holding_string(call_number_identifiers)
        {
            builder.with_electronic_portfolio_s(electronic_portfolio_s);
        }
    }
    serde_json::to_string(&builder.build()).unwrap_or_default()
}

pub fn class_year_fields(class_year: Option<Vec<String>>) -> String {
    let mut builder = SolrDocument::builder();
    if let Some(years) = class_year {
        if let Some(year) = years.first() {
            if year.chars().all(|c| c.is_numeric()) {
                builder
                    .with_class_year_s(vec![year.to_owned()])
                    .with_pub_date_start_sort(vec![year.to_owned()])
                    .with_pub_date_end_sort(vec![year.to_owned()]);
            }
        }
    }
    serde_json::to_string(&builder.build()).unwrap_or_default()
}

pub fn basic_fields(
    id: Option<String>,
    title_t: Option<String>,
    title_citation_display: Option<String>,
    title_display: Option<String>,
    title_sort: Option<String>,
    author_sort: Option<String>,
    electronic_access_1display: Option<String>,
    restrictions_display_text: Option<Vec<String>>,
    call_number_display: String,
    call_number_browse_s: String,
    language_facet: Vec<String>,
    language_name_display: Vec<String>,
) -> String {
    let mut builder = SolrDocument::builder();
    builder.with_call_number_display(call_number_display)
        .with_call_number_browse_s(call_number_browse_s)
        .with_language_facet(language_facet)
        .with_language_name_display(language_name_display);
    if let Some(value) = id { builder.with_id(value); }
    if let Some(value) = title_t { builder.with_title_t(value); }
    if let Some(value) = title_citation_display { builder.with_title_citation_display(value); }
    if let Some(value) = title_display { builder.with_title_display(value); }
    if let Some(value) = title_sort { builder.with_title_sort(value); }
    if let Some(value) = author_sort { builder.with_author_sort(value); }
    if let Some(value) = electronic_access_1display { builder.with_electronic_access_1display(value); }
    if let Some(value) = restrictions_display_text { builder.with_restrictions_display_text(value); }
    serde_json::to_string(&builder.build()).unwrap_or_default()
}

pub fn non_special_fields(
    author: Option<Vec<String>>,
    advisor: Option<Vec<String>>,
    contributor: Option<Vec<String>>,
    department: Option<Vec<String>>,
    certificate: Option<Vec<String>>,
    extent: Option<Vec<String>>,
    description_abstract: Option<Vec<String>>,
) -> String {
    let mut builder = SolrDocument::builder();

    // Mapping implementation
    if let Some(val) = author {
        builder.with_author_display(val.clone());
        val.iter().for_each(|value| {
            builder.with_author_s(value);
        });
    }
    if let Some(val) = advisor {
        builder.with_advisor_display(val.clone());
        val.iter().for_each(|value| {
            builder.with_author_s(value);
        });
    }
    if let Some(val) = contributor {
        builder.with_contributor_display(val.clone());
        val.iter().for_each(|value| {
            builder.with_author_s(value);
        });
    }
    if let Some(val) = department {
        builder.with_department_display(val.clone());
        val.iter().for_each(|value| {
            builder.with_author_s(value);
        });
    }
    if let Some(val) = certificate {
        builder.with_certificate_display(val.clone());
        val.iter().for_each(|value| {
            builder.with_author_s(value);
        });
    }
    if let Some(val) = extent {
        builder.with_description_display(val);
    }
    if let Some(val) = description_abstract {
        builder.with_summary_note_display(val);
    }

    serde_json::to_string(&builder.build()).unwrap_or_default()
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
            .with_location("Mudd Manuscript Library")
            .build();
        assert_eq!(document.location.unwrap(), "Mudd Manuscript Library");
    }
}
