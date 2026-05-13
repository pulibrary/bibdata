use crate::marc::control_field::control_number::ControlNumber;
use figgy_marc::{FiggyMmsIdCache, ark_eq, iiif_manifest_url};
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

/// Returns a manifest url for the provided ark if the cached MMS ID report contains it
pub fn manifest_url<'a>(ark: &str, cache: Option<&'a FiggyMmsIdCache>) -> Option<&'a str> {
    let cache = cache.unwrap_or_else(|| &FIGGY_MMS_REPORT_CACHE);
    cache
        .values()
        .filter_map(|items| items.iter().find(|item| ark_eq(ark, item)))
        .next()
        .and_then(|item| iiif_manifest_url(item))
}

#[cfg(test)]
mod tests {
    use super::*;
    use serde_json::json;
    use std::collections::HashMap;

    #[test]
    fn it_can_get_manifest_url_given_an_ark() {
        let cache: FiggyMmsIdCache = HashMap::from([
            (
                String::from("9965054633506421"),
                vec![
                    json!({"ark":"http://arks.princeton.edu/ark:/88435/dc08613099f","iiif_manifest_url":"https://figgy.princeton.edu/concern/scanned_resources/4abf0d8c-a64a-4422-a3f4-229fd9b3b28d/manifest","label":{"@value":"Stress Analysis of Coil Support Frames for B-3 Machine.","@language":"en"},"portion_note":null,"visibility":{"value":"open","label":"open","definition":"Open to the world. Anyone can view."}}),
                ],
            ),
            (
                String::from("99100829483506421"),
                vec![
                    json!({"ark":"http://arks.princeton.edu/ark:/88435/dc5425km496","iiif_manifest_url":"https://figgy.princeton.edu/concern/scanned_resources/f4930df2-d7be-4997-87fd-ac429a23084a/manifest","label":{"@value":"Самые большие / С. Федорченко ; рисунки Ю Пименова.","@language":"ru"},"portion_note":null,"visibility":{"value":"open","label":"open","definition":"Open to the world. Anyone can view."}}),
                ],
            ),
        ]);

        assert_eq!(
            manifest_url(
                "http://arks.princeton.edu/ark:/88435/dc08613099f",
                Some(&cache)
            ),
            Some(
                "https://figgy.princeton.edu/concern/scanned_resources/4abf0d8c-a64a-4422-a3f4-229fd9b3b28d/manifest"
            )
        );

        assert_eq!(
            manifest_url(
                "http://arks.princeton.edu/ark:/88435/dc5425km496",
                Some(&cache)
            ),
            Some(
                "https://figgy.princeton.edu/concern/scanned_resources/f4930df2-d7be-4997-87fd-ac429a23084a/manifest"
            )
        );

        assert_eq!(
            manifest_url("not an ark, just some invalid data", Some(&cache)),
            None
        );
    }
}
