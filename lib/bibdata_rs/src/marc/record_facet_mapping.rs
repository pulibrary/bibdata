use super::{
    control_field::{
        cataloging_source::uses_archival_description,
        system_control_number::is_princeton_finding_aid,
    },
    fixed_field::{
        is_monograph,
        physical_description::{categories_of_material, CategoryOfMaterial},
        TypeOfRecord,
    },
};
use crate::{marc::fixed_field::BibliographicLevel, solr};
use marctk::Record;

// This module is responsible for determining which solr facets are relevant for a given MARC record

struct ShouldIncludeFacet {
    facet: solr::FormatFacet,
    include_if: fn(&Record) -> bool,
}

pub fn format_facets(record: &Record) -> Vec<solr::FormatFacet> {
    [
        ShouldIncludeFacet {
            facet: solr::FormatFacet::Journal,
            include_if: is_serial,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::DataFile,
            include_if: is_datafile,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::VisualMaterial,
            include_if: is_visual_material,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::VideoProjectedMedium,
            include_if: is_video,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::MusicalScore,
            include_if: is_musical_score,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::Audio,
            include_if: is_audio,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::Map,
            include_if: is_map,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::Manuscript,
            include_if: is_manuscript,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::Book,
            include_if: is_book,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::Databases,
            include_if: is_database,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::ArchivalItem,
            include_if: is_archival_item,
        },
        ShouldIncludeFacet {
            facet: solr::FormatFacet::Microform,
            include_if: is_microform,
        },
    ]
    .iter()
    .filter(|should_include| (should_include.include_if)(record))
    .map(|should_include| should_include.facet)
    .collect()
}

fn is_book(record: &Record) -> bool {
    match TypeOfRecord::try_from(record) {
        Ok(TypeOfRecord::ManuscriptLanguageMaterial) if !is_princeton_finding_aid(record) => true,
        Ok(TypeOfRecord::LanguageMaterial) if is_monograph(record) => true,
        _ => false,
    }
}

fn is_database(record: &Record) -> bool {
    matches!(
        (
            TypeOfRecord::try_from(record),
            BibliographicLevel::try_from(record)
        ),
        (
            Ok(TypeOfRecord::LanguageMaterial),
            Ok(BibliographicLevel::IntegratingResource)
        )
    )
}

fn is_serial(record: &Record) -> bool {
    matches!(
        (
            TypeOfRecord::try_from(record),
            BibliographicLevel::try_from(record)
        ),
        (
            Ok(TypeOfRecord::LanguageMaterial),
            Ok(BibliographicLevel::Serial)
        )
    )
}

fn is_datafile(record: &Record) -> bool {
    matches!(
        TypeOfRecord::try_from(record),
        Ok(TypeOfRecord::ComputerFile)
    )
}

fn is_audio(record: &Record) -> bool {
    matches!(
        TypeOfRecord::try_from(record),
        Ok(TypeOfRecord::MusicalSoundRecording | TypeOfRecord::NonmusicalSoundRecording)
    )
}

fn is_video(record: &Record) -> bool {
    matches!(
        TypeOfRecord::try_from(record),
        Ok(TypeOfRecord::ProjectedMedium)
    )
}

fn is_visual_material(record: &Record) -> bool {
    matches!(
        TypeOfRecord::try_from(record),
        Ok(TypeOfRecord::TwoDimensionalNonProjectableGraphic
            | TypeOfRecord::ThreeDimensionalArtifactOrNaturallyOcurringObject
            | TypeOfRecord::Kit)
    )
}

fn is_musical_score(record: &Record) -> bool {
    matches!(
        TypeOfRecord::try_from(record),
        Ok(TypeOfRecord::NotatedMusic | TypeOfRecord::ManuscriptNotatedMusic)
    )
}

fn is_map(record: &Record) -> bool {
    matches!(
        TypeOfRecord::try_from(record),
        Ok(TypeOfRecord::CartographicMaterial | TypeOfRecord::ManuscriptCartographicMaterial)
    )
}

