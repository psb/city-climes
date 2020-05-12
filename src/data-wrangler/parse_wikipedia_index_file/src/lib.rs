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
            None => return Err("Didn't get a file path."),
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

    let (climate_pages, geography_pages) = pages(&contents);

    let mut pages_to_fetch = Vec::new();
    pages_to_fetch.append(&mut climate_pages.clone());
    pages_to_fetch.append(&mut geography_pages.clone());

    let fixed_pages_to_fetch = fix_ampersands(&pages_to_fetch);

    let fixed_pages_to_fetch_strs: Vec<&str> =
        fixed_pages_to_fetch.iter().map(AsRef::as_ref).collect();

    write_file(&config.output_directory, "climate_pages.txt", climate_pages)?;
    write_file(
        &config.output_directory,
        "geography_pages.txt",
        geography_pages,
    )?;
    write_file(
        &config.output_directory,
        "pages_to_fetch.txt",
        fixed_pages_to_fetch_strs,
    )?;

    Ok(())
}

fn pages<'a>(contents: &'a str) -> (Vec<&'a str>, Vec<&'a str>) {
    let mut climate_pages: Vec<&str> = Vec::new();
    let mut geography_pages: Vec<&str> = Vec::new();

    for line in contents.lines() {
        let split_line: Vec<&str> = line.split(':').collect();
        let page = split_line[2];

        if page.starts_with("Climate of ") {
            climate_pages.push(page);
        } else if page.starts_with("Geography of ") {
            geography_pages.push(page);
        }
    }

    climate_pages.sort();
    geography_pages.sort();

    (climate_pages, geography_pages)
}

fn fix_ampersands<'a>(pages_to_fetch: &Vec<&'a str>) -> Vec<String> {
    pages_to_fetch
        .into_iter()
        .map(|page| page.replace(" &amp; ", " & "))
        .collect()
}

fn write_file(
    output_directory: &str,
    filename: &str,
    page_list: Vec<&str>,
) -> Result<(), Box<Error>> {
    let full_path = format!("{}{}", output_directory, filename);
    let mut f = File::create(full_path).expect("Could not create file");

    for page in page_list {
        write!(f, "{}\r\n", page)?;
    }

    Ok(())
}

mod test {
    // use super::*;

    #[test]
    fn case_senstive() {}
}
