pub use super::SolrDocument;
use anyhow::Result;
use reqwest::header::CONTENT_TYPE;

pub fn index(solr_url: &str, documents: &[SolrDocument]) -> Result<()> {
    let client = reqwest::blocking::Client::new();
    let commit_url = format!("{solr_url}/update?commit=true");
    client
        .post(&commit_url)
        .body(serde_json::to_string(documents)?)
        .header(CONTENT_TYPE, "application/json")
        .send()?;
    Ok(())
}

pub fn index_string(solr_url: String, documents: String) {
    let document_vec: Vec<SolrDocument> =
        serde_json::from_str(&documents).expect("Failed to parse documents from JSON string");
    index(&solr_url, &document_vec).expect("Failed to index documents");
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

        let solr_url = format!("{}/solr/{collection}", &server.url());
        index(&solr_url, &[document]).unwrap();

        solr_mock.assert();
    }
}
