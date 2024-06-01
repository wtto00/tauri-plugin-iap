use once_cell::sync::OnceCell;
use serde::{ser::Serializer, Serialize};
use serde_json::Value as JsonValue;
use tauri::{
    command,
    plugin::{Builder, TauriPlugin},
    AppHandle, Manager, Runtime, State, Window, Wry,
};

use std::{collections::HashMap, sync::Mutex};

mod bridge;
mod product;
mod exception;

type IAPResult = std::result::Result<JsonValue, Error>;

#[derive(Debug, thiserror::Error)]
pub enum Error {
    #[error(transparent)]
    Io(#[from] std::io::Error),
}

impl Serialize for Error {
    fn serialize<S>(&self, serializer: S) -> std::result::Result<S::Ok, S::Error>
    where
        S: Serializer,
    {
        serializer.serialize_str(self.to_string().as_ref())
    }
}

#[derive(Default)]
struct MyState(Mutex<HashMap<String, String>>);

static APP_HANDLE: OnceCell<Mutex<AppHandle>> = OnceCell::new();

/// Check IAP is available or not.
#[command]
fn can_make_payments<R: Runtime>(_app: AppHandle<R>, _window: Window<R>) -> IAPResult {
    let available = bridge::swift_can_make_payments();
    Ok(JsonValue::Bool(available))
}

#[command]
fn query_products<R: Runtime>(
    _app: AppHandle<R>,
    _window: Window<R>,
    identifiers: Vec<String>,
) -> IAPResult {
    bridge::swift_query_products(identifiers);
    Ok(JsonValue::Null)
}

/// Initializes the plugin.
pub fn init() -> TauriPlugin<Wry> {
    Builder::new("iap")
        .invoke_handler(tauri::generate_handler![
            can_make_payments,
            query_products,
        ])
        .setup(|app| {
            APP_HANDLE
                .set(Mutex::new(app.app_handle().to_owned()))
                .unwrap();

            app.manage(MyState::default());
            Ok(())
        })
        .build()
}
