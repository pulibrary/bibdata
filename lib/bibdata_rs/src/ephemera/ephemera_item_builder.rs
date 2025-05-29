use super::ephemera_item::EphemeraItem;

#[derive(Default)]
pub struct EphemeraItemBuilder {
    id: Option<String>,
    title: Option<Vec<String>>,
    alternative: Option<Vec<String>>,
    transliterated_title: Option<Vec<String>>,
}

impl EphemeraItemBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn id(mut self, id: String) -> Self {
        self.id = Some(id);
        self
    }

    pub fn title(mut self, title: Vec<String>) -> Self {
        self.title = Some(title);
        self
    }

    pub fn alternative(mut self, alternative_title: Vec<String>) -> Self {
        self.alternative = Some(alternative_title);
        self
    }
    
    pub fn transliterated_title(mut self, transliterated_title: Vec<String>) -> Self {
        self.transliterated_title = Some(transliterated_title);
        self
    }

    pub fn build(self) -> Result<EphemeraItem, &'static str> {
        let id = self.id.ok_or("id is required")?;
        let title = self.title.ok_or("title is required")?;

        Ok(EphemeraItem {
            id,
            title,
            alternative_title_display: self.alternative,
            transliterated_title_display: self.transliterated_title,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_builder_success() {
        let item = EphemeraItemBuilder::new()
            .id("test-id".to_string())
            .title(vec!["test title".to_string()])
            .alternative(vec!["alt title".to_string()])
            .build();

        assert!(item.is_ok());
        let item = item.unwrap();
        assert_eq!(item.id, "test-id");
        assert_eq!(item.title, vec!["test title"]);
        assert_eq!(
            item.alternative_title_display,
            Some(vec!["alt title".to_string()])
        );
    }

    #[test]
    fn test_builder_missing_required_fields() {
        let item = EphemeraItemBuilder::new().id("test-id".to_string()).build();

        assert!(item.is_err());
        assert_eq!(item.unwrap_err(), "title is required");
    }
}
