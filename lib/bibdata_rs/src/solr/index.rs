pub use super::SolrDocument;
use anyhow::Result;

pub fn index(domain: &str, collection: &str, documents: &[SolrDocument]) -> Result<()> {
    let client = reqwest::blocking::Client::new();
    client
        .post(format!("{}/solr/{}/update?commit=true", domain, collection))
        .body(serde_json::to_string(documents)?)
        .send()?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::solr::builder::SolrDocumentBuilder;

    #[test]
    fn it_posts_the_document_to_solr() {
        let document = SolrDocumentBuilder::default()
            .with_other_title_display(Some(vec!["Aspen".to_string()]))
            .build();
        let mut server = mockito::Server::new();
        let collection = "alma-production-rebuild";
        let solr_mock = server
            .mock(
                "POST",
                format!("/solr/{}/update?commit=true", collection).as_str(),
            )
            .match_request(|request| {
                // Confirm that the body of the request is valid JSON with "Aspen" in the other_title_display field
                let request_documents: Vec<SolrDocument> =
                    serde_json::from_str(&request.utf8_lossy_body().unwrap()).unwrap();
                request_documents[0].other_title_display == Some(vec!["Aspen".to_string()])
            })
            .create();

        index(&server.url(), collection, &[document]).unwrap();

        solr_mock.assert();
    }
}
