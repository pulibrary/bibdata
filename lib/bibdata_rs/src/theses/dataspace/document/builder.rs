// This module provides a convenient way to create a DataspaceDocument using the builder pattern

use super::DataspaceDocument;
use crate::theses::dataspace::document::Metadatum;

#[derive(Debug, Default)]
pub struct DataspaceDocumentBuilder {
    id: Option<String>,
    certificate: Option<Vec<Option<String>>>,
    contributor: Option<Vec<Option<String>>>,
    contributor_advisor: Option<Vec<Option<String>>>,
    contributor_author: Option<Vec<Option<String>>>,
    date_classyear: Option<Vec<Option<String>>>,
    description_abstract: Option<Vec<Option<String>>>,
    department: Option<Vec<Option<String>>>,
    embargo_lift: Option<Vec<Option<String>>>,
    embargo_terms: Option<Vec<Option<String>>>,
    format_extent: Option<Vec<Option<String>>>,
    identifier_other: Option<Vec<Option<String>>>,
    identifier_uri: Option<Vec<Option<String>>>,
    language_iso: Option<Vec<Option<String>>>,
    location: Option<Vec<Option<String>>>,
    mudd_walkin: Option<Vec<Option<String>>>,
    rights_access_rights: Option<Vec<Option<String>>>,
    title: Option<Vec<Option<String>>>,
}

impl DataspaceDocumentBuilder {
    pub fn with_id(mut self, id: impl Into<String>) -> Self {
        self.id = Some(id.into());
        self
    }

    pub fn with_certificate(mut self, certificate: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.certificate {
            vec.extend(certificate.iter()
                .map(|cert| { cert.value.clone() }))
        } else {
            self.certificate = Some(certificate.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_contributor(mut self, contributors: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.contributor {
            vec.extend(contributors.iter()
                .map(|contributor| { contributor.value.clone() }))
        } else {
            self.contributor = Some(contributors.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_contributor_advisor(mut self, contributor_advisors: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.contributor_advisor {
            vec.extend(contributor_advisors.iter()
                .map(|ca| { ca.value.clone() }))
        } else {
            self.contributor_advisor = Some(contributor_advisors.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_contributor_author(mut self, contributor_author: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.contributor_author {
            vec.extend(contributor_author.iter()
                .map(|ca| { ca.value.clone() }))
        } else {
            self.contributor_author = Some(contributor_author.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_date_classyear(mut self, date_classyear: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.date_classyear {
            vec.extend(date_classyear.iter()
                .map(|date| { date.value.clone() }))
        } else {
            self.date_classyear = Some(date_classyear.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_description_abstract(mut self, description_abstract: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.description_abstract {
            vec.extend(description_abstract.iter()
                .map(|abs| { abs.value.clone() }))
        } else {
            self.description_abstract = Some(description_abstract.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_department(mut self, department: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.department {
            vec.append(&mut department.iter()
                .map(|department| { department.value.clone() })
                .collect())
        } else {
            self.department = Some(department.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_embargo_lift(mut self, embargo_lift: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.embargo_lift {
            vec.extend(embargo_lift.iter()
                .map(|el| { el.value.clone() }))
        } else {
            self.embargo_lift = Some(embargo_lift.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_embargo_terms(mut self, embargo_terms: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.embargo_terms {
            vec.extend(embargo_terms.iter()
                .map(|terms| { terms.value.clone() }))
        } else {
            self.embargo_terms = Some(embargo_terms.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_format_extent(mut self, format_extent: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.format_extent {
            vec.extend(format_extent.iter()
                .map(|format| { format.value.clone() }))
        } else {
            self.format_extent = Some(format_extent.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_identifier_other(mut self, identifier_other: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.identifier_other {
            vec.extend(identifier_other.iter()
                .map(|identifier| { identifier.value.clone() }))
        } else {
            self.identifier_other = Some(identifier_other.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_identifier_uri(mut self, identifier_uri: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.identifier_uri {
            vec.extend(identifier_uri.iter()
                .map(|uri| { uri.value.clone() }))
        } else {
            self.identifier_uri = Some(identifier_uri.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_language_iso(mut self, language_iso: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.language_iso {
            vec.extend(language_iso.iter()
                .map(|lang| { lang.value.clone() }))
        } else {
            self.language_iso = Some(language_iso.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_location(mut self, location: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.location {
            vec.extend(location.iter()
                .map(|location| { location.value.clone() }))
        } else {
            self.location = Some(location.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_mudd_walkin(mut self, mudd_walkin: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.mudd_walkin {
            vec.extend(mudd_walkin.iter()
                .map(|mw| { mw.value.clone() }));
        } else {
            self.mudd_walkin = Some(mudd_walkin.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_rights_access_rights(mut self, rights_access_rights: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.rights_access_rights {
            vec.extend(rights_access_rights.iter()
                .map(|rights| { rights.value.clone() }))
        } else {
            self.rights_access_rights = Some(rights_access_rights.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn with_title(mut self, title: Vec<Metadatum>) -> Self {
        if let Some(ref mut vec) = self.title {
            vec.extend(title.iter()
                .map(|title| { title.value.clone() }))
        } else {
            self.title = Some(title.iter().map(|md| { md.value.clone()}).collect::<Vec<Option<String>>>())
        }
        self
    }

    pub fn build(self) -> DataspaceDocument {
        DataspaceDocument {
            id: self.id,
            certificate: self.certificate,
            contributor: self.contributor,
            contributor_advisor: self.contributor_advisor,
            contributor_author: self.contributor_author,
            date_classyear: self.date_classyear,
            description_abstract: self.description_abstract,
            department: self.department,
            embargo_lift: self.embargo_lift,
            embargo_terms: self.embargo_terms,
            format_extent: self.format_extent,
            identifier_other: self.identifier_other,
            identifier_uri: self.identifier_uri,
            language_iso: self.language_iso,
            location: self.location,
            mudd_walkin: self.mudd_walkin,
            rights_access_rights: self.rights_access_rights,
            title: self.title,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_can_create_a_dataspace_document() {
        let builder = DataspaceDocumentBuilder::default();
        let doc = builder.with_id("ABC123").build();
        assert_eq!(doc.id, Some("ABC123".to_owned()));
    }
}
