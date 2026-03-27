use figgy_marc::{FiggyMarcConfig, fetch_report};
use std::env;

fn main() {
    let config =
        FiggyMarcConfig::try_new(env::var).expect("Could not determine the correct configuration");
    let body = fetch_report(&config).expect("Could not fetch report from Figgy");
    print!("Got {} records from Figgy", body.len());
}
