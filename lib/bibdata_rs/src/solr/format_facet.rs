use serde::{Deserialize, Deserializer, Serialize};
use std::str::FromStr;

#[allow(dead_code)]
#[derive(Copy, Clone, Debug, Serialize, PartialEq)]
pub enum FormatFacet {
    #[serde(rename = "Archival item")]
    ArchivalItem,
    Audio,
    Book,
    Coin,
    #[serde(rename = "Data file")]
    DataFile,
    Databases,
    Journal,
    Manuscript,
    Map,
    Microform,
    #[serde(rename = "Musical score")]
    MusicalScore,
    Report,
    #[serde(rename = "Senior thesis")]
    SeniorThesis,
    #[serde(rename = "Video/Projected medium")]
    VideoProjectedMedium,
    #[serde(rename = "Visual material")]
    VisualMaterial,
}

#[derive(Debug)]
pub struct NoFormatMatches;

impl FromStr for FormatFacet {
    type Err = NoFormatMatches;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "Book" => Ok(Self::Book),
            "Books" => Ok(Self::Book),
            "Reports" => Ok(Self::Report),
            "Serials" => Ok(Self::Journal),
            "Senior thesis" => Ok(Self::SeniorThesis),
            _ => Err(NoFormatMatches),
        }
    }
}

impl<'de> Deserialize<'de> for FormatFacet {
    fn deserialize<D>(deserializer: D) -> Result<Self, D::Error>
    where
        D: Deserializer<'de>,
    {
        let s = String::deserialize(deserializer)?;
        FromStr::from_str(&s).map_err(|_err| {
            serde::de::Error::invalid_value(
                serde::de::Unexpected::Str(&s),
                &"a valid catalog format",
            )
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_serializes() {
        assert_eq!(
            serde_json::to_string(&FormatFacet::ArchivalItem).unwrap(),
            r#""Archival item""#
        );
        assert_eq!(
            serde_json::to_string(&FormatFacet::DataFile).unwrap(),
            r#""Data file""#
        );
        assert_eq!(
            serde_json::to_string(&FormatFacet::MusicalScore).unwrap(),
            r#""Musical score""#
        );
        assert_eq!(
            serde_json::to_string(&FormatFacet::SeniorThesis).unwrap(),
            r#""Senior thesis""#
        );
        assert_eq!(
            serde_json::to_string(&FormatFacet::VideoProjectedMedium).unwrap(),
            r#""Video/Projected medium""#
        );
        assert_eq!(
            serde_json::to_string(&FormatFacet::VisualMaterial).unwrap(),
            r#""Visual material""#
        );
    }

    #[test]
    fn it_can_be_created_from_str() {
        assert_eq!(FormatFacet::from_str("Books").unwrap(), FormatFacet::Book);
        assert_eq!(
            FormatFacet::from_str("Reports").unwrap(),
            FormatFacet::Report
        );
        assert_eq!(
            FormatFacet::from_str("Serials").unwrap(),
            FormatFacet::Journal
        );
    }
}
