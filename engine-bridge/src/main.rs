use std::io::{self, BufRead, Write};
use std::process::ExitCode;
use std::thread;
use std::time::Duration;

use paneru::types::argv::parse_command;
use paneru::types::commands::Command;
use paneru::types::state::{StateEvent, StateQueryKind};
use paneru::types::wire::{self, RecvPort, Request, SendPort, Sender, service_name};
use serde_json::{Value, json};

const RESUBSCRIBE_DELAY: Duration = Duration::from_millis(500);

fn connect() -> Result<Sender<Request>, String> {
    wire::connect(&service_name()).map_err(|error| error.to_string())
}

/// Reads the engine's answers as plain values. The bridge links the published Paneru, whose
/// types would drop the fields only the patched engine writes, such as `pinned`.
fn snapshot(mut ask: impl FnMut(&Request) -> Result<Value, String>) -> Result<Value, String> {
    let layout = ask(&Request::WindowSet)?
        .get_mut("WindowSet")
        .map(Value::take);
    let mut reply = ask(&Request::Query(StateQueryKind::State))?;
    if let Some(state) = reply.pointer_mut("/Query/State") {
        return Ok(json!({
            "state": state.take(),
            "layout": layout,
        }));
    }
    Err(reply["Error"]
        .as_str()
        .unwrap_or("the engine sent an unexpected answer")
        .to_string())
}

#[derive(Debug, PartialEq)]
enum Ask {
    Snapshot,
    Command(Command),
}

/// Reads one request line. A line without an id has nowhere to send its answer, so it is
/// `None` and skipped.
fn parse(line: &str) -> Option<(u64, Result<Ask, String>)> {
    let request: Value = serde_json::from_str(line).ok()?;
    let id = request["id"].as_u64()?;
    let ask = match request["request"].as_str() {
        Some("snapshot") => Ok(Ask::Snapshot),
        Some("command") => words(&request["words"]).and_then(|words| {
            let borrowed = words.iter().map(String::as_str).collect::<Vec<_>>();
            parse_command(&borrowed)
                .map(Ask::Command)
                .map_err(|error| error.to_string())
        }),
        _ => Err(format!("unknown request {line}")),
    };
    Some((id, ask))
}

fn words(value: &Value) -> Result<Vec<String>, String> {
    value
        .as_array()
        .and_then(|words| {
            words
                .iter()
                .map(|word| word.as_str().map(str::to_string))
                .collect()
        })
        .ok_or_else(|| "a command needs its words as strings".to_string())
}

/// The engine connection kept across requests. A Paneru restart leaves the cached right
/// dead, so a failed request reconnects once and tries again.
#[derive(Default)]
struct Link {
    sender: Option<Sender<Request>>,
}

impl Link {
    fn with<T>(
        &mut self,
        act: impl Fn(&Sender<Request>) -> Result<T, wire::Error>,
    ) -> Result<T, String> {
        let mut retried = false;
        loop {
            let sender = match self.sender.take() {
                Some(sender) => sender,
                None => connect()?,
            };
            match act(&sender) {
                Ok(value) => {
                    self.sender = Some(sender);
                    return Ok(value);
                }
                Err(error) if retried => return Err(error.to_string()),
                Err(_) => retried = true,
            }
        }
    }
}

fn answer(link: &mut Link, ask: Ask) -> Value {
    let outcome = match ask {
        Ask::Snapshot => snapshot(|request| link.with(|sender| sender.call_blocking(request))),
        Ask::Command(command) => {
            let request = Request::Command(command);
            link.with(|sender| sender.send_blocking(&request))
                .map(|()| json!({}))
        }
    };
    outcome.unwrap_or_else(|message| json!({ "error": message }))
}

fn emit(line: &Value) {
    let mut out = io::stdout().lock();
    // Nobody reads the answers once Macousel is gone, so the bridge has nothing left to do.
    if writeln!(out, "{line}").and_then(|()| out.flush()).is_err() {
        std::process::exit(0);
    }
}

fn stream_events() {
    loop {
        let subscription = connect().and_then(|sender| {
            sender
                .subscribe_blocking::<StateEvent>(&Request::Subscribe)
                .map_err(|error| error.to_string())
        });
        if let Ok(events) = subscription {
            while let Ok(delivery) = events.recv_blocking() {
                if let Ok(event) = delivery.value.to_json() {
                    emit(&event);
                }
            }
        }
        thread::sleep(RESUBSCRIBE_DELAY);
    }
}

