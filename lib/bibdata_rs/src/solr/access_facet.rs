use serde::{Deserialize, Serialize};

#[derive(Clone, Copy, Debug, Deserialize, PartialEq, Serialize)]
pub enum AccessFacet {
    #[serde(rename = "In the Library")]
    InTheLibrary,
    Online,
}
