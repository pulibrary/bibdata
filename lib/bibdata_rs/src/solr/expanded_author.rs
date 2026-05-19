// This module is responsible for creating a field with the author and any related 880 field

use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Default, Deserialize, PartialEq, Serialize)]
pub struct ExpandedAuthor {
    pub author: Option<Vec<String>>,
}
