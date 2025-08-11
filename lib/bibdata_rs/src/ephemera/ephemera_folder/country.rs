use serde::Deserialize;

#[derive(Clone, Deserialize, Debug)]
pub struct ExactMatch {
    #[serde(rename = "@id")]
    pub id: String,
}

impl ExactMatch {
    pub fn accepted_vocabulary(&self) -> bool {
        self.id
            .starts_with("http://id.loc.gov/vocabulary/countries/")
    }
}
