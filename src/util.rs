use std::{ffi::c_void, sync::Mutex};

use once_cell::sync::OnceCell;
use serde_json::{from_str, Value as JsonValue};
use swift_rs::SwiftArg;
use tauri::{AppHandle, Manager};

use crate::exception::{ExceptionError, ExceptionPayload, ExceptionType};

type SwiftCallbackFn = unsafe extern "C" fn(*const c_void, size: i32);
pub struct SwiftCallback(pub SwiftCallbackFn);
impl<'a> SwiftArg<'a> for SwiftCallback {
    type ArgType = SwiftCallbackFn;

    unsafe fn as_arg(&'a self) -> Self::ArgType {
        self.0
    }
}

pub type IAPResult = std::result::Result<JsonValue, String>;

pub static APP_HANDLE: OnceCell<Mutex<AppHandle>> = OnceCell::new();

/// event of rust to js
pub enum EmitEvents {
    ProductsUpdated,
    TransactionUpdated,
    RestoreCompleted,
}
impl EmitEvents {
    fn get_name(&self) -> &'static str {
        match self {
            EmitEvents::ProductsUpdated => "plugin_iap:products-updated",
            EmitEvents::TransactionUpdated => "plugin_iap:transactions-updated",
            EmitEvents::RestoreCompleted => "plugin_iap:restore-completed",
        }
    }
    fn get_exception_type(&self) -> ExceptionType {
        match self {
            EmitEvents::ProductsUpdated => ExceptionType::QueryProducts,
            EmitEvents::TransactionUpdated => ExceptionType::TransactionUpdated,
            EmitEvents::RestoreCompleted => ExceptionType::RestorePurchases,
        }
    }
}

pub fn emit_event<'a, T>(event: EmitEvents, arg1: *const c_void, size: i32)
where
    T: serde::Serialize + Clone + serde::Deserialize<'a>,
{
    let data_slice = unsafe { std::slice::from_raw_parts(arg1 as *const u8, size as usize) };
    let data_str = std::str::from_utf8(data_slice).unwrap();
    let app = APP_HANDLE.get().unwrap().lock();
    if let Ok(app_handle) = app {
        match from_str::<T>(data_str) {
            Ok(data) => {
                app_handle.emit_all(event.get_name(), data).unwrap();
            }
            Err(e) => {
                app_handle
                    .emit_all(
                        "plugin_iap:exception",
                        ExceptionPayload {
                            r#type: event.get_exception_type(),
                            payload: ExceptionError {
                                code: -1,
                                message: format!("Failed to parse json: {}. {}", e, data_str),
                            },
                        },
                    )
                    .unwrap();
            }
        }
    }
}

pub fn emit_void(event: EmitEvents) {
    let app = APP_HANDLE.get().unwrap().lock();
    if let Ok(app_handle) = app {
        app_handle
            .emit_all(event.get_name(), Option::<usize>::None)
            .unwrap();
    }
}

pub fn emit_exception(arg1: *const c_void, size: i32) {
    let data_slice = unsafe { std::slice::from_raw_parts(arg1 as *const u8, size as usize) };
    let data_str = std::str::from_utf8(data_slice).unwrap();
    let app = APP_HANDLE.get().unwrap().lock();
    if let Ok(app_handle) = app {
        match from_str::<ExceptionPayload>(data_str) {
            Ok(data) => {
                app_handle.emit_all("plugin_iap:exception", data).unwrap();
            }
            Err(e) => {
                app_handle
                    .emit_all(
                        "plugin_iap:exception",
                        ExceptionPayload {
                            r#type: ExceptionType::JsonParse,
                            payload: ExceptionError {
                                code: -1,
                                message: format!("Failed to parse json: {}.", e),
                            },
                        },
                    )
                    .unwrap();
            }
        }
    }
}
