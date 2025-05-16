// This module provides a convenient way to create a DataspaceDocument using the builder pattern

use super::DataspaceDocument;

#[derive(Debug, Default)]
pub struct DataspaceDocumentBuilder {
    id: Option<String>,
    certificate: Option<Vec<String>>,
    contributor: Option<Vec<String>>,
    contributor_advisor: Option<Vec<String>>,
    contributor_author: Option<Vec<String>>,
    date_classyear: Option<Vec<String>>,
    description_abstract: Option<Vec<String>>,
    department: Option<Vec<String>>,
    embargo_lift: Option<Vec<String>>,
    embargo_terms: Option<Vec<String>>,
    format_extent: Option<Vec<String>>,
    identifier_other: Option<Vec<String>>,
    identifier_uri: Option<Vec<String>>,
    language_iso: Option<Vec<String>>,
    location: Option<Vec<String>>,
    mudd_walkin: Option<Vec<String>>,
    rights_access_rights: Option<Vec<String>>,
    title: Option<Vec<String>>,
}

impl DataspaceDocumentBuilder {
    pub fn with_id(mut self, id: impl Into<String>) -> Self {
        self.id = Some(id.into());
        self
    }

    pub fn with_certificate(mut self, certificate: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.certificate {
            vec.push(certificate.into())
        } else {
            self.certificate = Some(vec![certificate.into()]);
        };
        self
    }

    pub fn with_contributor(mut self, contributor: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.contributor {
            vec.push(contributor.into())
        } else {
            self.contributor = Some(vec![contributor.into()]);
        };
        self
    }

    pub fn with_contributor_advisor(mut self, contributor_advisor: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.contributor_advisor {
            vec.push(contributor_advisor.into())
        } else {
            self.contributor_advisor = Some(vec![contributor_advisor.into()]);
        };
        self
    }

    pub fn with_contributor_author(mut self, contributor_author: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.contributor_author {
            vec.push(contributor_author.into())
        } else {
            self.contributor_author = Some(vec![contributor_author.into()]);
        };
        self
    }

    pub fn with_date_classyear(mut self, date_classyear: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.date_classyear {
            vec.push(date_classyear.into())
        } else {
            self.date_classyear = Some(vec![date_classyear.into()]);
        };
        self
    }

    pub fn with_description_abstract(mut self, description_abstract: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.description_abstract {
            vec.push(description_abstract.into())
        } else {
            self.description_abstract = Some(vec![description_abstract.into()]);
        };
        self
    }

    pub fn with_department(mut self, department: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.department {
            vec.push(department.into())
        } else {
            self.department = Some(vec![department.into()]);
        };
        self
    }

    pub fn with_embargo_lift(mut self, embargo_lift: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.embargo_lift {
            vec.push(embargo_lift.into())
        } else {
            self.embargo_lift = Some(vec![embargo_lift.into()]);
        };
        self
    }

    pub fn with_embargo_terms(mut self, embargo_terms: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.embargo_terms {
            vec.push(embargo_terms.into())
        } else {
            self.embargo_terms = Some(vec![embargo_terms.into()]);
        };
        self
    }

    pub fn with_format_extent(mut self, format_extent: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.format_extent {
            vec.push(format_extent.into())
        } else {
            self.format_extent = Some(vec![format_extent.into()]);
        };
        self
    }

    pub fn with_identifier_other(mut self, identifier_other: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.identifier_other {
            vec.push(identifier_other.into())
        } else {
            self.identifier_other = Some(vec![identifier_other.into()]);
        };
        self
    }

    pub fn with_identifier_uri(mut self, identifier_uri: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.identifier_uri {
            vec.push(identifier_uri.into())
        } else {
            self.identifier_uri = Some(vec![identifier_uri.into()]);
        };
        self
    }

    pub fn with_language_iso(mut self, language_iso: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.language_iso {
            vec.push(language_iso.into())
        } else {
            self.language_iso = Some(vec![language_iso.into()]);
        };
        self
    }

    pub fn with_location(mut self, location: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.location {
            vec.push(location.into())
        } else {
            self.location = Some(vec![location.into()]);
        };
        self
    }

    pub fn with_mudd_walkin(mut self, mudd_walkin: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.mudd_walkin {
            vec.push(mudd_walkin.into())
        } else {
            self.mudd_walkin = Some(vec![mudd_walkin.into()]);
        };
        self
    }

    pub fn with_rights_access_rights(mut self, rights_access_rights: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.rights_access_rights {
            vec.push(rights_access_rights.into())
        } else {
            self.rights_access_rights = Some(vec![rights_access_rights.into()]);
        };
        self
    }

    pub fn with_title(mut self, title: impl Into<String>) -> Self {
        if let Some(ref mut vec) = self.title {
            vec.push(title.into())
        } else {
            self.title = Some(vec![title.into()]);
        };
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
