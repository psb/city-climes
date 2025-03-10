extern crate fetch_and_parse_climate_pages;
extern crate types;

use std::env;
use std::process;

use types::Config;

fn main() {
    let config = Config::new(env::args()).unwrap_or_else(|err| {
        eprintln!("Problem parsing arguments: {}", err);
        process::exit(1);
    });

    if let Err(e) = fetch_and_parse_climate_pages::run(config) {
        eprintln!("Application error: {}", e);
        process::exit(1);
    }
}
