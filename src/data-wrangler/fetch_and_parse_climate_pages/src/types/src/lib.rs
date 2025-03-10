extern crate rusqlite;
extern crate serde_json;

use rusqlite::types::{ToSql, ToSqlOutput};
use serde_json::Value;

pub struct Config {
    pub filename: String,
    pub db_path: String,
}

impl Config {
    pub fn new(mut args: std::env::Args) -> Result<Config, &'static str> {
        args.next();

        let filename = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a file path."),
        };

        let db_path = match args.next() {
            Some(arg) => arg,
            None => return Err("Didn't get a database path."),
        };

        Ok(Config { filename, db_path })
    }
}

#[derive(Debug)]
pub enum FetchResult {
    Page,
    FetchError,
    StatusError,
}

impl ToSql for FetchResult {
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput> {
        match &self {
            FetchResult::Page => Ok(ToSqlOutput::from("Page")),
            FetchResult::FetchError => Ok(ToSqlOutput::from("FetchError")),
            FetchResult::StatusError => Ok(ToSqlOutput::from("StatusError")),
        }
    }
}

#[derive(Debug)]
pub enum TemperatureTableType {
    Regular,
    Irregular,
    Infobox,
}

impl ToSql for TemperatureTableType {
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput> {
        match &self {
            TemperatureTableType::Regular => Ok(ToSqlOutput::from("Regular")),
            TemperatureTableType::Irregular => Ok(ToSqlOutput::from("Irregular")),
            TemperatureTableType::Infobox => Ok(ToSqlOutput::from("Infobox")),
        }
    }
}

#[derive(Debug)]
pub enum ParseResult {
    Parsed,
    ParseError,
    NoValidTablesFound,
}

impl ToSql for ParseResult {
    fn to_sql(&self) -> rusqlite::Result<ToSqlOutput> {
        match &self {
            ParseResult::Parsed => Ok(ToSqlOutput::from("Parsed")),
            ParseResult::ParseError => Ok(ToSqlOutput::from("ParseError")),
            ParseResult::NoValidTablesFound => Ok(ToSqlOutput::from("NoValidTablesFound")),
        }
    }
}

#[derive(Debug)]
pub struct PageResult {
    pub page_name: String,
    pub fetch_result: FetchResult,
    pub response_url: Option<String>,
    pub status_code: Option<u16>,
    pub content_location_url: Option<String>,
    pub wikipedia_url: Option<String>,
    pub location_name: Option<String>,
    pub table_html: Option<String>,
    pub temperature_table_type: Option<TemperatureTableType>,
    pub average_high_c: Option<Value>,
    pub average_low_c: Option<Value>,
    pub average_high_f: Option<Value>,
    pub average_low_f: Option<Value>,
    pub sunshine_hours: Option<Value>,
    pub parse_result: Option<ParseResult>,
}

impl Default for PageResult {
    fn default() -> PageResult {
        PageResult {
            page_name: String::new(),
            fetch_result: FetchResult::FetchError,
            response_url: None,
            status_code: None,
            content_location_url: None,
            wikipedia_url: None,
            location_name: None,
            table_html: None,
            temperature_table_type: None,
            average_high_c: None,
            average_low_c: None,
            average_high_f: None,
            average_low_f: None,
            sunshine_hours: None,
            parse_result: None,
        }
    }
}

#[derive(Debug)]
pub struct TableRows {
    pub average_high_c: Option<Value>,
    pub average_low_c: Option<Value>,
    pub average_high_f: Option<Value>,
    pub average_low_f: Option<Value>,
    pub sunshine_hours: Option<Value>,
}

#[derive(Debug)]
pub struct InfoboxRows {
    pub average_high_c: Option<Value>,
    pub average_low_c: Option<Value>,
    pub average_high_f: Option<Value>,
    pub average_low_f: Option<Value>,
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
