use serde::Deserialize;

#[derive(Clone, Deserialize, Debug)]
pub struct ExactMatch {
    #[serde(rename = "@id")]
    pub id: Id,
}

#[derive(Clone, Deserialize, Debug)]
pub struct Id {
    #[serde(rename = "@id")]
    pub id: String,
}
impl Id {
    pub fn country_ids(&self) -> anyhow::Result<Vec<String>> {
        let v: Vec<String> = serde_json::from_str(&self.id)?;
        Ok(v)
    }
}

impl ExactMatch {
    pub fn accepted_vocabulary(&self) -> bool {
        match &self.id.country_ids() {
            Ok(s)
                if s.iter()
                    .any(|url| url.starts_with("http://id.loc.gov/vocabulary/countries/")) =>
            {
                true
            }
            _ => false,
        }
    }
}
