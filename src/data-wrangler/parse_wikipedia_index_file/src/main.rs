extern crate parse_wikipedia_index_file;

use std::env;
use std::process;

use parse_wikipedia_index_file::Config;

fn main() {
    let config = Config::new(env::args()).unwrap_or_else(|err| {
        eprintln!("Problem parsing arguments: {}", err);
        process::exit(1);
    });

    if let Err(e) = parse_wikipedia_index_file::run(config) {
        eprintln!("Application error: {}", e);
        process::exit(1);
    }
}
