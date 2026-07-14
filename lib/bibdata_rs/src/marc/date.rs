use itertools::Itertools;
use jiff::{Timestamp, Zoned, tz::TimeZone};
use marctk::{Record, Subfield};
use parse_datetime::parse_datetime_at_date;

use crate::marc::{
    alma::{AlmaElectronicPortfolio, AlmaHoldingId},
    extract_values::ExtractValues,
    scsb::is_scsb,
};

pub fn cataloged_date(record: &Record) -> Option<String> {
    if is_scsb(record) {
        return None;
    }

    let item_edit_date = record
        .extract_field_values_by(
            |field| {
                field.tag() == "876"
                    && field
                        .first_subfield("0")
                        .is_some_and(|subfield| AlmaHoldingId::from(subfield).is_valid())
            },
            |field| field.first_subfield("d").map(Subfield::content),
        )
        .sorted();

    let electronic_edit_date = record
        .extract_field_values_by(
            |field| {
                matches!(
                    AlmaElectronicPortfolio::try_from(field),
                    Ok(AlmaElectronicPortfolio::Active)
                )
            },
            |field| field.first_subfield("w").map(Subfield::content),
        )
        .sorted();

    let record_edit_date = record
        .extract_field_values_by(
            |field| field.tag() == "950",
            |field| field.first_subfield("b").map(Subfield::content),
        )
        .sorted();

    item_edit_date
        .chain(electronic_edit_date)
        .chain(record_edit_date)
        .filter_map(|raw_date| {
            parse_date(raw_date).map(|parsed| {
                parsed
                    .timestamp()
                    .strftime("%Y-%m-%dT%H:%M:%SZ")
                    .to_string()
            })
        })
        .next()
}

fn parse_date(raw: &str) -> Option<Zoned> {
    match raw.find("US/Eastern") {
        Some(timezone_offset) => parse_datetime_at_date(
            Zoned::new(
                Timestamp::UNIX_EPOCH,
                TimeZone::get("America/New_York").unwrap(),
            ),
            raw.get(..timezone_offset).unwrap(),
        ),
        _ => parse_datetime_at_date(Zoned::new(Timestamp::UNIX_EPOCH, TimeZone::UTC), raw),
    }
    .ok()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn it_gets_cataloged_date_from_876() {
        let record =
            Record::from_breaker("=876 \\$022710806450006421$d2021-07-13 12:24:58").unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }

    #[test]
    fn it_gets_first_date_when_multiple_876() {
        let record = Record::from_breaker(
            "=876 \\$022710806450006421$d2021-07-15 12:24:58
=876 \\$022710806450006421$d2021-07-13 12:24:58
=876 \\$022710806450006421$d2021-07-17 12:24:58
=876 \\$022710806450006421$d2021-07-16 12:24:58",
        )
        .unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }

    #[test]
    fn it_gets_cataloged_date_from_active_951_portfolio() {
        let record =
            Record::from_breaker("=951 \\$aAvailable$8531026240820006421$w2021-07-13 12:24:58")
                .unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }

    #[test]
    fn it_gets_cataloged_date_from_950_record_date() {
        let record = Record::from_breaker("=950 \\$b2021-07-13 12:24:58").unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }

    #[test]
    fn it_prefers_the_876_date() {
        let record = Record::from_breaker(
            "=876 \\$022710806450006421$d2021-07-13 12:24:58
=951 \\$aAvailable$8531026240820006421$1995-07-13 12:24:58
=950 \\$b2030-07-13 12:24:58",
        )
        .unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2021-07-13T12:24:58Z".to_owned())
        )
    }

    #[test]
    fn it_can_handle_a_date_containing_a_timezone() {
        let record = Record::from_breaker(
            "=876 \\$022620045470006421$j1$zmap$a23936494400006421$d2022-07-19 15:37:46 US/Eastern",
        )
        .unwrap();
        assert_eq!(
            cataloged_date(&record),
            Some("2022-07-19T19:37:46Z".to_owned())
        )
    }

    #[test]
    fn it_sorts_dates_in_the_expected_order() {
        let a = Record::from_breaker(r#"=001 9960625923506421
=950 \\$c2026-07-13 21:02:18 US/Eastern$b2021-07-12 16:07:37 US/Eastern$afalse
=951 \\$v2021-07-20 19:46:35 US/Eastern$uSystem$t2021-07-20 19:46:27 US/Eastern$xhttps://na05-psb.alma.exlibrisgroup.com/view/uresolver/01PRI_INST/openurl?u.ignore_date_coverage=true&portfolio_pid=53889735050006421&Force_direct=true$sP2E_JOB$053889735050006421$w2021-07-20 23:46:27$ffalse$bstatic$152889735060006421$cd?u.ignore_date_coverage=true&rft.mms_id=9960625923506421$iSee the map$aAvailable$eMAP$853889735050006421
=852 8\$brare$cmap$hHMC01.3002$kD Alcove 22, Drawer 2$822564482900006421
=952 \\$d2022-08-10 14:57:06$822564482900006421$a2021-07-12 20:07:37$bSpecial Collections$cmap: Rare Books Historic Map Collection$efalse
=876 \\$022564482900006421$j1$zmap$p32101071578759$t1$a23564482890006421$d2010-03-01 19:00:00 US/Eastern$q2010-03-02 05:59:00 US/Eastern$yrare"#).unwrap();
        let b = Record::from_breaker(r#"=001 9967685993506421
=950 \\$c2026-07-14 00:33:49 US/Eastern$b2021-07-13 07:32:59 US/Eastern$afalse
=852 0\$bmarquand$cpj$hDC801.G82$iC66 2008$822730992450006421
=952 \\$a2021-07-13 11:32:59$822730992450006421$bMarquand Library$crcppj: Marquand Remote Storage (ReCAP)$efalse
=876 \\$022730992450006421$j1$zpj$p32101079262919$t1$a23730992440006421$d2011-11-06 19:00:00 US/Eastern$q2011-11-07 05:59:00 US/Eastern$ymarquand"#).unwrap();
        let c = Record::from_breaker(r#"=001 99125541697806421
=950 \\$c2023-01-26 04:21:59 US/Eastern$b2022-07-30 18:00:20 US/Eastern$afalse
=852 0\$bmarquand$cpj$hN6851.N53$iN53 2022q$kOversize$822938488440006421
=952 \\$d2022-10-14 13:17:42$822938488440006421$a2022-07-30 22:00:28$bMarquand Library$crcppj: Marquand Remote Storage (ReCAP)$efalse
=876 \\$022938488440006421$j1$zpj$p32101118680485$a23938488420006421$d2022-07-30 18:00:28 US/Eastern$q2022-10-13 10:56:33 US/Eastern$ymarquand"#).unwrap();

        let dates = [
            cataloged_date(&a).unwrap(),
            cataloged_date(&b).unwrap(),
            cataloged_date(&c).unwrap(),
        ];
        let mut sorted = dates.clone();
        sorted.sort();
        assert_eq!(dates, sorted);
    }
}
