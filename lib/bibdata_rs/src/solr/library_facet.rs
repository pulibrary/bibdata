use serde::{Deserialize, Serialize};

#[allow(dead_code)]
#[derive(Clone, Copy, Debug, Deserialize, PartialEq, Serialize)]
pub enum LibraryFacet {
    #[serde(rename = "Forrestal Annex")]
    Annex,

    #[serde(rename = "Architecture Library")]
    Architecture,

    #[serde(rename = "East Asian Library")]
    EastAsian,

    #[serde(rename = "Engineering Library")]
    Engineering,

    #[serde(rename = "Firestone Library")]
    Firestone,

    #[serde(rename = "Lewis Library")]
    Lewis,

    #[serde(rename = "Marquand Library")]
    Marquand,

    #[serde(rename = "Mendel Music Library")]
    Mendel,

    #[serde(rename = "Mudd Manuscript Library")]
    Mudd,

    #[serde(rename = "Harold P. Furth Plasma Physics Library")]
    PPPL,

    ReCAP,

    #[serde(rename = "Special Collections")]
    SpecialCollections,

    #[serde(rename = "Stokes Library")]
    Stokes,
}
