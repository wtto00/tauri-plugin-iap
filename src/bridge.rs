#[swift_bridge::bridge]
mod ffi {
    extern "Rust" {
        #[swift_bridge(swift_name = "rustProductCallback")]
        fn product_callback(products: Vec<Product>);

        #[swift_bridge(swift_name = "rustExceptionCallback")]
        fn exception_callback(r#type: String, code: u32, message: String);
    }

    extern "Swift" {
        #[swift_bridge(swift_name = "canMakePayments")]
        fn swift_can_make_payments() -> bool;

        #[swift_bridge(swift_name = "queryProducts")]
        fn swift_query_products(productIDs: Vec<String>);
    }
}

pub use ffi::swift_can_make_payments;
pub use ffi::swift_query_products;
use tauri::Manager;

use crate::exception::ExceptionError;
use crate::exception::ExceptionPayload;
use crate::product::Product;
use crate::APP_HANDLE;

// product_callback
fn product_callback(products: Vec<Product>) {
    let app = APP_HANDLE.get().unwrap().lock();
    if let Ok(app_handle) = app {
        app_handle
            .to_owned()
            .emit_all("plugin:iap|products-updated", products)
            .unwrap();
    }
}

// exception_callback
fn exception_callback(r#type: ExceptionType, code: u32, message: String) {
    let app = APP_HANDLE.get().unwrap().lock();
    if let Ok(app_handle) = app {
        app_handle
            .to_owned()
            .emit_all(
                "plugin:iap|exception",
                ExceptionPayload {
                    r#type,
                    payload: ExceptionError { code, message },
                },
            )
            .unwrap();
    }
}