fn is_manuscript(record: &Record) -> bool {
    matches!(
        TypeOfRecord::try_from(record),
        Ok(TypeOfRecord::ManuscriptCartographicMaterial
            | TypeOfRecord::ManuscriptLanguageMaterial
            | TypeOfRecord::ManuscriptNotatedMusic
            | TypeOfRecord::MixedMaterials)
    )
}

fn is_archival_item(record: &Record) -> bool {
    matches!(
        (
            TypeOfRecord::try_from(record),
            BibliographicLevel::try_from(record)
        ),
        (
            Ok(TypeOfRecord::ManuscriptLanguageMaterial),
            Ok(BibliographicLevel::MonographItem)
        )
    ) && is_princeton_finding_aid(record)
        && uses_archival_description(record)
}

fn is_microform(record: &Record) -> bool {
    categories_of_material(record)
        .iter()
        .any(|category| matches!(category, CategoryOfMaterial::Microform))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_defaults_to_no_facets() {
        let record = Record::new();
        assert_eq!(format_facets(&record), [])
    }

    #[test]
    fn it_can_identify_microform() {
        let record = Record::from_breaker("=007 hd adb016bucu").unwrap();
        assert_eq!(format_facets(&record), [solr::FormatFacet::Microform])
    }

    #[test]
    fn it_can_identify_microform_that_was_originally_a_journal() {
        let record = Record::from_breaker(
            r#"=LDR 02179cas a2200481 a 4500
=007 hd adb016bucu"#,
        )
        .unwrap();
        assert_eq!(
            format_facets(&record),
            [solr::FormatFacet::Journal, solr::FormatFacet::Microform]
        )
    }

    #[test]
    fn it_can_identify_microform_that_was_originally_a_manuscript_musical_score() {
        let record = Record::from_breaker(
            r#"=LDR 01765cdm a2200349 a 4500
=007 hd adb016bucu"#,
        )
        .unwrap();
        assert_eq!(
            format_facets(&record),
            [
                solr::FormatFacet::MusicalScore,
                solr::FormatFacet::Manuscript,
                solr::FormatFacet::Microform
            ]
        )
    }

    #[test]
    fn it_can_identify_manuscript_archival_item() {
        let record = Record::from_breaker(
            r#"=LDR 00804ctmaa2200217Ma 4500
=035 \\ $a(PULFA)C1778_c01107-90354"#,
        )
        .unwrap();
        assert_eq!(
            format_facets(&record),
            [
                solr::FormatFacet::Manuscript,
                solr::FormatFacet::ArchivalItem
            ]
        )
    }

    #[test]
    fn it_can_identify_manuscript_archival_item_that_uses_appm_standard() {
        let record = Record::from_breaker(
            r#"=LDR 00804ctmaa2200217Ma 4500
=035 \\ $a(PULFA)C1778_c01107-90354
=040 \\ $e appm"#,
        )
        .unwrap();
        assert_eq!(
            format_facets(&record),
            [
                solr::FormatFacet::Manuscript,
                solr::FormatFacet::ArchivalItem
            ]
        )
    }

    #[test]
    fn it_can_identify_manuscript_archival_item_that_uses_dacs_standard() {
        let record = Record::from_breaker(
            r#"=LDR 00804ctmaa2200217Ma 4500
=035 \\ $a(PULFA)C1778_c01107-90354
=040 \\ $edacs"#,
        )
        .unwrap();
        assert_eq!(
            format_facets(&record),
            [
                solr::FormatFacet::Manuscript,
                solr::FormatFacet::ArchivalItem
            ]
        )
    }

    #[test]
    fn it_can_identify_manuscript_archival_item_that_uses_unknown_standard() {
        let record = Record::from_breaker(
            r#"=LDR 00804ctmaa2200217Ma 4500
=035 \\ $a(PULFA)C1778_c01107-90354
=040 \\ $a NjP"#,
        )
        .unwrap();
        assert_eq!(
            format_facets(&record),
            [
                solr::FormatFacet::Manuscript,
                solr::FormatFacet::ArchivalItem
            ]
        )
    }

    #[test]
    fn it_can_identify_manuscript_that_is_described_using_a_non_archival_standard() {
        let record = Record::from_breaker(
            r#"=LDR 00804ctmaa2200217Ma 4500
=035 \\ $a(PULFA)C1778_c01107-90354
=040 \\ $e aacr"#,
        )
        .unwrap();
        assert_eq!(format_facets(&record), [solr::FormatFacet::Manuscript])
    }

    #[test]
    fn it_can_identify_books_from_leader() {
        let leaders = ["      aa", "      ab", "      ac", "      ad", "      am"];
        for leader in leaders {
            let mut record = Record::new();
            record.set_leader(format!("{:24}", leader)).unwrap();
            assert!(format_facets(&record).contains(&solr::FormatFacet::Book))
        }
    }

    #[test]
    fn it_can_identify_journals_from_leader() {
        let leader = "      as";
        let mut record = Record::new();
        record.set_leader(format!("{:24}", leader)).unwrap();
        assert!(format_facets(&record).contains(&solr::FormatFacet::Journal))
    }

    #[test]
    fn it_can_identify_data_files_from_leader() {
        let leader = "      m";
        let mut record = Record::new();
        record.set_leader(format!("{:24}", leader)).unwrap();
        assert!(format_facets(&record).contains(&solr::FormatFacet::DataFile))
    }

    #[test]
    fn it_can_identify_databases_from_leader() {
        let leader = "      ai";
        let mut record = Record::new();
        record.set_leader(format!("{:24}", leader)).unwrap();
        assert!(format_facets(&record).contains(&solr::FormatFacet::Databases))
    }

    #[test]
    fn it_can_identify_visual_materials_from_leader() {
        let leaders = ["      k", "      o", "      r"];
        for leader in leaders {
            let mut record = Record::new();
            record.set_leader(format!("{:24}", leader)).unwrap();
            assert!(format_facets(&record).contains(&solr::FormatFacet::VisualMaterial))
        }
    }

    #[test]
    fn it_can_identify_video_projected_medium_from_leader() {
        let leader = "      g";
        let mut record = Record::new();
        record.set_leader(format!("{:24}", leader)).unwrap();
        assert!(format_facets(&record).contains(&solr::FormatFacet::VideoProjectedMedium))
    }

    #[test]
    fn it_can_identify_musical_scores_from_leader() {
        let leaders = ["      c", "      d"];
        for leader in leaders {
            let mut record = Record::new();
            record.set_leader(format!("{:24}", leader)).unwrap();
            assert!(format_facets(&record).contains(&solr::FormatFacet::MusicalScore))
        }
    }

    #[test]
    fn it_can_identify_audio_from_leader() {
        let leaders = ["      i", "      j"];
        for leader in leaders {
            let mut record = Record::new();
            record.set_leader(format!("{:24}", leader)).unwrap();
            assert!(format_facets(&record).contains(&solr::FormatFacet::Audio))
        }
    }

    #[test]
    fn it_can_identify_map_from_leader() {
        let leader = "      e";
        let mut record = Record::new();
        record.set_leader(format!("{:24}", leader)).unwrap();
        assert!(format_facets(&record).contains(&solr::FormatFacet::Map))
    }

    #[test]
    fn it_can_identify_manuscript_from_leader() {
        let leaders = ["      d", "      f", "      p", "      t"];
        for leader in leaders {
            let mut record = Record::new();
            record.set_leader(format!("{:24}", leader)).unwrap();
            assert!(format_facets(&record).contains(&solr::FormatFacet::Manuscript))
        }
    }
}
