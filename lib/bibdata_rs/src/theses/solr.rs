use crate::theses::{embargo, holdings};
use serde::Serialize;

#[derive(Debug, Default, Serialize)]
struct SolrDocument {
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
}

impl SolrDocument {
    pub fn builder() -> SolrDocumentBuilder {
        SolrDocumentBuilder::default()
    }
}

#[derive(Default)]
struct SolrDocumentBuilder {
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
}
impl SolrDocumentBuilder {
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
    pub fn with_pub_date_start_sort(&mut self, pub_date_start_sort: impl Into<Vec<String>>) -> &mut Self {
        self.pub_date_start_sort = Some(pub_date_start_sort.into());
        self
    }
    pub fn with_pub_date_end_sort(&mut self, pub_date_end_sort: impl Into<Vec<String>>) -> &mut Self {
        self.pub_date_end_sort = Some(pub_date_end_sort.into());
        self
    }
    pub fn build(&self) -> SolrDocument {
        SolrDocument {
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
                builder.with_class_year_s(vec![year.to_owned()])
                    .with_pub_date_start_sort(vec![year.to_owned()])
                    .with_pub_date_end_sort(vec![year.to_owned()]);
            }    
        }
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
    }

    #[test]
    fn test_build_a_solr_document_with_location() {
        let document = SolrDocument::builder()
            .with_location("Mudd Manuscript Library")
            .build();
        assert_eq!(document.location.unwrap(), "Mudd Manuscript Library");
    }
}
