use crate::marc::control_field::control_number::ControlNumber;
use figgy_marc::FiggyMmsIdCache;
use marctk::Record;
use std::sync::LazyLock;

static FIGGY_MMS_REPORT_CACHE: LazyLock<FiggyMmsIdCache> =
    LazyLock::new(figgy_marc::redis_cache::read);

pub fn figgy_1display(record: &Record) -> Option<String> {
    match ControlNumber::from(record) {
        ControlNumber::Alma(mms_id) => FIGGY_MMS_REPORT_CACHE
            .get(mms_id)
            .and_then(|figgy_items| serde_json::to_string(figgy_items).ok()),
        _ => None,
    }
}
