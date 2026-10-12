use std::process::{Command, Stdio};
use std::thread;

use futures_lite::StreamExt;
use futures_lite::future::block_on;
use paneru::types::state::{ActiveState, Frame, QueryState, VirtualWorkspaceState, WindowState};
use paneru::types::windowset::{
    ColumnKind, ColumnSet, DisplaySet, WindowRec, WindowSet, WorkspaceSet,
};
use paneru::types::wire::{self, QueryPayload, Request, Response};
use serde_json::Value;
use std::sync::Arc;

const FRAME: Frame = Frame {
    x: 0,
    y: 38,
    width: 960,
    height: 1205,
};

fn record(id: i32) -> WindowRec {
    WindowRec {
        id,
        app_name: "Notes".to_string(),
        bundle_id: "com.apple.Notes".to_string(),
        title: String::new(),
        frame: Some(FRAME),
        floating: false,
        managed: true,
        visible: true,
        focused: id == 7,
    }
}

fn row(id: i32) -> WindowState {
    WindowState {
        window_id: id,
        bundle_id: "com.apple.Notes".to_string(),
        app_name: "Notes".to_string(),
        title: String::new(),
        focused: id == 7,
        floating: false,
        display_id: Some(1),
        frame: Some(FRAME),
        visible: true,
    }
}

fn layout() -> WindowSet {
    let tabs = ColumnSet {
        kind: ColumnKind::Tabs,
        width_ratio: 0.5,
        selected: 0,
        windows: Arc::new(vec![record(7), record(8)]),
    };
    let workspace = WorkspaceSet {
        number: 1,
        native_id: 3,
        active: true,
        columns: Arc::new(vec![tabs, ColumnSet::single(record(9), 0.5)]),
        floating: Arc::new(Vec::new()),
    };
    let display = DisplaySet {
        id: 1,
        frame: FRAME,
        active: true,
        workspaces: Arc::new(vec![workspace]),
    };
    WindowSet::new(vec![display], Some(7))
}

fn state() -> QueryState {
    QueryState {
        version: 1,
        timestamp: 0,
        active: ActiveState::default(),
        virtual_workspaces: vec![VirtualWorkspaceState {
            number: 1,
            native_workspace_id: 3,
            active: true,
            windows: vec![row(7), row(8), row(9)],
        }],
    }
}

fn serve(service: &str, answers_layout: bool) -> thread::JoinHandle<()> {
    let receiver = wire::bind::<Request>(service).expect("binds the service name");
    thread::spawn(move || {
        block_on(async move {
            let mut requests = std::pin::pin!(receiver);
            for _ in 0..2 {
                let delivery = requests.next().await.expect("a request").expect("decodes");
                let answer = match delivery.value {
                    Request::WindowSet if answers_layout => Response::WindowSet(Box::new(layout())),
                    Request::Query(_) => Response::Query(QueryPayload::State(Box::new(state()))),
                    _ => Response::Error("no layout".to_string()),
                };
                delivery
                    .reply
                    .expect("a reply channel")
                    .send(&answer)
                    .expect("answers");
            }
        });
    })
}

fn snapshot(service: &str) -> (bool, Value) {
    let output = Command::new(env!("CARGO_BIN_EXE_engine-bridge"))
        .env(wire::SERVICE_ENV, service)
        .stderr(Stdio::null())
        .output()
        .expect("runs the bridge");
    let document = serde_json::from_slice(&output.stdout).unwrap_or(Value::Null);
    (output.status.success(), document)
}

#[test]
fn prints_the_state_with_the_column_structure() {
    let service = format!("dev.macousel.bridge-test.{}.layout", std::process::id());
    let server = serve(&service, true);
    let (succeeded, document) = snapshot(&service);
    server.join().expect("the server finishes");

    assert!(succeeded);
    let columns = &document["layout"]["displays"][0]["workspaces"][0]["columns"];
    assert_eq!(columns[0]["kind"], "tabs");
    assert_eq!(columns[0]["windows"][1]["id"], 8);
    assert_eq!(columns[1]["windows"][0]["id"], 9);
    assert_eq!(document["layout"]["focused"], 7);
    let windows = &document["state"]["virtual_workspaces"][0]["windows"];
    assert_eq!(windows[2]["window_id"], 9);
}

#[test]
fn keeps_the_state_when_the_layout_is_refused() {
    let service = format!("dev.macousel.bridge-test.{}.refused", std::process::id());
    let server = serve(&service, false);
    let (succeeded, document) = snapshot(&service);
    server.join().expect("the server finishes");

    assert!(succeeded);
    assert_eq!(document["layout"], Value::Null);
    assert_eq!(document["state"]["version"], 1);
}

#[test]
fn fails_when_no_engine_answers() {
    let service = format!("dev.macousel.bridge-test.{}.absent", std::process::id());
    let (succeeded, _) = snapshot(&service);

    assert!(!succeeded);
}
