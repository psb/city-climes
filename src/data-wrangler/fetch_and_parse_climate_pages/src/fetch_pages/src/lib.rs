#[macro_use]
extern crate lazy_static;
extern crate reqwest;
extern crate types;

use reqwest::header::ContentLocation;
use reqwest::{Client, Response};
use types::{FetchResult, PageResult};

lazy_static! {
    static ref CLIENT: Client = Client::new();
}

pub fn fetch_page(page: &str) -> (PageResult, Option<String>) {
    let url = create_restbase_url(&page);
    let resp = CLIENT.get(&url).send();
    if resp.is_ok() {
        let mut fetch_result = resp.unwrap();
        if fetch_result.status().is_success() {
            let content_location_url = fetch_result
                .headers()
                .get::<ContentLocation>()
                .unwrap()
                .to_string();
            let html = fetch_result.text().unwrap();
            let pr = make_page_result(&page, Some(fetch_result), FetchResult::Page);
            println!("Fetch -> Page: {:?}", content_location_url);
            (pr, Some(html))
        } else {
            let pr = make_page_result(&page, Some(fetch_result), FetchResult::FetchError);
            println!("Fetch -> StatusError: {:?}", url);
            (pr, None)
        }
    } else {
        let pr = make_page_result(&page, None, FetchResult::FetchError);
        println!("Fetch -> FetchError: {:?}", resp);
        (pr, None)
    }
}

fn create_restbase_url(page: &str) -> String {
    format!(
        "https://en.wikipedia.org/api/rest_v1/page/html/{}?redirect=true",
        page.replace(" ", "_")
    )
}

fn extract_location_name(clu: &str) -> String {
    let mut v: Vec<&str> = clu.split('/').collect();
    let l = v.pop().unwrap();
    if l.starts_with("Climate_of") || l.starts_with("Geography_of") {
        let p: Vec<&str> = l.splitn(3, '_').collect();
        let p = p[2].to_string().replace("_", " ");
        if p.starts_with("the") {
            p.replacen("the", "The", 1)
        } else {
            p
        }
    } else {
        l.replace("_", " ")
    }
}

fn create_wikipedia_url(clu: &str) -> String {
    let restbase_url_section = "api/rest_v1/page/html";
    let wikipedia_url_section = "wiki";
    clu.replace(restbase_url_section, wikipedia_url_section)
}

fn make_page_result(page: &str, fetch_result: Option<Response>, fr: FetchResult) -> PageResult {
    match fr {
        FetchResult::Page => {
            let fetch_result = fetch_result.unwrap();
            let content_location_url = fetch_result
                .headers()
                .get::<ContentLocation>()
                .unwrap()
                .to_string();
            let response_url = fetch_result.url().to_string();
            let status_code = fetch_result.status().as_u16();
            let location_name = extract_location_name(&content_location_url);
            let wikipedia_url = create_wikipedia_url(&content_location_url);
            PageResult {
                page_name: page.to_string(),
                fetch_result: FetchResult::Page,
                response_url: Some(response_url),
                content_location_url: Some(content_location_url),
                wikipedia_url: Some(wikipedia_url),
                location_name: Some(location_name),
                status_code: Some(status_code),
                ..Default::default()
            }
        }
        FetchResult::FetchError => PageResult {
            page_name: page.to_string(),
            fetch_result: FetchResult::FetchError,
            ..Default::default()
        },
        FetchResult::StatusError => {
            let fetch_result = fetch_result.unwrap();
            let status_code = fetch_result.status().as_u16();
            PageResult {
                page_name: page.to_string(),
                fetch_result: FetchResult::StatusError,
                status_code: Some(status_code),
                ..Default::default()
            }
        }
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
        assert_eq!(2 + 2, 4);
    }
}
