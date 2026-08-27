use crate::solr::FormatFacet::*;
use crate::solr::format_facet::Abbreviation;

// Choses an abbreviated display format given a vector of formats
// this is intended for displaying compact badges inline with search results
pub fn display_format(formats: Vec<String>) -> String {
    match formats {
        _ if formats.contains(&"Microform".to_string()) => Microform.abbreviation(),
        _ if formats.contains(&"Manuscript".to_string()) => Manuscript.abbreviation(),
        _ if formats.contains(&"Data file".to_string()) => DataFile.abbreviation(),
        _ if formats.contains(&"Musical score".to_string()) => MusicalScore.abbreviation(),
        _ if formats.contains(&"Senior thesis".to_string()) => SeniorThesis.abbreviation(),
        _ if formats.contains(&"Archival item".to_string()) => ArchivalItem.abbreviation(),
        _ if formats.contains(&"Video/Projected medium".to_string()) => VideoProjectedMedium.abbreviation(),
        _ if formats.contains(&"Visual material".to_string()) => VisualMaterial.abbreviation(),
        _ if formats.contains(&"Map".to_string()) => Map.abbreviation(),
        _ if formats.contains(&"Report".to_string()) => Report.abbreviation(),
        _ if formats.contains(&"Coin".to_string()) => Coin.abbreviation(),
        _ if formats.contains(&"Databases".to_string()) => Databases.abbreviation(),
        _ if formats.contains(&"Audio".to_string()) => Audio.abbreviation(),
        _ if formats.contains(&"Book".to_string()) => Book.abbreviation(),
        _ if formats.contains(&"Journal".to_string()) => Journal.abbreviation(),
        _ => "".to_string()
    }
}