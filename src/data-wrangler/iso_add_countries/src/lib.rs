extern crate regex;
extern crate serde;
#[macro_use]
extern crate serde_json;
#[macro_use]
extern crate serde_derive;
#[macro_use]
extern crate lazy_static;

use regex::Regex;
use std::collections::HashMap;
use std::error::Error;
use std::fs;
use std::fs::File;
use std::io::prelude::*;

lazy_static! {
    static ref COUNTRY: Regex = Regex::new(r"(?i)country").unwrap();
}

pub struct Config {
    pub json_file: String,
    pub cities_file: String,
    pub continents_file: String,
    pub isos_file: String,
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
    ISOCode: Option<String>,
    Continent: Option<String>,
}

impl Config {
    pub fn new(mut args: std::env::Args) -> Result<Config, &'static str> {
        args.next();

        let json_file = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a json file path."),
        };

        let cities_file = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a cities file path."),
        };

        let continents_file = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a continents file path."),
        };

        let isos_file = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a iso codes file path."),
        };

        let output_directory = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a output directory path."),
        };

        Ok(Config {
            json_file,
            cities_file,
            continents_file,
            isos_file,
            output_directory,
        })
    }
}

pub fn run(config: Config) -> Result<(), Box<Error>> {
    let json_file = fs::read_to_string(config.json_file).expect("Unable to read json file");
    let cities_file = fs::read_to_string(config.cities_file).expect("Unable to read cities file");
    let continents_file =
        fs::read_to_string(config.continents_file).expect("Unable to read continents file");
    let isos_file = fs::read_to_string(config.isos_file).expect("Unable to read iso file");

    let out_file_path = format!("{}CityClimesCountriesISO.json", config.output_directory);
    let mut out_file = File::create(out_file_path).expect("Could not create file");

    let locations: Vec<Location> = serde_json::from_str(&json_file)?;
    let cities: HashMap<&str, Vec<&str>> = cities_hashmap(&cities_file);
    let continents: HashMap<&str, &str> = continents_hashmap(&continents_file);
    let isos: HashMap<&str, (&str, &str)> = isos_hashmap(&isos_file);

    // println!("{:?}", &cities.get(&"AX"));
    // let new_locations: Vec<Location> = locations[375..425]
    let new_locations: Vec<Location> = locations
        .iter()
        .map(|location| update_location(location.clone(), &cities, &continents, &isos))
        .collect();
    // println!("{:?}", new_locations);

    write!(out_file, "{}", json!(new_locations).to_string()).expect("Unable to write to file.");

    Ok(())
}

fn cities_hashmap(cities: &str) -> HashMap<&str, Vec<&str>> {
    let mut map: HashMap<&str, Vec<&str>> = HashMap::new();

    for line in cities.lines() {
        let cols: Vec<&str> = line.split('\t').collect();
        let iso: &str = cols[8].trim();
        let name: &str = cols[1].trim();
        let ascii_name: &str = cols[2];
        let mut alt_names: Vec<&str> = cols[3].split(',').map(|n| n.trim()).collect();

        alt_names.push(name);
        alt_names.push(ascii_name);

        if map.contains_key(iso) {
            if let Some(vals) = map.get_mut(iso) {
                vals.append(&mut alt_names);
            }
        } else {
            map.insert(iso, alt_names);
        }
    }

    map
}

fn continents_hashmap(continents: &str) -> HashMap<&str, &str> {
    let mut map: HashMap<&str, &str> = HashMap::new();

    for line in continents.lines() {
        let cols: Vec<&str> = line.split(',').collect();
        let iso: &str = cols[0].trim();
        let continent: &str = cols[1].trim();

        map.insert(iso, continent);
    }

    map
}

fn isos_hashmap(isos: &str) -> HashMap<&str, (&str, &str)> {
    let mut map: HashMap<&str, (&str, &str)> = HashMap::new();

    for line in isos.lines() {
        let cols: Vec<&str> = line.split('\t').collect();
        let iso: &str = cols[0].trim();
        let country: &str = cols[4].trim();
        let continent: &str = cols[8].trim();

        map.insert(iso, (country, continent));
    }

    map
}

fn update_location(
    location: Location,
    cities: &HashMap<&str, Vec<&str>>,
    continents: &HashMap<&str, &str>,
    isos: &HashMap<&str, (&str, &str)>,
) -> Location {
    let location_name = location
        .LocationName
        .split(',')
        .collect::<Vec<&str>>()
        .first()
        .unwrap()
        .trim()
        .clone();

    let mut iso_code: Option<&str> = None;
    for (key, vals) in cities.iter() {
        if vals.contains(&location_name) {
            iso_code = Some(key);
        }
    }

    match iso_code {
        Some(code) => {
            if let Some((country, continent_iso_code)) = isos.get(code) {
                let continent = continents.get(continent_iso_code);

                Location {
                    LocationName: location_name.to_string(),
                    Country: Some(country.to_string()),
                    ISOCode: Some(code.to_string()),
                    Continent: continent.map(|c| c.to_string()),
                    ..location
                }
            } else {
                Location {
                    LocationName: location_name.to_string(),
                    Country: None,
                    ISOCode: Some(code.to_string()),
                    Continent: None,
                    ..location
                }
            }
        }
        None => Location {
            LocationName: location_name.to_string(),
            Country: None,
            ISOCode: None,
            Continent: None,
            ..location
        },
    }
}

mod test {
    // use super::*;

    #[test]
    fn case_senstive() {}
}
