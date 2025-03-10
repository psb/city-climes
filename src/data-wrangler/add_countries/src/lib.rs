extern crate rayon;
extern crate regex;
extern crate serde;
#[macro_use]
extern crate serde_json;
#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate lazy_static;
extern crate reqwest;
extern crate scraper;

use rayon::prelude::*;
use regex::Regex;
use reqwest::{Client, Response};
use scraper::element_ref::ElementRef;
use scraper::{Html, Selector};
use std::error::Error;
use std::fs;
use std::fs::File;
use std::io::prelude::*;

lazy_static! {
    static ref CLIENT: Client = Client::new();
    static ref COUNTRY: Regex = Regex::new(r"(?i)country").unwrap();
}

pub struct Config {
    pub json_file: String,
    pub output_directory: String,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct Location {
    ID: u32,
    WikipediaURL: String,
    LocationName: String,
    AverageHighC: Vec<f64>,
    AverageLowC: Vec<f64>,
    AverageHighF: Vec<f64>,
    AverageLowF: Vec<f64>,
    SunshineHours: Option<Vec<f64>>,
    Country: Option<String>,
}

impl Config {
    pub fn new(mut args: std::env::Args) -> Result<Config, &'static str> {
        args.next();

        let json_file = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a json file path."),
        };

        let output_directory = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a output directory path."),
        };

        Ok(Config {
            json_file,
            output_directory,
        })
    }
}

pub fn run(config: Config) -> Result<(), Box<Error>> {
    let json_file = fs::read_to_string(config.json_file).expect("Unable to read json file");

    let out_file_path = format!("{}CityClimesCountries.json", config.output_directory);
    let mut out_file = File::create(out_file_path).expect("Could not create file");

    let locations: Vec<Location> = serde_json::from_str(&json_file)?;

    // let new_locations: Vec<Location> = locations[375..425]
    let new_locations: Vec<Location> = locations
        .par_iter()
        .map(|location| add_country(location.clone()))
        .collect();
    // println!("{:?}", new_locations);

    write!(out_file, "{}", json!(new_locations).to_string()).expect("Unable to write to file.");

    Ok(())
}

fn add_country(location: Location) -> Location {
    let resp = fetch_page(&location.LocationName);
    if resp.is_ok() {
        let mut fetch_result = resp.unwrap();
        if fetch_result.status().is_success() {
            println!("Fetch -> Page: {:?}", &location.LocationName);
            let html = fetch_result.text().unwrap();
            let country = extract_country(html);
            match country {
                Some(c) => {
                    println!("Country: {:?}", &c);
                    Location {
                        Country: Some(c),
                        ..location
                    }
                }
                None => {
                    println!("No Country Found: {:?}", &location.LocationName);
                    Location {
                        Country: None,
                        ..location
                    }
                }
            }
        } else {
            println!("Fetch -> StatusError: {:?}", &location.LocationName);
            Location {
                Country: None,
                ..location
            }
        }
    } else {
        println!("Fetch -> FetchError: {:?}", resp);
        Location {
            Country: None,
            ..location
        }
    }
}

pub fn fetch_page(page: &str) -> Result<Response, reqwest::Error> {
    let url = create_restbase_url(&page);
    let resp = CLIENT.get(&url).send();
    resp
}

fn create_restbase_url(page: &str) -> String {
    format!(
        "https://en.wikipedia.org/api/rest_v1/page/html/{}?redirect=true",
        page.replace(" ", "_")
    )
}

fn extract_country(html: String) -> Option<String> {
    let doc = Html::parse_document(&html);
    let table_selector = Selector::parse("table.infobox.vcard").unwrap();
    let tables = doc.select(&table_selector);
    let tables = tables.map(|table| (table_data(table)));
    let tables_with_country = tables
        .filter(|table| {
            table
                .into_iter()
                .any(|row| row.into_iter().any(|cell| COUNTRY.is_match(cell)))
        })
        .collect::<Vec<_>>();

    // println!("{:?}\n", &tables_with_country);

    if tables_with_country.is_empty() {
        None
    } else {
        let row_with_country = tables_with_country
            .first()
            .unwrap()
            .into_iter()
            .filter(|row| row.into_iter().any(|cell| COUNTRY.is_match(cell)))
            .collect::<Vec<_>>();

        let country = row_with_country[0].last().unwrap();

        // println!("{:?}\n", country);
        Some(country.to_string())
    }
}

fn table_data(table: ElementRef) -> Vec<Vec<&str>> {
    let row_selector = Selector::parse("tr").unwrap();

    let rows = table.select(&row_selector);
    rows.map(|row| {
        row.text()
            .map(|cell| cell.trim())
            .filter(|cell| *cell != "")
            .collect::<Vec<_>>()
    }).collect::<Vec<_>>()
}

mod test {
    // use super::*;

    #[test]
    fn case_senstive() {}
}
