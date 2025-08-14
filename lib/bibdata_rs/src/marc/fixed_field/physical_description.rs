// This module concerns field 007: Physical Description

use std::str::FromStr;

use marctk::Record;

pub enum CategoryOfMaterial {
    Map,
    ElectronicResource,
    Globe,
    TactileMaterial,
    ProjectedGraphic,
    Microform,
    NonProjectedGraphic,
    MotionPicture,
    Kit,
    NotatedMusic,
    RemoteSensingImage,
    SoundRecording,
    Text,
    VideoRecording,
    Unspecified,
}

#[derive(Debug)]
pub struct NoSuchCategoryOfMaterial;

impl FromStr for CategoryOfMaterial {
    type Err = NoSuchCategoryOfMaterial;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s.chars().next() {
            Some('a') => Ok(CategoryOfMaterial::Map),
            Some('c') => Ok(CategoryOfMaterial::ElectronicResource),
            Some('d') => Ok(CategoryOfMaterial::Globe),
            Some('f') => Ok(CategoryOfMaterial::TactileMaterial),
            Some('g') => Ok(CategoryOfMaterial::ProjectedGraphic),
            Some('h') => Ok(CategoryOfMaterial::Microform),
            Some('k') => Ok(CategoryOfMaterial::NonProjectedGraphic),
            Some('m') => Ok(CategoryOfMaterial::MotionPicture),
            Some('o') => Ok(CategoryOfMaterial::Kit),
            Some('q') => Ok(CategoryOfMaterial::NotatedMusic),
            Some('r') => Ok(CategoryOfMaterial::RemoteSensingImage),
            Some('s') => Ok(CategoryOfMaterial::SoundRecording),
            Some('t') => Ok(CategoryOfMaterial::Text),
            Some('v') => Ok(CategoryOfMaterial::VideoRecording),
            Some('z') => Ok(CategoryOfMaterial::Unspecified),
            _ => Err(NoSuchCategoryOfMaterial),
        }
    }
}

pub fn categories_of_material(record: &Record) -> Vec<CategoryOfMaterial> {
    record
        .get_control_fields("007")
        .iter()
        .filter_map(|field| CategoryOfMaterial::from_str(field.content()).ok())
        .collect()
}
