use super::ephemera_folder_item::format::Format;
use super::ephemera_folder_item::EphemeraFolderItem;

#[derive(Default)]
pub struct EphemeraFolderItemBuilder {
    alternative: Option<Vec<String>>,
    creator: Option<Vec<String>>,
    description: Option<Vec<String>>,
    format: Option<Vec<Format>>,
    id: Option<String>,
    provenance: Option<String>,
    publisher: Option<Vec<String>>,
    title: Option<Vec<String>>,
    transliterated_title: Option<Vec<String>>,
}

impl EphemeraFolderItemBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn id(mut self, id: String) -> Self {
        self.id = Some(id);
        self
    }

    pub fn creator(mut self, creator: Vec<String>) -> Self {
        self.creator = Some(creator);
        self
    }

    pub fn description(mut self, description: Vec<String>) -> Self {
        self.description = Some(description);
        self
    }

    pub fn title(mut self, title: Vec<String>) -> Self {
        self.title = Some(title);
        self
    }

    pub fn alternative(mut self, alternative: Vec<String>) -> Self {
        self.alternative = Some(alternative);
        self
    }

    pub fn format(mut self, format: Vec<Format>) -> Self {
        self.format = Some(format);
        self
    }
    pub fn provenance(mut self, provenance: String) -> Self {
        self.provenance = Some(provenance);
        self
    }
    pub fn publisher(mut self, publisher: Vec<String>) -> Self {
        self.publisher = Some(publisher);
        self
    }

    pub fn transliterated_title(mut self, transliterated_title: Vec<String>) -> Self {
        self.transliterated_title = Some(transliterated_title);
        self
    }

    pub fn build(self) -> Result<EphemeraFolderItem, &'static str> {
        let id = self.id.ok_or("id is required")?;
        let title = self.title.ok_or("title is required")?;

        Ok(EphemeraFolderItem {
            id,
            title,
            alternative: self.alternative,
            description: self.description,
            format: self.format,
            transliterated_title: self.transliterated_title,
            provenance: self.provenance,
            publisher: self.publisher,
            creator: self.creator,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_builder_success() {
        let item = EphemeraFolderItemBuilder::new()
            .id("test-id".to_string())
            .title(vec!["test title".to_string()])
            .alternative(vec!["alt title".to_string()])
            .creator(vec!["jessy".to_string()])
            .provenance("Test name".to_string())
            .publisher(vec!["Princeton Press".to_string()])
            .build();

        assert!(item.is_ok());
        let item = item.unwrap();
        assert_eq!(item.id, "test-id");
        assert_eq!(item.title, vec!["test title"]);
        assert_eq!(item.alternative, Some(vec!["alt title".to_string()]));
        assert_eq!(item.creator, Some(vec!["jessy".to_string()]));
        assert_eq!(item.provenance, Some("Test name".to_string()));
        assert_eq!(item.publisher, Some(vec!["Princeton Press".to_string()]));
    }

    #[test]
    fn test_builder_missing_required_fields() {
        let item = EphemeraFolderItemBuilder::new()
            .id("test-id".to_string())
            .build();

        assert!(item.is_err());
        assert_eq!(item.unwrap_err(), "title is required");
    }
}
