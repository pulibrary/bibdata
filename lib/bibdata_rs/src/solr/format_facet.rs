use serde::{Deserialize, Deserializer, Serialize};
use std::{fmt::Display, str::FromStr};

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

// When we provide a format facet to Ruby, it must be provided as a String.
// Implementing Display allows us to map FormatFacet values to Strings so
// that Ruby can access them.
impl Display for FormatFacet {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            Self::ArchivalItem => write!(f, "Archival item"),
            Self::DataFile => write!(f, "Data file"),
            Self::MusicalScore => write!(f, "Musical score"),
            Self::SeniorThesis => write!(f, "Senior thesis"),
            Self::VideoProjectedMedium => write!(f, "Video/Projected medium"),
            Self::VisualMaterial => write!(f, "Visual material"),
            _ => write!(f, "{:?}", self),
        }
    }
}

#[derive(Debug)]
pub struct NoFormatMatches;

impl FromStr for FormatFacet {
    type Err = NoFormatMatches;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        let s_lower = s.to_lowercase();
        match s_lower.as_str() {
            "advertisements" => Ok(Self::Book),
            "audio recordings" => Ok(Self::Audio),
            "bags" => Ok(Self::Book),
            "banners" => Ok(Self::Book),
            "booklets" => Ok(Self::Book),
            "bookmarks" => Ok(Self::Book),
            "book" => Ok(Self::Book),
            "books" => Ok(Self::Book),
            "brochures" => Ok(Self::Book),
            "business cards" => Ok(Self::Book),
            "buttons" => Ok(Self::Book),
            "calendars" => Ok(Self::Book),
            "caricatures" => Ok(Self::Book),
            "correspondence" => Ok(Self::Book),
            "court decisions and opinions" => Ok(Self::Coin),
            "data files" => Ok(Self::DataFile),
            "electoral paraphernalia" => Ok(Self::Book),
            "ephemera" => Ok(Self::Book),
            "fans" => Ok(Self::Book),
            "flags" => Ok(Self::Book),
            "flyers" => Ok(Self::Book),
            "forms" => Ok(Self::Book),
            "games" => Ok(Self::Book),
            "headscarves" => Ok(Self::VisualMaterial),
            "leaflets" => Ok(Self::Book),
            "magnets" => Ok(Self::VisualMaterial),
            "manuscripts" => Ok(Self::Manuscript),
            "maps" => Ok(Self::Map),
            "masks" => Ok(Self::Book),
            "montages" => Ok(Self::Book),
            "new clippings" => Ok(Self::Book),
            "newsletters" => Ok(Self::Book),
            "newspapers" => Ok(Self::Journal),
            "paintings" => Ok(Self::VisualMaterial),
            "pamphlets" => Ok(Self::Book),
            "pedagogical materials" => Ok(Self::Book),
            "pennants" => Ok(Self::Book),
            "periodical" => Ok(Self::Journal),
            "photographs" => Ok(Self::VisualMaterial),
            "picket signs" => Ok(Self::Book),
            "posters" => Ok(Self::VisualMaterial),
            "postcards" => Ok(Self::Book),
            "reports" => Ok(Self::Report),
            "serials" => Ok(Self::Journal),
            "series" => Ok(Self::Book),
            "stickers" => Ok(Self::Book),
            "t-shirts" => Ok(Self::Book),
            "video recordings" => Ok(Self::VideoProjectedMedium),
            "senior thesis" => Ok(Self::SeniorThesis),
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
        assert_eq!(
            FormatFacet::from_str("Pamphlets").unwrap(),
            FormatFacet::Book
        );
        assert_eq!(
            FormatFacet::from_str("Calendars").unwrap(),
            FormatFacet::Book
        );
        assert_eq!(
            FormatFacet::from_str("Audio recordings").unwrap(),
            FormatFacet::Audio
        );
        assert_eq!(
            FormatFacet::from_str("Video recordings").unwrap(),
            FormatFacet::VideoProjectedMedium
        );
        assert_eq!(
            FormatFacet::from_str("Serials").unwrap(),
            FormatFacet::Journal
        );
    }
}
