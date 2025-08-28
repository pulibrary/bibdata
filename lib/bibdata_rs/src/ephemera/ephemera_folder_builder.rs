use super::ephemera_folder::coverage::Coverage;
use super::ephemera_folder::format::Format;
use super::ephemera_folder::origin_place::OriginPlace;
use super::ephemera_folder::{EphemeraFolder, Thumbnail};
use crate::ephemera::ephemera_folder;
use crate::ephemera::ephemera_folder::language::Language;
use crate::ephemera_folder::subject::Subject;
use crate::solr::ElectronicAccess;

#[derive(Default)]
pub struct EphemeraFolderBuilder {
    alternative: Option<Vec<String>>,
    creator: Option<Vec<String>>,
    contributor: Option<Vec<String>>,
    coverage: Option<Vec<Coverage>>,
    date_created: Option<Vec<String>>,
    description: Option<Vec<String>>,
    electronic_access: Option<Vec<ElectronicAccess>>,
    format: Option<Vec<Format>>,
    id: Option<String>,
    language: Option<Vec<Language>>,
    origin_place: Option<Vec<OriginPlace>>,
    page_count: Option<String>,
    provenance: Option<String>,
    publisher: Option<Vec<String>>,
    subject: Option<Vec<Subject>>,
    sort_title: Option<Vec<String>>,
    title: Option<Vec<String>>,
    thumbnail: Option<ephemera_folder::Thumbnail>,
    transliterated_title: Option<Vec<String>>,
}

impl EphemeraFolderBuilder {
    pub fn new() -> Self {
        Self::default()
    }

    pub fn alternative(mut self, alternative: Vec<String>) -> Self {
        self.alternative = Some(alternative);
        self
    }
    pub fn id(mut self, id: String) -> Self {
        self.id = Some(id);
        self
    }
    pub fn contributor(mut self, contributor: Vec<String>) -> Self {
        self.contributor = Some(contributor);
        self
    }
    pub fn coverage(mut self, country: Vec<Coverage>) -> Self {
        self.coverage = Some(country);
        self
    }
    pub fn creator(mut self, creator: Vec<String>) -> Self {
        self.creator = Some(creator);
        self
    }
    pub fn date_created(mut self, date_created: Vec<String>) -> Self {
        self.date_created = Some(date_created);
        self
    }
    pub fn description(mut self, description: Vec<String>) -> Self {
        self.description = Some(description);
        self
    }
    pub fn electronic_access(mut self, electronic_access: Vec<ElectronicAccess>) -> Self {
        self.electronic_access = Some(electronic_access);
        self
    }
    pub fn format(mut self, format: Vec<Format>) -> Self {
        self.format = Some(format);
        self
    }
    pub fn language(mut self, language: Vec<Language>) -> Self {
        self.language = Some(language);
        self
    }
    pub fn origin_place(mut self, origin: Vec<OriginPlace>) -> Self {
        self.origin_place = Some(origin);
        self
    }
    pub fn page_count(mut self, page_count: String) -> Self {
        self.page_count = Some(page_count);
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
    pub fn subject(mut self, subject: Vec<Subject>) -> Self {
        self.subject = Some(subject);
        self
    }

    pub fn subjects(mut self, subjects: Vec<Subject>) -> Self {
        self.subject = Some(subjects);
        self
    }
    pub fn sort_title(mut self, sort_title: Vec<String>) -> Self {
        self.sort_title = Some(sort_title);
        self
    }
    pub fn thumbnail(mut self, thumbnail: Thumbnail) -> Self {
        self.thumbnail = Some(thumbnail);
        self
    }

    pub fn title(mut self, title: Vec<String>) -> Self {
        self.title = Some(title);
        self
    }

    pub fn transliterated_title(mut self, transliterated_title: Vec<String>) -> Self {
        self.transliterated_title = Some(transliterated_title);
        self
    }

    pub fn build(self) -> Result<EphemeraFolder, &'static str> {
        let id = self.id.ok_or("id is required")?;
        let title = self.title.ok_or("title is required")?;

        Ok(EphemeraFolder {
            alternative: self.alternative,
            creator: self.creator,
            contributor: self.contributor,
            coverage: self.coverage,
            date_created: self.date_created,
            description: self.description,
            electronic_access: self.electronic_access,
            format: self.format,
            id,
            language: self.language,
            origin: self.origin_place,
            page_count: self.page_count,
            provenance: self.provenance,
            publisher: self.publisher,
            sort_title: self.sort_title,
            subject: self.subject,
            title,
            thumbnail: self.thumbnail,
            transliterated_title: self.transliterated_title,
        })
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_builder_success() {
        let item = EphemeraFolderBuilder::new()
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
        let item = EphemeraFolderBuilder::new()
            .id("test-id".to_string())
            .build();

        assert!(item.is_err());
        assert_eq!(item.unwrap_err(), "title is required");
    }

    #[test]
    fn it_has_a_contributor() {
        let item = EphemeraFolderBuilder::new()
            .id("test-id".to_string())
            .title(vec!["test title".to_string()])
            .contributor(vec!["Eric".to_string()])
            .build();

        assert!(item.is_ok());
        let item = item.unwrap();
        assert_eq!(item.id, "test-id");
        assert_eq!(item.title, vec!["test title"]);
        assert_eq!(item.contributor, Some(vec!["Eric".to_string()]));
    }
}
