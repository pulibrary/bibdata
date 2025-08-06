use super::{
    fixed_field::{literary_forms, BibliographicLevel, TypeOfRecord},
    trim_punctuation,
};
use itertools::Itertools;
use marctk::Record;
use regex::{Regex, RegexBuilder};
use std::sync::LazyLock;

mod biographical_content;

pub use biographical_content::BiographicalContent;

pub fn genres(record: &Record) -> Vec<String> {
    genres_from_subfield_v(record)
        .into_iter()
        .chain(genres_from_subfield_x(record))
        .chain(genres_from_subject_vocabularies(record))
        .chain(genres_from_primary_source_lcsh_mapping(record))
        .chain(genres_from_primary_source_lcgft_mapping(record))
        .chain(genres_from_biographical_content(record))
        .unique()
        .collect()
}

fn genres_from_primary_source_lcsh_mapping(record: &Record) -> Vec<String> {
    if is_book(record) && is_literary_work(record) {
        return vec![];
    }
    if record
        .extract_values(
            "600(*0)vx:610(*0)vx:611(*0)vx:630(*0)vx:650(*0)vx:651(*0)vx:655(*0)a:655(*0)vx",
        )
        .iter()
        .any(|genre_term| does_lcsh_genre_term_indicate_primary_source(genre_term))
    {
        vec!["Primary sources".to_string()]
    } else {
        vec![]
    }
}

const GENRE_TERMS: &[&str] = &[
    "Bibliography",
    "Biography",
    "Catalogs",
    "Catalogues raisonnes",
    "Commentaries",
    "Congresses",
    "Diaries",
    "Dictionaries",
    "Drama",
    "Encyclopedias",
    "Exhibitions",
    "Fiction",
    "Guidebooks",
    "In art",
    "Indexes",
    "Librettos",
    "Manuscripts",
    "Newspapers",
    "Periodicals",
    "Pictorial works",
    "Poetry",
    "Portraits",
    "Scores",
    "Songs and music",
    "Sources",
    "Statistics",
    "Texts",
    "Translations",
];

const GENRE_STARTING_TERMS: &[&str] = &[
    "Census",
    "Maps",
    "Methods",
    "Parts",
    "Personal narratives",
    "Scores and parts",
    "Study and teaching",
    "Translations into ",
];

fn is_likely_genre_term(term: &str) -> bool {
    GENRE_TERMS.contains(&term)
        || GENRE_STARTING_TERMS
            .iter()
            .any(|starting_term| term.starts_with(starting_term))
}

const PRIMARY_SOURCE_GENRES: &[&str] = &[
    "atlases",
    "charters",
    "correspondence",
    "diaries",
    "documents",
    "interview",
    "interviews",
    "letters",
    "manuscripts",
    "maps",
    "notebooks, sketchbooks, etc",
    "oral history",
    "pamphlets",
    "personal narratives",
    "photographs",
    "pictorial works",
    "sources",
    "speeches",
    "statistics",
];

fn does_lcsh_genre_term_indicate_primary_source(value: &str) -> bool {
    static CONTAINS_PRIMARY_SOURCE_TERM: LazyLock<Vec<Regex>> = LazyLock::new(|| {
        PRIMARY_SOURCE_GENRES
            .iter()
            .map(|term| Regex::new(format!(r"(^|\W){}($|\W)", term).as_str()).unwrap())
            .collect()
    });
    let lowercase = value.to_lowercase();
    let normalized_genre = lowercase.trim().trim_end_matches('.');
    CONTAINS_PRIMARY_SOURCE_TERM
        .iter()
        .any(|r| r.is_match(normalized_genre))
}

fn genres_from_biographical_content(record: &Record) -> Vec<String> {
    if matches!(
        BiographicalContent::from(record),
        BiographicalContent::Autobiography
    ) && !is_literary_book(record)
    {
        vec!["Primary sources".to_owned()]
    } else {
        vec![]
    }
}

fn genres_from_subfield_x(record: &Record) -> Vec<String> {
    record
        .extract_values("600(*0)x:610(*0)x:611(*0)x:630(*0)x:650(*0)x:651(*0)x:655(*0)x")
        .iter()
        .map(|genre| trim_punctuation(genre))
        .map(|genre| genre.trim().to_owned())
        .filter(|genre| !genre.is_empty())
        .filter(|genre| is_likely_genre_term(genre))
        .collect()
}

fn genres_from_subfield_v(record: &Record) -> Vec<String> {
    record
        .extract_values("600(*0)v:610(*0)v:611(*0)v:630(*0)v:650(*0)v:651(*0)v:655(*0)a:655(*0)v")
        .iter()
        .map(|genre| trim_punctuation(genre))
        .map(|genre| genre.trim().to_owned())
        .filter(|genre| !genre.is_empty())
        .collect()
}

