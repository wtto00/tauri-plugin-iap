use std::{collections::HashSet, ffi::c_void};

use serde_json::Value as JsonValue;
use swift_rs::{swift, Bool, SRString, SwiftArg};
use tauri::{
    command,
    plugin::{Builder, TauriPlugin},
    AppHandle, Manager, Runtime, State, Window,
};

type AppleCallbackFn = unsafe extern "C" fn(*const c_void, size: i32);
pub struct AppleCallback(pub AppleCallbackFn);

impl<'a> SwiftArg<'a> for AppleCallback {
    type ArgType = AppleCallbackFn;

    unsafe fn as_arg(&'a self) -> Self::ArgType {
        self.0
    }
}

swift!(fn is_available() -> Bool);
swift!(fn query_products(product_id: SRString, success: AppleCallback, error: AppleCallback));

type IAPResult = std::result::Result<JsonValue, String>;

/// Check IAP is available or not.
#[command]
fn can_make_payments<R: Runtime>(_app: AppHandle<R>, _window: Window<R>) -> IAPResult {
    // unsafe extern "C" fn callback(arg1: *const c_void, size: i32) {
    //     let data_slice = unsafe { std::slice::from_raw_parts(arg1 as *const u8, size as usize) };
    //     let data_str = std::str::from_utf8(data_slice).unwrap();
    //     println!("data_str: {:?}", data_str);
    // }
    let available = unsafe { is_available() };
    Ok(JsonValue::Bool(available))
}

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
    }
    unsafe extern "C" fn error_callback(arg1: *const c_void, size: i32) {
        let data_slice = unsafe { std::slice::from_raw_parts(arg1 as *const u8, size as usize) };
        let data_str = std::str::from_utf8(data_slice).unwrap();
        println!("error_callback data_str: {:?}", data_str);
    }
    unsafe {
        query_products(
            SRString::from(identifiers.join(",").as_str()),
            AppleCallback(success_callback),
            AppleCallback(error_callback),
        );
    }
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
            // let mut iap = IAP::default();
            // let handle = app.app_handle();
            // let _ = iap
            //     .init(move |event, payload| {
            //         let _ = handle.emit_all(event, payload);
            //     })
            //     .or_else(|e| app.emit_all("exception", e));
            // app.manage(iap);
            Ok(())
        })
        .build()
}
