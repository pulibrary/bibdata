use crate::solr::FormatFacet::*;
use crate::solr::format_facet::Abbreviation;

// Choses an abbreviated display format given a vector of formats
// this is intended for displaying compact badges inline with search results
pub fn display_format(formats: Vec<String>) -> String {
    match formats {
        _ if formats.contains(&Microform.to_string()) => Microform.abbreviation(),
        _ if formats.contains(&Manuscript.to_string()) => Manuscript.abbreviation(),
        _ if formats.contains(&DataFile.to_string()) => DataFile.abbreviation(),
        _ if formats.contains(&MusicalScore.to_string()) => MusicalScore.abbreviation(),
        _ if formats.contains(&SeniorThesis.to_string()) => SeniorThesis.abbreviation(),
        _ if formats.contains(&ArchivalItem.to_string()) => ArchivalItem.abbreviation(),
        _ if formats.contains(&VideoProjectedMedium.to_string()) => {
            VideoProjectedMedium.abbreviation()
        }
        _ if formats.contains(&VisualMaterial.to_string()) => VisualMaterial.abbreviation(),
        _ if formats.contains(&Map.to_string()) => Map.abbreviation(),
        _ if formats.contains(&Report.to_string()) => Report.abbreviation(),
        _ if formats.contains(&Coin.to_string()) => Coin.abbreviation(),
        _ if formats.contains(&Databases.to_string()) => Databases.abbreviation(),
        _ if formats.contains(&Audio.to_string()) => Audio.abbreviation(),
        _ if formats.contains(&Book.to_string()) => Book.abbreviation(),
        _ if formats.contains(&Journal.to_string()) => Journal.abbreviation(),
        _ => "".to_string(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
#[test]
    fn it_prioritizes_correctly() {
        assert_eq!(
            display_format(vec!("Microform".to_string(), "Book".to_string())),
            Microform.abbreviation()
        );
        assert_eq!(
            display_format(vec!("Journal".to_string(), "Book".to_string())),
            Book.abbreviation()
        );
        assert_eq!(
            display_format(vec!("Musical score".to_string(), "Data file".to_string())),
            DataFile.abbreviation()
        );
    }
}