const SUBJECT_GENRE_VOCABULARIES: &[&str] = &[
    "sk", "aat", "lcgft", "rbbin", "rbgenr", "rbmscv", "rbpap", "rbpri", "rbprov", "rbpub",
    "rbtyp", "homoit",
];

fn genres_from_subject_vocabularies(record: &Record) -> Vec<String> {
    let subjects = record.fields().iter().fold(Vec::new(), |mut acc, field| {
        if field.ind2() != "7" { return acc }
        if !matches!(&field.first_subfield("2"), Some(sf) if SUBJECT_GENRE_VOCABULARIES.contains(&sf.content().trim())) { return acc };
        acc.extend(field.subfields().iter()
            .filter(|sf| (field.tag() == "650" && sf.code() == "v") || (field.tag() == "655" && sf.code() == "a") || (field.tag() == "655" && sf.code() == "v"))
            .map(|sf| trim_punctuation(sf.content()))
            .map(|genre| genre.trim().to_owned())
        );
        acc
    });
    subjects
}

const PRIMARY_SOURCE_LCGFT_GENRES: &[&str] = &[
    "Primary sources",
    "Call documents",
    "Charters and articles of incorporation",
    "Church covenants",
    "Church orders",
    "Codes (Jewish law)",
    "Codices (Law)",
    "Collective labor agreements",
    "Commercial arbitration agreements",
    "Concordats",
    "Consilia",
    "Constitutional amendments",
    "Constitutions",
    "Contracts",
    "Cooperative agreements",
    "Court decisions and opinions",
    "Court rules",
    "Coutumes",
    "Customary laws",
    "Custumals",
    "Deeds",
    "Executive orders",
    "Fatwas",
    "Indulgences (Canon law)",
    "Intergovernmental agreements",
    "Legal instruments",
    "Legal memorandums",
    "Legal petitions",
    "Legislative materials",
    "Messages (Official communications)",
    "Monastic constitutions",
    "Monastic rules",
    "Official gazettes",
    "Papal documents",
    "Papal encyclicals",
    "Patents",
    "Privileges and immunities",
    "Proclamations",
    "Records (Documents)",
    "Records and briefs",
    "Registers (Lists)",
    "Religious inventories",
    "Remonstrances",
    "Resolutions (Law)",
    "Responsa (Jewish law)",
    "Session laws",
    "Statutes and codes",
    "Travaux préparatoires (Treaties)",
    "Treaties",
    "Trial and arbitral proceedings",
    "Wills",
    "Writs",
    "Year books (English law reports)",
    "Autobiographical comics",
    "Autobiographical drama",
    "Autobiographical films",
    "Autobiographical television programs",
    "Autobiographies",
    "Captivity narratives",
    "Diaries",
    "Personal narratives",
    "Slave narratives",
    "Census data",
    "City directories",
    "Data sets",
    "Death registers",
    "Demographic surveys",
    "Judicial statistics",
    "Medical statistics",
    "Statistics",
    "Vital statistics",
    "Field recordings",
    "Interviews",
    "Radio interviews",
    "Business correspondence",
    "Chirographa (Personal correspondence)",
    "Love letters",
    "Pastoral letters and charges",
    "Personal correspondence",
    "Manuscripts",
    "Atlases",
    "Cartographic materials",
    "Digital maps",
    "Early maps",
    "Geospatial data",
    "Globes",
    "Gores (Maps)",
    "Manuscript maps",
    "Mappae mundi",
    "Maps",
    "Military maps",
    "Mine maps",
    "Nautical charts",
    "Outline maps",
    "Physical maps",
    "Quadrangle maps",
    "Raster data",
    "Road maps",
    "Stick charts",
    "Strip maps",
    "Topographic maps",
    "Topological maps",
    "Upside-down maps",
    "World atlases",
    "World maps",
    "Zoning maps",
    "Field notes",
    "Notebooks",
    "Sketchbooks",
    "Oral histories",
    "Personal recordings",
    "Ephemera",
    "Tracts (Ephemera)",
    "Aerial photographs",
    "Aerial views",
    "Baby books",
    "Drawings",
    "Negatives (Photographs)",
    "Photographs",
    "Pictures",
    "Portraits",
    "Selfies",
    "Self-portraits",
    "Visual works",
    "Campaign speeches",
    "Occasional speeches",
    "Speeches",
];

