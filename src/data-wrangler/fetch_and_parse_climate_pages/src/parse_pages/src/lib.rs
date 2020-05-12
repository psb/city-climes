#[macro_use]
extern crate lazy_static;
extern crate regex;
extern crate scraper;
#[macro_use]
extern crate serde_json;
extern crate types;

use regex::Regex;
use scraper::element_ref::ElementRef;
use scraper::{Html, Selector};
use serde_json::Value;
use std::num::ParseFloatError;
use types::{InfoboxRows, PageResult, ParseResult, TableRows, TemperatureTableType};

type HasSunshineHours = bool;

lazy_static! {
    static ref SUNSHINE: Regex = Regex::new(r"(?i)sunshine hours").unwrap();
    static ref AVERAGE_HIGH: Regex = Regex::new(r"(?i)(^average high|^high temperature)").unwrap();
    static ref AVERAGE_LOW: Regex = Regex::new(r"(?i)(^average low|^low temperature)").unwrap();
    static ref FAHRENHEIT: Regex = Regex::new(r"(?i)\(.+F\)").unwrap();
    static ref IMPERIAL: Regex = Regex::new(r"(?i)^imperial").unwrap();
    static ref MONTH: Regex = Regex::new(r"(?i)month").unwrap();
    static ref DAILY: Regex = Regex::new(r"(?i)daily").unwrap();
}

pub fn parse_page(page: (PageResult, Option<String>)) -> PageResult {
    let (page_result, html) = page;
    if html.is_none() {
        page_result
    } else {
        let doc = Html::parse_document(&html.unwrap());
        let regular_table = extract_regular_temperature_table(&doc);
        let irregular_table = extract_irregular_temperature_table(&doc);
        let infobox = extract_infobox_temperature_table(&doc);

        match (regular_table, irregular_table, infobox) {
            (Some((has_sunshine_hours, (table, table_html))), _, _) => {
                if let Ok(table_rows) = extract_table_data(has_sunshine_hours, table) {
                    println!("Parse -> Parsed: {:?}", &page_result.page_name);
                    PageResult {
                        table_html: table_html,
                        temperature_table_type: Some(TemperatureTableType::Regular),
                        average_high_c: table_rows.average_high_c,
                        average_low_c: table_rows.average_low_c,
                        average_high_f: table_rows.average_high_f,
                        average_low_f: table_rows.average_low_f,
                        sunshine_hours: table_rows.sunshine_hours,
                        parse_result: Some(ParseResult::Parsed),
                        ..page_result
                    }
                } else {
                    println!("Parse -> ParseError: {:?}", &page_result.page_name);
                    PageResult {
                        table_html: table_html,
                        temperature_table_type: Some(TemperatureTableType::Regular),
                        parse_result: Some(ParseResult::ParseError),
                        ..page_result
                    }
                }
            }
            (_, Some((has_sunshine_hours, table)), _) => {
                if let Ok(table_rows) = extract_table_data(has_sunshine_hours, table) {
                    println!("Parse -> Parsed: {:?}", &page_result.page_name);
                    PageResult {
                        temperature_table_type: Some(TemperatureTableType::Irregular),
                        average_high_c: table_rows.average_high_c,
                        average_low_c: table_rows.average_low_c,
                        average_high_f: table_rows.average_high_f,
                        average_low_f: table_rows.average_low_f,
                        sunshine_hours: table_rows.sunshine_hours,
                        parse_result: Some(ParseResult::Parsed),
                        ..page_result
                    }
                } else {
                    println!("Parse -> ParseError: {:?}", &page_result.page_name);
                    PageResult {
                        temperature_table_type: Some(TemperatureTableType::Irregular),
                        parse_result: Some(ParseResult::ParseError),
                        ..page_result
                    }
                }
            }
            (_, _, Some((table1, table2))) => {
                if let Ok(infobox_rows) = extract_infobox_data(table1, table2) {
                    println!("Parse -> Parsed: {:?}", &page_result.page_name);
                    PageResult {
                        temperature_table_type: Some(TemperatureTableType::Infobox),
                        average_high_c: infobox_rows.average_high_c,
                        average_low_c: infobox_rows.average_low_c,
                        average_high_f: infobox_rows.average_high_f,
                        average_low_f: infobox_rows.average_low_f,
                        parse_result: Some(ParseResult::Parsed),
                        ..page_result
                    }
                } else {
                    println!("Parse -> ParseError: {:?}", &page_result.page_name);
                    PageResult {
                        temperature_table_type: Some(TemperatureTableType::Infobox),
                        parse_result: Some(ParseResult::ParseError),
                        ..page_result
                    }
                }
            }
            _ => {
                println!(
                    "Parse -> No Valid Tables Found: {:?}",
                    &page_result.page_name
                );
                PageResult {
                    parse_result: Some(ParseResult::NoValidTablesFound),
                    ..page_result
                }
            }
        }
    }
}

