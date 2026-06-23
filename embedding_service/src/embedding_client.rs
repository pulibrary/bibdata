use std::io;

use reqwest::Url;
pub struct EmbeddingClient {
    url: String,
}

impl EmbeddingClient {
    pub fn new(url: String) -> Self {
        EmbeddingClient { url }
    }
    pub fn get_embedding(&self, text: &str) -> Result<Vec<f64>, Box<dyn std::error::Error>> {
        let mut url = Url::parse(&self.url)?;
        url.path_segments_mut()
            .map_err(|_| "Cannot modify URL path segments")?
            .push("embedding");

        let client = reqwest::blocking::Client::new();
        let response = client
            .post(url)
            .json(&serde_json::json!({ "text": text }))
            .send()?
            .error_for_status()?;
        // let response1 = reqwest::blocking::get(url)?;
        // eprintln!("Response: {:?}", response1.text());

        let json: serde_json::Value = response.json()?;
        let embedding = json["embedding"]
            .as_array()
            .ok_or_else(|| {
                io::Error::new(
                    io::ErrorKind::InvalidData,
                    format!(
                        "Expected 'embedding' to be an array, got: {}",
                        json["embedding"]
                    ),
                )
            })?
            .iter()
            .map(|v| {
                v.as_f64()
                    .ok_or("Expected embedding values to be floats")
                    .map(|i| i as f64)
            })
            .collect::<Result<Vec<f64>, _>>()?;
        Ok(embedding)
    }
}
pub fn get_embedding(text: String) -> Result<Vec<f64>, magnus::Error> {
    let base_url = std::env::var("EMBEDDING_SERVICE_URL")
        .unwrap_or_else(|_| "http://localhost:8000".to_string());
    let client = EmbeddingClient::new(base_url);
    client.get_embedding(&text).map_err(|error| {
        magnus::Error::new(
            unsafe { magnus::Ruby::get_unchecked() }.exception_runtime_error(),
            error.to_string(),
        )
    })
}

#[cfg(test)]

mod tests {
    use super::*;

    #[test]
    fn it_gets_an_embedding_for_text() {
        let mut server = mockito::Server::new();
        let mock = server.mock("POST", "/embedding")
            .match_body(r#"{"text":"aspen is the best"}"#)
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body(r#"{"embedding":[-0.03072148561477661,0.0025953894946724176,-0.01963762193918228,-0.04897492006421089,-0.07700270414352417,-0.01809978112578392,0.09056542068719864,-0.008020268753170967,0.03081989660859108,-0.005157603416591883,-0.002370256930589676,-0.07629439979791641,-0.03276306390762329,0.03974098339676857,0.0013087878469377756,-0.023633986711502075,-0.056400369852781296,-0.11435861140489578,-0.005043743643909693,-0.04609031602740288,0.046932004392147064,-0.13379953801631927,0.04509463161230087,0.02285894565284252]}"#)
            .create();

        let client = EmbeddingClient::new(server.url());
        let embedding = client.get_embedding("aspen is the best").unwrap();
        assert_eq!(
            embedding,
            vec![
                -0.03072148561477661,0.0025953894946724176,-0.01963762193918228,-0.04897492006421089,-0.07700270414352417,-0.01809978112578392,0.09056542068719864,-0.008020268753170967,0.03081989660859108,-0.005157603416591883,-0.002370256930589676,-0.07629439979791641,-0.03276306390762329,0.03974098339676857,0.0013087878469377756,-0.023633986711502075,-0.056400369852781296,-0.11435861140489578,-0.005043743643909693,-0.04609031602740288,0.046932004392147064,-0.13379953801631927,0.04509463161230087,0.02285894565284252
            ]
        );
        mock.assert();
    }
}