fn genres_from_primary_source_lcgft_mapping(record: &Record) -> Vec<String> {
    if is_book(record) && is_literary_work(record) {
        return vec![];
    }
    if record
        .extract_fields(
            "655",
        )
        .filter(|field| field.ind2() == "7" && matches!(field.first_subfield("2"), Some(vocabulary) if vocabulary.content().trim() == "lcgft" ))
        .any(|field| field.get_subfields("a").iter().any(|sf| does_lcgft_genre_term_indicate_primary_source(sf.content())))
    {
        vec!["Primary sources".to_string()]
    } else {
        vec![]
    }
}

fn does_lcgft_genre_term_indicate_primary_source(value: &str) -> bool {
    static CONTAINS_LCGFT_PRIMARY_SOURCE_TERM: LazyLock<Vec<Regex>> = LazyLock::new(|| {
        PRIMARY_SOURCE_LCGFT_GENRES
            .iter()
            .map(|term| {
                RegexBuilder::new(format!(r"(^|\W){}($|\W)", term).as_str())
                    .case_insensitive(true)
                    .build()
                    .unwrap()
            })
            .collect()
    });
    let normalized_genre = value.trim().trim_end_matches('.');
    CONTAINS_LCGFT_PRIMARY_SOURCE_TERM
        .iter()
        .any(|r| r.is_match(normalized_genre))
}

fn is_literary_work(record: &Record) -> bool {
    literary_forms(record)
        .iter()
        .any(|form| form.is_literature())
}

fn is_book(record: &Record) -> bool {
    let type_of_record: Result<TypeOfRecord, _> = record.try_into();
    let bibliographic_level: Result<BibliographicLevel, _> = record.try_into();
    matches!((type_of_record, bibliographic_level), (Ok(TypeOfRecord::LanguageMaterial), Ok(level)) if !level.is_serial())
}

fn is_literary_book(record: &Record) -> bool {
    is_book(record) && is_literary_work(record)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_identies_nonfiction_title_as_non_literary() {
        let record = Record::from_breaker(
            r#"=LDR 04137cam a2200853Ii 4500
=008                                  0
=650  0 $a Franco-Prussian War, 1870-1871 $v Pamphlets."#,
        )
        .unwrap();
        assert!(!is_literary_work(&record))
    }

    #[test]
    fn it_identies_fiction_title_as_literary() {
        let record = Record::from_breaker(
            r#"=LDR 04137cam a2200853Ii 4500
=008                                  1
=650  0 $a Franco-Prussian War, 1870-1871 $v Pamphlets."#,
        )
        .unwrap();
        assert!(is_literary_work(&record))
    }

    #[test]
    fn it_can_find_genres_from_subject_vocabularies() {
        let record = Record::from_breaker(
            r#"=LDR 04137cam a2200853Ii 4500
=655 \7 $a Afrofuturist comics $2 lcgft
=655 \7 $a Random genre $2 invalid thesaurus"#,
        )
        .unwrap();
        assert_eq!(
            genres_from_subject_vocabularies(&record),
            vec!["Afrofuturist comics".to_string()]
        )
    }

    #[test]
    fn it_can_find_genres_from_630x() {
        let record = Record::from_breaker(
            r#"=600 \\$aExclude$vJohn$xJoin
=630 \0$xFiction.
=655 \\$aCulture.$xDramatic rendition$vAwesome
=655 \\$aPoetry$xTranslations into French$vMaps
=655 \\$aManuscript$xTranslations into French$vGenre$2rbgenr"#,
        )
        .unwrap();
        assert_eq!(genres_from_subfield_x(&record), vec!["Fiction"]);
    }

    #[test]
    fn it_can_identify_autobiographies_as_primary_source() {
        let record = Record::from_breaker(
            r#"=LDR 02056cam a2200385 i 4500
=008 180831s2018 ag 000 0 spa d
=100 1\ $a Barilaro, Javier, $d 1974- $e author.  $0 http://id.loc.gov/authorities/names/no2019132371
=600 10 $a Barilaro, Javier, $d 1974- $v Biography."#,
        )
        .unwrap();
        assert_eq!(
            genres(&record),
            vec!["Biography".to_string(), "Primary sources".to_string()]
        )
    }

    #[test]
    fn it_can_find_genres_from_lcgft() {
        let record = Record::from_breaker(
            r#"=LDR 04137cam a2200853Ii 4500
=655 \7 $a Chirographa (Personal correspondence) $2 lcgft"#,
        )
        .unwrap();
        assert_eq!(
            genres(&record),
            vec![
                "Chirographa (Personal correspondence)".to_string(),
                "Primary sources".to_string()
            ]
        )
    }

    #[test]
    fn it_can_identify_primary_source() {
        assert!(does_lcsh_genre_term_indicate_primary_source(
            "Correspondence"
        ));
    }
}
