use std::{ffi::c_void, sync::Mutex};

use once_cell::sync::OnceCell;
use serde_json::Value as JsonValue;
use swift_rs::{swift, Bool, SRString, SwiftArg};
use tauri::{
    command, plugin::{Builder, TauriPlugin}, AppHandle, Manager, Runtime, Window, Wry
};

type AppleCallbackFn = unsafe extern "C" fn(*const c_void, size: i32);
pub struct AppleCallback(pub AppleCallbackFn);

impl<'a> SwiftArg<'a> for AppleCallback {
    type ArgType = AppleCallbackFn;

    unsafe fn as_arg(&'a self) -> Self::ArgType {
        self.0
    }
}

type IAPResult = std::result::Result<JsonValue, String>;

static APP_HANDLE: OnceCell<Mutex<AppHandle>> = OnceCell::new();

swift!(fn is_available() -> Bool);
/// Check IAP is available or not.
#[command]
fn can_make_payments<R: Runtime>(_app: AppHandle<R>, _window: Window<R>) -> IAPResult {
    let available = unsafe { is_available() };
    Ok(JsonValue::Bool(available))
}

swift!(fn query_products(product_id: SRString, success: AppleCallback, error: AppleCallback));
#[command]
fn query_product_details<R: Runtime>(
    _app: AppHandle<R>,
    _window: Window<R>,
    identifiers: Vec<String>,
) -> IAPResult {
    unsafe extern "C" fn success_callback(arg1: *const c_void, size: i32) {
        let data_slice = unsafe { std::slice::from_raw_parts(arg1 as *const u8, size as usize) };
        let data_str = std::str::from_utf8(data_slice).unwrap();
        println!("success_callback data_str: {:?}", data_str);
        let app = APP_HANDLE.get().unwrap().lock();
        if let Ok(app_handle) = app {
            app_handle.emit_all("products-update", data_str).unwrap();
        }
    }
    unsafe extern "C" fn error_callback(arg1: *const c_void, size: i32) {
        let data_slice = unsafe { std::slice::from_raw_parts(arg1 as *const u8, size as usize) };
        let data_str = std::str::from_utf8(data_slice).unwrap();
        println!("error_callback data_str: {:?}", data_str);
        let app = APP_HANDLE.get().unwrap().lock();
        if let Ok(app_handle) = app {
            app_handle.emit_all("exception", data_str).unwrap();
        }
    }
    unsafe {
        query_products(
            identifiers.join(",").as_str().into(),
            AppleCallback(success_callback),
            AppleCallback(error_callback),
        );
    }
    Ok(JsonValue::Null)
}

/// Initializes the plugin.
pub fn init() -> TauriPlugin<Wry> {
    Builder::new("iap")
        .invoke_handler(tauri::generate_handler![
            can_make_payments,
            query_product_details
        ])
        .setup(|app| {
            APP_HANDLE
                .set(Mutex::new(app.app_handle().to_owned()))
                .unwrap();
            // app.manage(iap);
            Ok(())
        })
        .build()
}
