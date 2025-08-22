use crate::solr;
use serde::Deserialize;

use serde::Serialize;

#[derive(Clone, Debug, Serialize, Deserialize, PartialEq)]
pub struct ElectronicAccess {
    pub electronic_access: Option<solr::ElectronicAccess>,
}