fn extract_regular_temperature_table(
    doc: &Html,
) -> Option<(HasSunshineHours, (Vec<Vec<&str>>, Option<String>))> {
    let table_selector = Selector::parse("table.wikitable").unwrap();

    let tables = doc.select(&table_selector);

    let tables = tables.map(|table| (table_data(table), Some(table.html())));

    let mut tables_with_temperatures = tables
        .filter(|(table, _)| {
            table.into_iter().any(|row| {
                row.contains(&"Month")
                    && row.contains(&"Jan")
                    && row.contains(&"Feb")
                    && row.contains(&"Dec")
            })
        })
        .filter(|(table, _)| {
            table
                .into_iter()
                .any(|row| row.into_iter().any(|cell| AVERAGE_HIGH.is_match(cell)))
        })
        .filter(|(table, _)| {
            table
                .into_iter()
                .any(|row| row.into_iter().any(|cell| AVERAGE_LOW.is_match(cell)))
        })
        .collect::<Vec<_>>();

    // println!("\nTEMPERATURE TABLES: {:?}\n", &tables_with_temperatures);

    let mut tables_with_sunshine_hours = tables_with_temperatures
        .clone()
        .into_iter()
        .filter(|(table, _)| {
            table
                .into_iter()
                .any(|row| row.into_iter().any(|cell| SUNSHINE.is_match(cell)))
        })
        .collect::<Vec<_>>();

    match (
        tables_with_temperatures.is_empty(),
        tables_with_sunshine_hours.is_empty(),
    ) {
        (true, true) => None,
        (_, false) => Some((true, tables_with_sunshine_hours.remove(0))),
        (false, _) => Some((false, tables_with_temperatures.remove(0))),
    }
}

fn extract_irregular_temperature_table(doc: &Html) -> Option<(HasSunshineHours, Vec<Vec<&str>>)> {
    let table_selector = Selector::parse("table.wikitable").unwrap();

    let tables = doc.select(&table_selector);

    let tables = tables.map(|table| table_data(table));

    let mut tables_with_temperatures = tables
        .filter(|table| {
            table.into_iter().any(|row| {
                row.contains(&"Average")
                    && row.contains(&"Jan")
                    && row.contains(&"Feb")
                    && row.contains(&"Dec")
            })
        })
        .collect::<Vec<_>>();

    let tables_with_sunshine_hours = tables_with_temperatures
        .clone()
        .into_iter()
        .filter(|table| {
            table
                .into_iter()
                .any(|row| row.into_iter().any(|cell| SUNSHINE.is_match(cell)))
        })
        .collect::<Vec<_>>();

    match (
        tables_with_temperatures.is_empty(),
        tables_with_sunshine_hours.is_empty(),
    ) {
        (true, true) => None,
        (true, false) => None,
        (false, true) => Some((false, tables_with_temperatures.remove(0))),
        (false, false) => {
            let mut table = tables_with_temperatures.remove(0);

            let mut sunshine_rows = tables_with_sunshine_hours
                .first()
                .unwrap()
                .into_iter()
                .filter(|row| row.into_iter().any(|cell| SUNSHINE.is_match(cell)))
                .collect::<Vec<_>>();

            table.push(sunshine_rows.remove(0).to_vec());

            Some((true, table))
        }
    }
}

