// This module is responsible for creating a JSON formatted list of authors
// and their roles.

use serde::{Deserialize, Serialize};
use std::fmt::Display;

#[derive(Clone, Debug, Default, Deserialize, PartialEq)]
pub struct AuthorRoles {
    pub primary_author: Option<String>,
    pub secondary_authors: Vec<String>,
    pub translators: Vec<String>,
    pub editors: Vec<String>,
    pub compilers: Vec<String>,
}

/// Serialize the author roles to be a json string, with all the necessary escaping
impl Serialize for AuthorRoles {
    fn serialize<S>(&self, serializer: S) -> Result<S::Ok, S::Error>
    where
        S: serde::Serializer,
    {
        serializer.serialize_str(&self.to_string())
    }
}

/// Serialize the author roles to be a regular string, with no JSON escaping
impl Display for AuthorRoles {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        let mut hash = serde_json::Map::new();
        let cloned = self.clone();
        if let Some(primary) = cloned.primary_author {
            hash.insert(String::from("primary_author"), primary.into());
        }
        hash.insert(
            String::from("secondary_authors"),
            cloned.secondary_authors.into(),
        );
        hash.insert(String::from("translators"), cloned.translators.into());
        hash.insert(String::from("editors"), cloned.editors.into());
        hash.insert(String::from("compilers"), cloned.compilers.into());
        if let Ok(str) = serde_json::to_string(&hash) {
            f.write_str(&str)
        } else {
            Ok(())
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_serializes_correctly() {
        assert_eq!(
            serde_json::to_string(&AuthorRoles::default()).unwrap(),
            r#""{\"secondary_authors\":[],\"translators\":[],\"editors\":[],\"compilers\":[]}""#
        );
        assert_eq!(
            serde_json::to_string(&AuthorRoles {
                primary_author: Some("Ginger".to_owned()),
                ..Default::default()
            })
            .unwrap(),
            r#""{\"primary_author\":\"Ginger\",\"secondary_authors\":[],\"translators\":[],\"editors\":[],\"compilers\":[]}""#
        );
        assert_eq!(
            serde_json::to_string(&AuthorRoles {
                primary_author: Some("Ginger".to_owned()),
                compilers: vec!["Galangal".to_owned()],
                ..Default::default()
            })
            .unwrap(),
            r#""{\"primary_author\":\"Ginger\",\"secondary_authors\":[],\"translators\":[],\"editors\":[],\"compilers\":[\"Galangal\"]}""#
        );
        assert_eq!(
            serde_json::to_string(&AuthorRoles {
                secondary_authors: vec!["Cardamom".to_owned(), "Turmeric".to_owned()],
                ..Default::default()
            })
            .unwrap(),
            r#""{\"secondary_authors\":[\"Cardamom\",\"Turmeric\"],\"translators\":[],\"editors\":[],\"compilers\":[]}""#
        );
    }
}
