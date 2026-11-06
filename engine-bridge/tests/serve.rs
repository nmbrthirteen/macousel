use std::io::{BufRead, BufReader, Write};
use std::process::{Command, Stdio};
use std::sync::mpsc;
use std::thread;
use std::time::Duration;

use futures_lite::StreamExt;
use futures_lite::future::block_on;
use paneru::types::argv::parse_command;
use paneru::types::commands::Command as EngineCommand;
use paneru::types::state::{QueryState, StateEvent};
use paneru::types::wire::{self, QueryPayload, Request, Response};
use serde_json::Value;

fn state() -> QueryState {
    QueryState {
        version: 1,
        timestamp: 0,
        active: Default::default(),
        virtual_workspaces: Vec::new(),
    }
}

fn serve(service: &str) -> mpsc::Receiver<EngineCommand> {
    let receiver = wire::bind::<Request>(service).expect("binds the service name");
    let (commands, received) = mpsc::channel();
    thread::spawn(move || {
        block_on(async move {
            let mut requests = std::pin::pin!(receiver);
            let mut subscribers = Vec::new();
            while let Some(delivery) = requests.next().await {
                let delivery = delivery.expect("decodes");
                match delivery.value {
                    Request::Command(command) => commands.send(command).expect("records"),
                    Request::Subscribe => {
                        let subscriber = delivery.subscriber.expect("an event channel");
                        subscriber
                            .try_send(&StateEvent::DisplayChanged {
                                display_id: Some(2),
                            })
                            .expect("pushes an event");
                        subscribers.push(subscriber);
                    }
                    request => {
                        let answer = match request {
                            Request::Query(_) => {
                                Response::Query(QueryPayload::State(Box::new(state())))
                            }
                            _ => Response::Error("no layout".to_string()),
                        };
                        delivery
                            .reply
                            .expect("a reply channel")
                            .send(&answer)
                            .expect("answers");
                    }
                }
            }
        });
    });
    received
}

#[test]
fn answers_requests_by_id_and_streams_events_until_stdin_closes() {
    let service = format!("dev.macousel.bridge-test.{}.serve", std::process::id());
    let commands = serve(&service);
    let mut bridge = Command::new(env!("CARGO_BIN_EXE_engine-bridge"))
        .arg("serve")
        .env(wire::SERVICE_ENV, &service)
        .stdin(Stdio::piped())
        .stdout(Stdio::piped())
        .stderr(Stdio::null())
        .spawn()
        .expect("runs the bridge");
    let mut input = bridge.stdin.take().expect("an input pipe");
    let output = BufReader::new(bridge.stdout.take().expect("an output pipe"));
    writeln!(
        input,
        r#"{{"id":1,"request":"command","words":["window","focus","west"]}}
{{"id":2,"request":"snapshot"}}
{{"id":3,"request":"command","words":["window","fly"]}}"#
    )
    .expect("writes requests");

    let mut answers = Vec::new();
    let mut events = Vec::new();
    for line in output.lines() {
        let line: Value = serde_json::from_str(&line.expect("a line")).expect("JSON");
        if line["id"].is_null() {
            events.push(line);
        } else {
            answers.push(line);
        }
        if answers.len() == 3 && !events.is_empty() {
            break;
        }
    }
    drop(input);

    assert_eq!(answers[0]["id"], 1);
    assert_eq!(answers[0]["error"], Value::Null);
    assert_eq!(answers[1]["id"], 2);
    assert_eq!(answers[1]["state"]["version"], 1);
    assert_eq!(answers[1]["layout"], Value::Null);
    assert_eq!(answers[2]["id"], 3);
    assert!(answers[2]["error"].is_string());
    assert_eq!(answers[2]["unparsed"], true);
    assert_eq!(events[0]["event"], "display_changed");
    assert_eq!(events[0]["display_id"], 2);
    let sent = commands
        .recv_timeout(Duration::from_secs(5))
        .expect("the command reached the engine");
    assert_eq!(
        sent,
        parse_command(&["window", "focus", "west"]).expect("a command")
    );
    assert!(bridge.wait().expect("the bridge exits").success());
}
