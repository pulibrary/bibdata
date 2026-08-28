use crate::marc::control_field::control_number::ControlNumber;
use figgy_marc::{FiggyMmsIdCache, ark_eq, iiif_manifest_url};
use marctk::Record;
use serde_json::Value;
use std::sync::LazyLock;

static FIGGY_MMS_REPORT_CACHE: LazyLock<FiggyMmsIdCache> =
    LazyLock::new(figgy_marc::redis_cache::read);

pub fn figgy_1display<M>(
    record: &Record,
    cache: Option<&LazyLock<FiggyMmsIdCache>>,
    modify_items: M,
) -> Option<String>
where
    M: Fn(&Vec<Value>, &Record) -> Vec<Value>,
{
    let figgy_cache = cache.unwrap_or_else(|| &FIGGY_MMS_REPORT_CACHE);

    match ControlNumber::from(record) {
        ControlNumber::Alma(mms_id) => figgy_cache
            .get(mms_id)
            .map(|figgy_items| modify_items(figgy_items, &record))
            .and_then(|figgy_items| serde_json::to_string(&figgy_items).ok()),
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

/// Returns the MMS ID that matches the provided ark
pub fn mms_id<'a>(ark: &str, cache: Option<&'a FiggyMmsIdCache>) -> Option<&'a str> {
    let cache = cache.unwrap_or_else(|| &FIGGY_MMS_REPORT_CACHE);
    cache
        .iter()
        .find(|(_mms_id, items)| items.iter().any(|item| ark_eq(ark, item)))
        .map(|(mms_id, _items)| mms_id.as_str())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::marc::record_facet_mapping::formats;
    use crate::marc::utils::display_format::display_format;
    use serde_json::json;
    use std::collections::HashMap;

    static SMALL_CACHE: LazyLock<FiggyMmsIdCache> = LazyLock::new(|| {
        HashMap::from([
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
        ])
    });

    #[test]
    fn it_can_get_manifest_url_given_an_ark() {
        assert_eq!(
            manifest_url(
                "http://arks.princeton.edu/ark:/88435/dc08613099f",
                Some(&SMALL_CACHE)
            ),
            Some(
                "https://figgy.princeton.edu/concern/scanned_resources/4abf0d8c-a64a-4422-a3f4-229fd9b3b28d/manifest"
            )
        );

        assert_eq!(
            manifest_url(
                "http://arks.princeton.edu/ark:/88435/dc5425km496",
                Some(&SMALL_CACHE)
            ),
            Some(
                "https://figgy.princeton.edu/concern/scanned_resources/f4930df2-d7be-4997-87fd-ac429a23084a/manifest"
            )
        );

        assert_eq!(
            manifest_url("not an ark, just some invalid data", Some(&SMALL_CACHE)),
            None
        );
    }

    #[test]
    fn it_can_get_mms_id_given_an_ark() {
        assert_eq!(
            mms_id(
                "http://arks.princeton.edu/ark:/88435/dc08613099f",
                Some(&SMALL_CACHE)
            ),
            Some("9965054633506421")
        );

        assert_eq!(
            mms_id(
                "http://arks.princeton.edu/ark:/88435/dc5425km496",
                Some(&SMALL_CACHE)
            ),
            Some("99100829483506421")
        );

        assert_eq!(
            mms_id("not an ark, just some invalid data", Some(&SMALL_CACHE)),
            None
        );
    }

    #[test]
    fn it_renders_full_json() {
        let record = Record::from_breaker(
            "=LDR 02190cdm a2200385 i 4500
=001 9965054633506421
=008 911219d19912007ohufr-p-------0---a0eng-c
=260 \\ $aCincinnati, Ohio : $bAmerican Drama Institute,$cc1991-",
        )
        .unwrap();

        assert_eq!(
            figgy_1display(&record, Some(&SMALL_CACHE), |figgy_items, record| {
                figgy_items.iter().map(|figgy_item| {
                    let mut item = figgy_item.as_object().unwrap().clone();
                    let format = display_format(formats(record));
                    item.insert("display_format".to_owned(), json!(format));
                    serde_json::to_value(item).unwrap()
                }).collect::<Vec<Value>>()
                
            }).unwrap(),
            "[{\"ark\":\"http://arks.princeton.edu/ark:/88435/dc08613099f\",\"iiif_manifest_url\":\"https://figgy.princeton.edu/concern/scanned_resources/4abf0d8c-a64a-4422-a3f4-229fd9b3b28d/manifest\",\"label\":{\"@value\":\"Stress Analysis of Coil Support Frames for B-3 Machine.\",\"@language\":\"en\"},\"portion_note\":null,\"visibility\":{\"value\":\"open\",\"label\":\"open\",\"definition\":\"Open to the world. Anyone can view.\"},\"display_format\":\"Manuscript\"}]".to_owned()
        )
    }
}
