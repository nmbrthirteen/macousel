use std::process::ExitCode;

use futures_lite::future::block_on;
use paneru::types::state::StateQueryKind;
use paneru::types::wire::{self, QueryPayload, Request, Response, SendPort, Sender, service_name};
use serde_json::{Value, json};

fn connect() -> Result<Sender<Request>, String> {
    wire::connect(&service_name()).map_err(|error| error.to_string())
}

async fn ask(request: Request) -> Result<Response, String> {
    connect()?
        .call(&request)
        .await
        .map_err(|error| error.to_string())
}

async fn snapshot() -> Result<Value, String> {
    let layout = match ask(Request::WindowSet).await? {
        Response::WindowSet(layout) => Some(layout),
        _ => None,
    };
    match ask(Request::Query(StateQueryKind::State)).await? {
        Response::Query(QueryPayload::State(state)) => Ok(json!({
            "state": state,
            "layout": layout,
        })),
        Response::Error(message) => Err(message),
        _ => Err("the engine sent an unexpected answer".to_string()),
    }
}

fn main() -> ExitCode {
    match block_on(snapshot()) {
        Ok(document) => {
            println!("{document}");
            ExitCode::SUCCESS
        }
        Err(message) => {
            eprintln!("{message}");
            ExitCode::FAILURE
        }
    }
}
