mod iap;
mod products_request_delegate;
mod global_data;
mod exception;

use iap::IAP;
use serde_json::Value as JsonValue;
use tauri::{
    command,
    plugin::{Builder, TauriPlugin},
    AppHandle, Manager, Runtime, State, Window,
};

type IAPResult = std::result::Result<JsonValue, String>;

/// Check IAP is available or not.
#[command]
fn can_make_payments<R: Runtime>(
    _app: AppHandle<R>,
    _window: Window<R>,
    _state: State<'_, IAP>,
) -> IAPResult {
    Ok(JsonValue::Bool(IAP::can_make_payments()))
}

#[command]
fn query_product_details<R: Runtime>(
    _app: AppHandle<R>,
    _window: Window<R>,
    state: State<'_, IAP>,
    identifiers: Vec<String>,
) -> IAPResult {
    if !state.initialized {
        return Err("Not initialized".to_string());
    }
    state.start_product_request(identifiers);
    Ok(JsonValue::Null)
}

/// Initializes the plugin.
pub fn init<R: Runtime>() -> TauriPlugin<R> {
    Builder::new("iap")
        .invoke_handler(tauri::generate_handler![
            can_make_payments,
            query_product_details
        ])
        .setup(|app: &AppHandle<R>| {
            let mut iap = IAP::default();
            let handle = app.app_handle();
            let _ = iap
                .init(move |event, payload| {
                    let _ = handle.emit_all(event, payload);
                })
                .or_else(|e| app.emit_all("exception", e));
            app.manage(iap);
            Ok(())
        })
        .build()
}
