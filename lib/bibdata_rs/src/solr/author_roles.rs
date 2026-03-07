// This module is responsible for creating a JSON formatted list of authors
// and their roles.

use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Default, Deserialize, PartialEq, Serialize)]
pub struct AuthorRoles {
    #[serde(skip_serializing_if = "Option::is_none")]
    pub primary_author: Option<String>,
    pub secondary_authors: Vec<String>,
    pub translators: Vec<String>,
    pub editors: Vec<String>,
    pub compilers: Vec<String>,
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_serializes_correctly() {
        assert_eq!(
            serde_json::to_string(&AuthorRoles::default()).unwrap(),
            r#"{"secondary_authors":[],"translators":[],"editors":[],"compilers":[]}"#
        );
        assert_eq!(
            serde_json::to_string(&AuthorRoles {
                primary_author: Some("Ginger".to_owned()),
                ..Default::default()
            })
            .unwrap(),
            r#"{"primary_author":"Ginger","secondary_authors":[],"translators":[],"editors":[],"compilers":[]}"#
        );
        assert_eq!(
            serde_json::to_string(&AuthorRoles {
                primary_author: Some("Ginger".to_owned()),
                compilers: vec!["Galangal".to_owned()],
                ..Default::default()
            })
            .unwrap(),
            r#"{"primary_author":"Ginger","secondary_authors":[],"translators":[],"editors":[],"compilers":["Galangal"]}"#
        );
        assert_eq!(
            serde_json::to_string(&AuthorRoles {
                secondary_authors: vec!["Cardamom".to_owned(), "Turmeric".to_owned()],
                ..Default::default()
            })
            .unwrap(),
            r#"{"secondary_authors":["Cardamom","Turmeric"],"translators":[],"editors":[],"compilers":[]}"#
        );
    }
}
