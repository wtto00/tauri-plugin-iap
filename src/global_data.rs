use std::sync::Mutex;

use objc2::rc::Retained;
use once_cell::sync::OnceCell;
use serde_json::Value as JsonValue;

use crate::products_request_delegate::ProductsRequestDelegate;

type THandler = OnceCell<Mutex<Box<dyn FnMut(&str, JsonValue) + Send + 'static>>>;

static EMIT_HANDLER: THandler = OnceCell::new();

pub fn set_emit_handler<F: FnMut(&str, JsonValue) + Send + 'static>(
    handler: F,
) -> Result<(), std::sync::Mutex<Box<(dyn for<'a> FnMut(&'a str, JsonValue) + Send + 'static)>>> {
    EMIT_HANDLER.set(Mutex::new(Box::new(handler)))
}

pub fn emit_event(event: &str, payload: JsonValue) {
    let mut cb = EMIT_HANDLER.get().unwrap().lock().unwrap();
    cb(event, payload);
}

pub static mut DELEGATE: Option<Retained<ProductsRequestDelegate>> = None;
