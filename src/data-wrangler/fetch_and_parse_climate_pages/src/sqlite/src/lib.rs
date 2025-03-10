extern crate rusqlite;
extern crate types;

use rusqlite::Connection;
use types::PageResult;

pub fn save_page(db_path: &str, page_result: PageResult) -> () {
    let conn = Connection::open(db_path).expect("Failed to open connection to DB.");

    let res = conn.execute(
        "INSERT INTO FetchAndParseResults (
                PageName,
                FetchResult,
                ResponseURL,
                StatusCode,
                ContentLocationURL,
                WikipediaURL,
                LocationName,
                TableHTML,
                TemperatureTableType,
                AverageHighC,
                AverageLowC,
                AverageHighF,
                AverageLowF,
                SunshineHours,
                ParseResult
            ) VALUES (
                ?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8,
                ?9, ?10, ?11, ?12, ?13, ?14, ?15)",
        &[
            &page_result.page_name,
            &page_result.fetch_result,
            &page_result.response_url,
            &page_result.status_code,
            &page_result.content_location_url,
            &page_result.wikipedia_url,
            &page_result.location_name,
            &page_result.table_html,
            &page_result.temperature_table_type,
            &page_result.average_high_c,
            &page_result.average_low_c,
            &page_result.average_high_f,
            &page_result.average_low_f,
            &page_result.sunshine_hours,
            &page_result.parse_result,
        ],
    );

    if let Ok(updated) = res {
        println!(
            "Save -> Success: Inserted {:?} row(s) for {:?}",
            updated, &page_result.page_name
        );
    } else {
        println!("Save -> Error: {:?}", res);
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
