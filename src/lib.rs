use std::{ffi::c_void, sync::Mutex};

use product::Product;
use serde_json::Value as JsonValue;
use swift_rs::{swift, Bool, Int, SRString};
use tauri::{
    command,
    plugin::{Builder, TauriPlugin},
    AppHandle, Manager, Runtime, State, Window, Wry,
};
use transaction::Transaction;
use util::{emit_event, emit_exception, EmitEvents, IAPResult, SwiftCallback, APP_HANDLE};

mod exception;
mod product;
mod transaction;
mod util;

struct IAPState {
    inited: bool,
}

impl IAPState {
    fn new(inited: bool) -> Self {
        Self { inited }
    }
}

swift!(fn swift_initialize(on_product_updated: SwiftCallback,on_transaction_updated: SwiftCallback,on_exception: SwiftCallback) -> Bool);
fn initialize(app: AppHandle) {
    APP_HANDLE.set(Mutex::new(app.to_owned())).unwrap();
    unsafe extern "C" fn product_updated_callback(arg1: *const c_void, size: i32) {
        emit_event::<Vec<Product>>(EmitEvents::ProductsUpdated, arg1, size);
    }
    unsafe extern "C" fn transaction_updated_callback(arg1: *const c_void, size: i32) {
        emit_event::<Vec<Transaction>>(EmitEvents::TransactionUpdated, arg1, size)
    }
    unsafe extern "C" fn exception_callback(arg1: *const c_void, size: i32) {
        emit_exception(arg1, size);
    }
    let inited = unsafe {
        swift_initialize(
            SwiftCallback(product_updated_callback),
            SwiftCallback(transaction_updated_callback),
            SwiftCallback(exception_callback),
        )
    };
    app.manage(IAPState::new(inited));
}

swift!(fn swift_can_make_payments() -> Bool);
#[command]
fn can_make_payments<R: Runtime>(_app: AppHandle<R>, _window: Window<R>) -> IAPResult {
    let available = unsafe { swift_can_make_payments() };
    Ok(JsonValue::Bool(available))
}

swift!(fn swift_country_code() -> Option<SRString>);
#[command]
fn country_code() -> IAPResult {
    if let Some(country) = unsafe { swift_country_code() } {
        Ok(JsonValue::String(country.to_owned()))
    } else {
        Ok(JsonValue::Null)
    }
}

swift!(fn swift_query_products(product_id: &SRString));
#[command]
fn query_products<R: Runtime>(
    _app: AppHandle<R>,
    _window: Window<R>,
    state: State<'_, IAPState>,
    identifiers: Vec<String>,
) -> IAPResult {
    if !state.inited {
        return Err("Not initialized.".to_owned());
    }
    unsafe {
        swift_query_products(&identifiers.join(",").as_str().into());
    }
    Ok(JsonValue::Null)
}

swift!(fn swift_restore_purchases(application_user_name: SRString));
#[command]
fn restore_purchases<R: Runtime>(
    _app: AppHandle<R>,
    _window: Window<R>,
    state: State<'_, IAPState>,
    application_user_name: Option<String>,
) -> IAPResult {
    if !state.inited {
        return Err("Not initialized.".to_owned());
    }
    unsafe {
        swift_restore_purchases(application_user_name.unwrap_or_default().as_str().into());
    }
    Ok(JsonValue::Null)
}

swift!(fn swift_request_pruchase(product_identifier: SRString, quantity: Int, application_user_name: SRString));
#[command]
fn request_pruchase<R: Runtime>(
    _app: AppHandle<R>,
    _window: Window<R>,
    state: State<'_, IAPState>,
    product_identifier: String,
    quantity: isize,
    application_user_name: Option<String>,
) -> IAPResult {
    if !state.inited {
        return Err("Not initialized.".to_owned());
    }
    unsafe {
        swift_request_pruchase(
            product_identifier.as_str().into(),
            quantity.into(),
            application_user_name.unwrap_or_default().as_str().into(),
        );
    }
    Ok(JsonValue::Null)
}

swift!(fn swift_complete_pruchase(transaction_id: SRString));
#[command]
fn complete_pruchase<R: Runtime>(
    _app: AppHandle<R>,
    _window: Window<R>,
    state: State<'_, IAPState>,
    transaction_id: String,
) -> IAPResult {
    if !state.inited {
        return Err("Not initialized.".to_owned());
    }
    unsafe {
        swift_complete_pruchase(transaction_id.as_str().into());
    }
    Ok(JsonValue::Null)
}

/// Initializes the plugin.
pub fn init() -> TauriPlugin<Wry> {
    Builder::new("iap")
        .invoke_handler(tauri::generate_handler![
            can_make_payments,
            country_code,
            query_products,
            restore_purchases,
            request_pruchase,
            complete_pruchase,
        ])
        .setup(|app| {
            initialize(app.app_handle());
            Ok(())
        })
        .build()
}
