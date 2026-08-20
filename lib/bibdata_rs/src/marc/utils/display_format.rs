// Choses a display format given a vector of formats an if it's electronic
pub fn display_format(formats: Vec<String>) -> String {
    match formats {
        _ if formats.contains(&"Microform".to_string()) => "Microform".to_string(),
        _ if formats.contains(&"Manuscript".to_string()) => "Manuscript".to_string(),
        _ if formats.contains(&"Data file".to_string()) => "Data file".to_string(),
        _ if formats.contains(&"Musical score".to_string()) => "Music Score".to_string(),
        _ if formats.contains(&"Senior thesis".to_string()) => "Thesis".to_string(),
        _ if formats.contains(&"Archival item".to_string()) => "Archival".to_string(),
        _ if formats.contains(&"Video/Projected medium".to_string()) => "Video".to_string(),
        _ if formats.contains(&"Visual material".to_string()) => "Image".to_string(),
        _ if formats.contains(&"Map".to_string()) => "Map".to_string(),
        _ if formats.contains(&"Report".to_string()) => "Report".to_string(),
        _ if formats.contains(&"Coin".to_string()) => "Coin".to_string(),
        _ if formats.contains(&"Databases".to_string()) => "Database".to_string(),
        _ if formats.contains(&"Audio".to_string()) => "Audio".to_string(),
        _ if formats.contains(&"Book".to_string()) => "Book".to_string(),
        _ if formats.contains(&"Journal".to_string()) => "Journal".to_string(),
        _ => "".to_string()
    }
}