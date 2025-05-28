use crate::ephemera::ephemera_item::EphemeraItem;

use super::SolrDocument;

impl From<&EphemeraItem> for SolrDocument {
    fn from(value: &EphemeraItem) -> Self {
        SolrDocument::builder()
            .with_title_citation_display(value.title.first().cloned())
            .with_alternative_title_display(value.alternative_title_display.clone())
            .build()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_has_alternative_title_display() {
        // let document = EphemeraItem{id: "af4a941d-96a4-463e-9043-cfa512e5eddd".to_string(), title: vec!["title1".to_string()], alternative_title_display: None, transliterated_title_display: Some(vec!["test title display".to_string()])};
        let document = EphemeraItem::builder()
            .id("af4a941d-96a4-463e-9043-cfa512e5eddd".to_string())
            .title(vec!["title1".to_string()])
            .alternative_title_display(vec!["alternativeTestTitle".to_string()])
            .transliterated_title_display(vec!["test title display".to_string()])
            .build()
            .unwrap();
        let solr = SolrDocument::from(&document);
        assert_eq!(
            solr.alternative_title_display,
            Some(vec!["alternativeTestTitle".to_string()])
        );
    }
}
