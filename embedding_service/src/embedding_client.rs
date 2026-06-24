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
            .with_body(r#"{"embedding":[0.108879,-0.021541,0.076476,0.036891,0.052652,-0.020828,-0.03946]}"#)
            .create();

        let client = EmbeddingClient::new(server.url());
        let embedding = client.get_embedding("aspen is the best").unwrap();
        assert_eq!(
            embedding,
            vec![
                0.108879, -0.021541, 0.076476, 0.036891, 0.052652, -0.020828, -0.03946
            ]
        );
        mock.assert();
    }
}
