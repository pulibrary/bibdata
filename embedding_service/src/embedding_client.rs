use reqwest::Url;
pub struct EmbeddingClient {
    url: String,
}

impl EmbeddingClient {
    pub fn new(url: String) -> Self {
        EmbeddingClient { url }
    }

    pub fn get_embedding(&self, text: &str) -> Result<Vec<i32>, Box<dyn std::error::Error>> {
        let mut url = Url::parse(&self.url)?;
        url.path_segments_mut()
            .map_err(|_| "Cannot modify URL path segments")?
            .push("embedding")
            .push(text);
        let response = reqwest::blocking::get(url)?;
        let json: serde_json::Value = response.json()?;
        let embedding = json["embedding"]
            .as_array()
            .ok_or("Expected 'embedding' to be an array")?
            .iter()
            .map(|v| {
                v.as_i64()
                    .ok_or("Expected embedding values to be integers")
                    .map(|i| i as i32)
            })
            .collect::<Result<Vec<i32>, _>>()?;
        Ok(embedding)
    }
}
pub fn get_embedding(text: String) -> Result<Vec<i32>, magnus::Error> {
    let base_url = std::env::var("EMBEDDING_SERVICE_URL").map_err(|e| {
        magnus::Error::new(
            unsafe { magnus::Ruby::get_unchecked() }.exception_runtime_error(),
            format!("EMBEDDING_SERVICE_URL is not set: {}", e),
        )
    })?;
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
        let mock = server.mock("GET", "/embedding/aspen%20is%20the%20best")
            .with_status(200)
            .with_header("content-type", "application/json")
            .with_body(r#"{"embedding":[-101,124,-96,22,-18,70,-59,-16,80,-54,95,40,-6,-85,-63,-11,84,29,-22,37,-57,-46,35,-72,97,-41,122,-59,-28,-36,23,-54,8,-40,26,-111,-38,45,54,-14,-96,-35,-77,61,-49,98,122,-12,19,1,64,-104,116,106,14,75,-33,124,80,118,125,79,-83,125,-37,54,-19,-28,42,-108,122,84,-42,-32,74,2,118,102,-36,85,-99,20,0,118,-14,-17,51,103,-51,48,-102,-76,18,-30,96,51]}"#)
            .create();

        let client = EmbeddingClient::new(server.url());
        let embedding = client.get_embedding("aspen is the best").unwrap();
        assert_eq!(
            embedding,
            vec![
                -101, 124, -96, 22, -18, 70, -59, -16, 80, -54, 95, 40, -6, -85, -63, -11, 84, 29,
                -22, 37, -57, -46, 35, -72, 97, -41, 122, -59, -28, -36, 23, -54, 8, -40, 26, -111,
                -38, 45, 54, -14, -96, -35, -77, 61, -49, 98, 122, -12, 19, 1, 64, -104, 116, 106,
                14, 75, -33, 124, 80, 118, 125, 79, -83, 125, -37, 54, -19, -28, 42, -108, 122, 84,
                -42, -32, 74, 2, 118, 102, -36, 85, -99, 20, 0, 118, -14, -17, 51, 103, -51, 48,
                -102, -76, 18, -30, 96, 51
            ]
        );
        mock.assert();
    }
}