fn extract_infobox_temperature_table(doc: &Html) -> Option<(Vec<Vec<&str>>, Vec<Vec<&str>>)> {
    let table_selector = Selector::parse(".infobox").unwrap();

    let tables = doc.select(&table_selector);

    let tables = tables.map(|table| table_data(table));

    let mut tables_with_temperatures = tables
        .filter(|table| {
            table
                .into_iter()
                .any(|row| row == &vec!["J", "F", "M", "A", "M", "J", "J", "A", "S", "O", "N", "D"])
        })
        .collect::<Vec<_>>();

    if tables_with_temperatures.is_empty() || tables_with_temperatures.len() > 9 {
        // Infobox tables are split into 3 returned results per table,
        // i.e. 3 infobox tables on wikipedia equals 9 returned results.
        // A high number of results appears on country level pages,
        // e.g. Climate of Brazil; therefore, ignore.
        return None;
    } else {
        // Items 1 and 2 are the cleaner tables of metric and imperial data
        // or visa-versa.
        Some((
            tables_with_temperatures.remove(1),
            tables_with_temperatures.remove(1),
        ))
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

fn extract_table_data(
    has_sunshine_hours: HasSunshineHours,
    table: Vec<Vec<&str>>,
) -> Result<TableRows, String> {
    // println!("{} - {:?}", has_sunshine_hours, table);

    let months_row = &table
        .iter()
        .filter(|row| {
            row.contains(&"Jan")
                && row.contains(&"Feb")
                && row.contains(&"May")
                && row.contains(&"Dec")
        })
        .next()
        .unwrap();

    let jan_index: usize = months_row.iter().position(|&month| month == "Jan").unwrap();
    let dec_index: usize = months_row.iter().position(|&month| month == "Dec").unwrap();

    // println!("\n\n{:?}", &months_row);

    let average_high_rows = filter_for_rows(&table, &AVERAGE_HIGH);

    // println!("\nAverage high rows: {:?}", &average_high_rows);
    // println!("Average high rows length: {:?}", &average_high_rows.len());

    let average_low_rows = filter_for_rows(&table, &AVERAGE_LOW);

    // println!("Average low rows: {:?}", &average_low_rows);
    // println!("Average low rows length: {:?}", &average_low_rows.len());

    // Some tables have celsius and fahrenheit values on separate rows instead of
    // using parentheses:
    let average_high_row;
    let average_low_row;
    if average_high_rows.len() == 2 && average_low_rows.len() == 2 {
        // Format the data to look like table rows that use parenthesis,
        // which is the majority:
        let mut combined_average_high_row = vec!["Average high oC (oF)"];
        if average_high_rows[0][0].contains("F") {
            average_high_rows[1][1..]
                .iter()
                .zip(&average_high_rows[0][1..])
                .for_each(|(t1, t2)| {
                    combined_average_high_row.push(t1);
                    combined_average_high_row.push(t2);
                });
        } else {
            average_high_rows[0][1..]
                .iter()
                .zip(&average_high_rows[1][1..])
                .for_each(|(t1, t2)| {
                    combined_average_high_row.push(t1);
                    combined_average_high_row.push(t2);
                });
        }
        let mut combined_average_low_row = vec!["Average low oC (oF)"];
        if average_low_rows[0][0].contains("F") {
            average_low_rows[1][1..]
                .iter()
                .zip(&average_low_rows[0][1..])
                .for_each(|(t1, t2)| {
                    combined_average_low_row.push(t1);
                    combined_average_low_row.push(t2);
                });
        } else {
            average_low_rows[0][1..]
                .iter()
                .zip(&average_low_rows[1][1..])
                .for_each(|(t1, t2)| {
                    combined_average_low_row.push(t1);
                    combined_average_low_row.push(t2);
                });
        }
        average_high_row = combined_average_high_row;
        average_low_row = combined_average_low_row;
    } else {
        average_high_row = average_high_rows[0].clone();
        average_low_row = average_low_rows[0].clone();
        // If there is only one average row it should contain both the celsius and
        // fahrenheit values. Discard data if not:
        let label_test = &average_high_row[0];
        if !(label_test.contains("C") && label_test.contains("F")) {
            return Err("Does not have celsius AND fahrenheit values.".to_string());
        }
    }
    // println!("Average high row: {:?}", &average_high_row);
    // println!("Average low row: {:?}", &average_low_row);

    let sunshine_rows: Vec<Vec<&str>>;
    let sunshine_row;
    if has_sunshine_hours {
        let sun_rows = filter_for_rows(&table, &SUNSHINE);
        if sun_rows.len() > 1 {
            sunshine_rows = sun_rows
                .iter()
                .filter(|row| row.into_iter().any(|cell| MONTH.is_match(cell)))
                .cloned()
                .collect();
        } else {
            sunshine_rows = sun_rows;
        }
        sunshine_row = Some(&sunshine_rows[0]);
    // println!("Sun rows: {:?}", &sun_rows);
    // println!("Sunshine rows: {:?}", &sunshine_rows);
    // println!("Sunshine row: {:?}", &sunshine_row);
    } else {
        sunshine_row = None;
    }

    let label = &average_high_row[0];
    // println!("{:?}", label);

    let average_high_values: Vec<&str>;
    let average_low_values: Vec<&str>;
    if months_row.len() == average_high_row.len() {
        // Is irregular table data.
        // Make it into the same format as regular table data.
        average_high_values = average_high_row[jan_index..=dec_index]
            .iter()
            .flat_map(|pair| pair.split(' '))
            .collect();

        average_low_values = average_low_row[jan_index..=dec_index]
            .iter()
            .flat_map(|pair| pair.split(' '))
            .collect();
    } else {
        if average_high_row.len() < 24 {
            return Err("Wrong number of values".to_string());
        } else {
            average_high_values = average_high_row[jan_index..=dec_index * 2].to_vec();
            average_low_values = average_low_row[jan_index..=dec_index * 2].to_vec();
        }
    }

    let (average_high_non_paren_values, average_high_paren_values) =
        match parse_table_temperatures(average_high_values) {
            Ok(tup) => tup,
            Err(err) => return Err(err.to_string()),
        };
    let (average_low_non_paren_values, average_low_paren_values) =
        match parse_table_temperatures(average_low_values) {
            Ok(tup) => tup,
            Err(err) => return Err(err.to_string()),
        };

    let average_high_c: Option<Value>;
    let average_high_f: Option<Value>;
    let average_low_c: Option<Value>;
    let average_low_f: Option<Value>;

    if FAHRENHEIT.is_match(label) {
        average_high_c = Some(average_high_non_paren_values);
        average_high_f = Some(average_high_paren_values);
        average_low_c = Some(average_low_non_paren_values);
        average_low_f = Some(average_low_paren_values);
    } else {
        average_high_c = Some(average_high_paren_values);
        average_high_f = Some(average_high_non_paren_values);
        average_low_c = Some(average_low_paren_values);
        average_low_f = Some(average_low_non_paren_values);
    }

    // println!(
    //     "HIGH:\nC: {:?}\nF: {:?}\n\n",
    //     average_high_c, average_high_f
    // );
    // println!("LOW:\nC: {:?}\nF: {:?}\n\n", average_low_c, average_low_f);

    let sunshine_values: Option<Value>;
    if has_sunshine_hours {
        let row = sunshine_row.unwrap();
        // println!("sunshine row: {:?}", &row);
        if SUNSHINE.is_match(&row[1]) {
            // Is regular table.
            // Can have daily rather than monthly sunshine values.
            sunshine_values = parse_sunshine_values(
                row[1..][jan_index..=dec_index].to_vec(),
                DAILY.is_match(&row[0]),
            ).ok();

        // println!("sunshine vals: {:?}", sunshine_values);
        } else {
            // Is irregular table.
            sunshine_values =
                parse_sunshine_values(row[jan_index..=dec_index].to_vec(), DAILY.is_match(&row[0]))
                    .ok();
        }
    // println!("{:?}", sunshine_values);
    } else {
        sunshine_values = None;
    }

    Ok(TableRows {
        average_high_c: average_high_c,
        average_low_c: average_low_c,
        average_high_f: average_high_f,
        average_low_f: average_low_f,
        sunshine_hours: sunshine_values,
    })
}

fn filter_for_rows<'a>(table: &'a Vec<Vec<&str>>, regex: &Regex) -> Vec<Vec<&'a str>> {
    table
        .iter()
        .filter(|row| row.into_iter().any(|cell| regex.is_match(cell)) && row.len() > 10)
        .cloned()
        .collect()
}

