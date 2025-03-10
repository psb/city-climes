extern crate fetch_pages;
extern crate parse_pages;
extern crate rayon;
extern crate sqlite;
extern crate types;

use rayon::prelude::*;
use std::error::Error;
use std::fs::File;
use std::io::prelude::*;

use fetch_pages::fetch_page;
use parse_pages::parse_page;
use sqlite::save_page;
use types::*;

pub fn run(config: Config) -> Result<(), Box<Error>> {
    let mut f = File::open(&config.filename).expect("Input file not found.");

    let mut contents = String::new();
    f.read_to_string(&mut contents)?;

    contents.par_lines().for_each(|page| {
        let fetch_result = fetch_page(page);
        let parse_result = parse_page(fetch_result);
        let _ = save_page(&config.db_path, parse_result);
    });

    // for page in contents.lines() {
    //     let fetch_result = fetch_page(page);
    //     let parse_result = parse_page(fetch_result);
    //     let _ = save_page(&config.db_path, parse_result);
    // }

    Ok(())
}