fn serve() {
    thread::spawn(stream_events);
    let mut link = Link::default();
    for line in io::stdin().lock().lines() {
        let Ok(line) = line else { break };
        let Some((id, ask)) = parse(&line) else {
            continue;
        };
        // The published Paneru cannot parse a command only a patch adds, so Macousel sends
        // the words it refused through the patched engine binary instead.
        let mut reply = match ask {
            Ok(ask) => answer(&mut link, ask),
            Err(message) => json!({ "error": message, "unparsed": true }),
        };
        reply["id"] = json!(id);
        emit(&reply);
    }
}

fn main() -> ExitCode {
    if std::env::args().nth(1).as_deref() == Some("serve") {
        serve();
        return ExitCode::SUCCESS;
    }
    match snapshot(|request| {
        connect()?
            .call_blocking(request)
            .map_err(|error| error.to_string())
    }) {
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

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn reads_a_snapshot_request() {
        assert_eq!(
            parse(r#"{"id":4,"request":"snapshot"}"#),
            Some((4, Ok(Ask::Snapshot)))
        );
    }

    #[test]
    fn reads_command_words_the_way_send_cmd_does() {
        let expected = parse_command(&["window", "focus", "west"]).expect("a command");
        assert_eq!(
            parse(r#"{"id":5,"request":"command","words":["window","focus","west"]}"#),
            Some((5, Ok(Ask::Command(expected))))
        );
    }

    #[test]
    fn refuses_words_paneru_does_not_know() {
        let (id, ask) = parse(r#"{"id":6,"request":"command","words":["window","fly"]}"#)
            .expect("an answerable request");
        assert_eq!(id, 6);
        assert!(ask.is_err());
    }

    #[test]
    fn refuses_words_that_are_not_strings() {
        let (_, ask) =
            parse(r#"{"id":7,"request":"command","words":["window",1]}"#).expect("an id");
        assert!(ask.is_err());
    }

    #[test]
    fn refuses_an_unknown_request() {
        let (_, ask) = parse(r#"{"id":8,"request":"dance"}"#).expect("an id");
        assert!(ask.is_err());
    }

    #[test]
    fn reads_the_state_the_typed_answer_carries() {
        use paneru::types::state::QueryState;
        use paneru::types::wire::{Codec, MessagePack, QueryPayload, Response};

        let state = QueryState {
            version: 1,
            timestamp: 3,
            active: Default::default(),
            virtual_workspaces: Vec::new(),
        };
        let bytes = MessagePack
            .encode(&Response::Query(QueryPayload::State(Box::new(
                state.clone(),
            ))))
            .expect("encodes");
        let answer: Value = MessagePack.decode(&bytes).expect("decodes");
        let document = snapshot(|request| match request {
            Request::WindowSet => Ok(json!({ "Error": "no layout" })),
            _ => Ok(answer.clone()),
        })
        .expect("a snapshot");

        assert_eq!(
            document["state"],
            serde_json::to_value(state).expect("JSON")
        );
        assert_eq!(document["layout"], Value::Null);
    }

    #[test]
    fn keeps_fields_the_published_types_do_not_know() {
        let window = json!({ "window_id": 7, "pinned": true });
        let document = snapshot(|request| match request {
            Request::WindowSet => Ok(json!({ "WindowSet": { "floating": [window.clone()] } })),
            _ => Ok(json!({ "Query": { "State": { "virtual_workspaces": [{ "windows": [window.clone()] }] } } })),
        })
        .expect("a snapshot");

        assert_eq!(
            document["state"]["virtual_workspaces"][0]["windows"][0]["pinned"],
            true
        );
        assert_eq!(document["layout"]["floating"][0]["pinned"], true);
    }

    #[test]
    fn passes_on_the_engine_refusal() {
        let refusal = snapshot(|_| Ok(json!({ "Error": "not yet" })));

        assert_eq!(refusal, Err("not yet".to_string()));
    }

    #[test]
    fn skips_lines_it_cannot_answer() {
        assert_eq!(parse(r#"{"request":"snapshot"}"#), None);
        assert_eq!(parse("not json"), None);
    }
}