fn parse_table_temperatures(values: Vec<&str>) -> Result<(Value, Value), ParseFloatError> {
    let mut non_paren_values = Vec::new();
    let mut paren_values = Vec::new();

    for (index, value) in values.into_iter().enumerate() {
        if index % 2 == 0 {
            non_paren_values.push(string_to_float(value)?)
        } else {
            paren_values.push(string_to_float(value)?)
        }
    }

    Ok((json!(non_paren_values), json!(paren_values)))
}

fn parse_sunshine_values(values: Vec<&str>, is_daily: bool) -> Result<Value, ParseFloatError> {
    let days_per_month = [
        31.0, 28.25, 31.0, 30.0, 31.0, 30.0, 31.0, 31.0, 30.0, 31.0, 30.0, 31.0,
    ];
    let mut sunshine_values = Vec::new();

    for value in values {
        sunshine_values.push(string_to_float(value)?)
    }

    if is_daily {
        let sv: Vec<f64> = sunshine_values
            .iter()
            .zip(days_per_month.iter())
            .map(|(s, d)| {
                let v = s * d;
                (v * 100.0).round() / 100.0 // Rounding float to 1 decimal place.
            })
            .collect();

        Ok(json!(sv))
    } else {
        Ok(json!(sunshine_values))
    }
}

