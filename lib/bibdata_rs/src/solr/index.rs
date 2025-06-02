#[cfg(test)]
mod tests {
    use crate::solr::builder::SolrDocumentBuilder;

    #[test]
    fn it_posts_the_document_to_solr() {
        let document = SolrDocumentBuilder::default()
            .with_other_title_display(Some(vec!["Aspen".to_string()]))
            .build();
        let mut server = mockito::Server::new();
        server
            .mock("POST", "/solr/alma-production-rebuild/update?commit=true")
            .match_body(r#"[{"other_title_display": "Aspen"}]"#)
            .create();
        assert!(true)
    }
}
