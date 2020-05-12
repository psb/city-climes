use std::collections::HashSet;
use std::error::Error;
use std::fs::File;
use std::io::prelude::*;

pub struct Config {
    pub filename: String,
    pub output_directory: String,
}

impl Config {
    pub fn new(mut args: std::env::Args) -> Result<Config, &'static str> {
        args.next();

        let filename = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a geonames cities file path."),
        };

        let output_directory = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a output directory path."),
        };

        Ok(Config {
            filename,
            output_directory,
        })
    }
}

pub fn run(config: Config) -> Result<(), Box<Error>> {
    let mut f = File::open(config.filename).expect("file not found");

    let mut contents = String::new();

    f.read_to_string(&mut contents)?;

    let city_pages: HashSet<&str> = contents
        .lines()
        .map(|line| {
            let split_line: Vec<&str> = line.split('\t').collect();
            split_line[1]
        })
        .collect();

    let full_path = format!("{}{}", &config.output_directory, "pages_to_fetch.txt");
    let mut f = File::create(full_path).expect("Could not create file");

    for page in city_pages {
        write!(f, "{}\r\n", page)?;
    }

    Ok(())
}

mod test {
    // use super::*;

    #[test]
    fn case_senstive() {}
}