fn string_to_float(value: &str) -> Result<f64, ParseFloatError> {
    value
        .replace("(", "")
        .replace(")", "")
        .replace("−", "-") // Replace unicode character 'MINUS SIGN' '−' (U+2212) with '-'.
        .parse::<f64>()
}

fn extract_infobox_data(
    table1: Vec<Vec<&str>>,
    table2: Vec<Vec<&str>>,
) -> Result<InfoboxRows, String> {
    // println!("{:?}\n{:?}", &table1, &table2);

    let label = table2.first().unwrap().first().unwrap();
    // println!("{:?}\n", label);

    let table1_values = &table1[1];
    let table2_values = &table2[2];

    if table1_values.len() != 36 || table2_values.len() != 36 {
        return Err("Wrong number of values".to_string());
    }

    let (average_high_shown_values, average_low_shown_values) =
        match parse_infobox_temperatures(table1_values.to_vec()) {
            Ok(tup) => tup,
            Err(err) => return Err(err.to_string()),
        };
    let (average_high_hidden_values, average_low_hidden_values) =
        match parse_infobox_temperatures(table2_values.to_vec()) {
            Ok(tup) => tup,
            Err(err) => return Err(err.to_string()),
        };

    let average_high_c: Option<Value>;
    let average_high_f: Option<Value>;
    let average_low_c: Option<Value>;
    let average_low_f: Option<Value>;

    if IMPERIAL.is_match(label) {
        average_high_c = Some(average_high_shown_values);
        average_high_f = Some(average_high_hidden_values);
        average_low_c = Some(average_low_shown_values);
        average_low_f = Some(average_low_hidden_values);
    } else {
        average_high_c = Some(average_high_hidden_values);
        average_high_f = Some(average_high_shown_values);
        average_low_c = Some(average_low_hidden_values);
        average_low_f = Some(average_low_shown_values);
    }

    // println!(
    //     "HIGH:\nC: {:?}\nF: {:?}\n\n",
    //     average_high_c, average_high_f
    // );
    // println!("LOW:\nC: {:?}\nF: {:?}\n\n", average_low_c, average_low_f);

    Ok(InfoboxRows {
        average_high_c: average_high_c,
        average_low_c: average_low_c,
        average_high_f: average_high_f,
        average_low_f: average_low_f,
    })
}

fn parse_infobox_temperatures(values: Vec<&str>) -> Result<(Value, Value), ParseFloatError> {
    // Values must be 36 in length - 3 values for each month.
    // Every chunk of 3 consists of:
    // [precipitation value, average high value, average low value].
    let mut average_high_values = Vec::new();
    let mut average_low_values = Vec::new();

    for chunk in values.chunks(3) {
        average_high_values.push(string_to_float(chunk[1])?);
        average_low_values.push(string_to_float(chunk[2])?);
    }

    Ok((json!(average_high_values), json!(average_low_values)))
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
