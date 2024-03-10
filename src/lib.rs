use std::thread::sleep;
use std::time::Duration;

use chrono::NaiveDate;
use flawless::workflow;
use flawless_http::{get, post};
use serde::{Deserialize, Serialize};

const HOUR: Duration = Duration::from_secs(3600);

#[workflow("risk-central")]
pub fn risk_central(input: Input) {
    let resp: PrimaInfoReqStatus = get(format!("http://localhost:8080/xf/req-status?ndg={}", &input.ndg))
        .send().unwrap().json().unwrap();
    if resp.status == "OK" {
        let risk_events = loop {
            let risk_events: Vec<DwhRiskEvents> = get(format!("http://localhost:8080/dwh/risk-events?ndg={}", &input.ndg))
                .send().unwrap().json().unwrap();
            if !risk_events.is_empty() {
                break risk_events;
            }
            sleep(4 * HOUR);
        };
        if risk_events.iter().any(|e| e.date.is_recent()) {
            post("http://localhost:8080/kafka/centrale-rischi")
                .body(serde_json::to_value(risk_events).unwrap())
                .send().unwrap();
        } else {
            println!("KO");
        }
    } else {
        println!("KO");
    }
    println!("Hello, world!");
}

#[derive(Debug, Serialize, Deserialize)]
struct Input {
    ndg: String,
    tax_code: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct PrimaInfoReqStatus {
    ndg: String,
    status: String,
}

#[derive(Debug, Serialize, Deserialize)]
struct DwhRiskEvents {
    description: String,
    phenomenon: String,
    date: NaiveDate,
}

trait IsRecent {
    fn is_recent(&self) -> bool;
}

impl IsRecent for NaiveDate {
    fn is_recent(&self) -> bool {
        let today = chrono::offset::Local::now().naive_local().date();
        let diff = today.signed_duration_since(*self).num_days();
        diff < 30
    }
}

#[cfg(test)]
mod tests {
    #[test]
    fn it_works() {
    }
}
