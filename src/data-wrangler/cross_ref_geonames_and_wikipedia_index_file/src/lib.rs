extern crate rayon;
extern crate regex;

use rayon::prelude::*;
// use regex::RegexBuilder;
use std::collections::HashSet;
use std::error::Error;
use std::fs;
use std::fs::File;
use std::io::prelude::*;

pub struct Config {
    pub geonames_file: String,
    pub wikipedia_index_file: String,
    pub output_directory: String,
}

impl Config {
    pub fn new(mut args: std::env::Args) -> Result<Config, &'static str> {
        args.next();

        let geonames_file = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a geonames file path."),
        };

        let wikipedia_index_file = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a wikipedia index file path."),
        };

        let output_directory = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a output directory path."),
        };

        Ok(Config {
            geonames_file,
            wikipedia_index_file,
            output_directory,
        })
    }
}

pub fn run(config: Config) -> Result<(), Box<Error>> {
    let geonames_file =
        fs::read_to_string(config.geonames_file).expect("Unable to read geonames file");
    let wikipedia_index_file = fs::read_to_string(config.wikipedia_index_file)
        .expect("Unable to read wikipedia index file");
    let out_file_path = format!("{}cross_ref_pages_to_fetch.txt", config.output_directory);
    let mut out_file = File::create(out_file_path).expect("Could not create file");

    let cities = extract_cities(geonames_file);
    // println!("{:?}", cities.contains(""));

    let pages: Vec<_> = wikipedia_index_file
        .par_lines()
        .filter_map(|line| {
            let split_line: Vec<&str> = line.split(':').collect();
            let page = split_line.last().unwrap().trim().to_string();
            // println!("Page: {:?}", page);

            if cities.contains(&page) {
                println!("Match: {:?}", &page);
                Some(page)
            } else {
                None
            }
        })
        .collect();

    for page in pages {
        // println!("Page: {:?}", page);
        write!(out_file, "{}\r\n", page).expect("Unable to write to file.");
    }

    Ok(())
}

fn extract_cities(geonames_file: String) -> HashSet<String> {
    let mut cities = HashSet::new();

    for line in geonames_file.lines() {
        let mut names: Vec<String> = Vec::new();

        let split_line: Vec<&str> = line.split('\t').collect();

        names.push(split_line[1].trim().to_string()); // utf8 name
        names.push(split_line[2].trim().to_string()); // ascii name
        split_line[3] // alternative names list
            .split(',')
            .for_each(|name| names.push(name.trim().to_string()));
        split_line[17] // time zone
            .split('/')
            .for_each(|name| names.push(name.trim().to_string()));

        // println!("{:?}", names);
        for name in names {
            cities.insert(name);
        }
    }
    cities.remove("");

    cities
}

mod test {
    // use super::*;

    #[test]
    fn case_senstive() {}
}
