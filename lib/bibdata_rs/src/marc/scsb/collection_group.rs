use std::str::FromStr;

use marctk::Record;

pub enum CollectionGroup {
    Shared,
    Private,
    Committed,
    Uncommittable,
    Open,
}

impl CollectionGroup {
    pub fn code(&self) -> char {
        match self {
            Self::Committed => 'C',
            Self::Open => 'O',
            Self::Private => 'P',
            Self::Shared => 'S',
            Self::Uncommittable => 'U',
        }
    }
}

pub fn collection_groups(record: &Record) -> Vec<CollectionGroup> {
    record
        .get_field_values("876", "x")
        .iter()
        .filter_map(|value| CollectionGroup::from_str(value).ok())
        .collect()
}

pub struct NoSuchCollectionGroup;
impl FromStr for CollectionGroup {
    type Err = NoSuchCollectionGroup;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "Shared" => Ok(Self::Shared),
            "Private" => Ok(Self::Private),
            "Committed" => Ok(Self::Committed),
            "Uncommittable" => Ok(Self::Uncommittable),
            "Open" => Ok(Self::Open),
            _ => Err(NoSuchCollectionGroup),
        }
    }
}
