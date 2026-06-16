use reqwest;

pub struct EmbeddingServiceClient {
    url: String,
}

impl EmbeddingServiceClient {
    pub fn new(url: String) -> Self {
        EmbeddingServiceClient { url }
    }

    pub fn get_embedding(&self, text: &str) -> Result<Vec<i32>, Box<dyn std::error::Error>> {
        let url = format!("{}/embedding/{}", self.url, text);
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

        let client = EmbeddingServiceClient::new(server.url());
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
