#[swift_bridge::bridge]
mod ffi {
    #[swift_bridge(already_declared, swift_repr = "struct")]
    struct Product;

    extern "Rust" {
        #[swift_bridge(swift_name = "rustUpdateProducts")]
        fn update_products(products: Vec<Product>);

        #[swift_bridge(swift_name = "rustExceptionCallback")]
        fn exception_callback(exception_type: String, code: u32, message: String);
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

use crate::exception::{ExceptionError, ExceptionPayload};
use crate::APP_HANDLE;
use product::Product;

// update_products
fn update_products(products: Vec<Product>) {
    let app = APP_HANDLE.get().unwrap().lock();
    if let Ok(app_handle) = app {
        app_handle
            .to_owned()
            .emit_all("plugin:iap|products-updated", products)
            .unwrap();
    }
}

// exception_callback
fn exception_callback(exception_type: String, code: u32, message: String) {
    let app = APP_HANDLE.get().unwrap().lock();
    if let Ok(app_handle) = app {
        app_handle
            .to_owned()
            .emit_all(
                "plugin:iap|exception",
                ExceptionPayload {
                    exception_type,
                    payload: ExceptionError { code, message },
                },
            )
            .unwrap();
    }
}

#[swift_bridge::bridge]
pub mod product {
    #[derive(serde::Serialize, Clone)]
    pub enum IPeriodUnit {
        Minute,
        Hour,
        Day,
        Week,
        Month,
        Year,
    }

    #[derive(serde::Serialize, Clone)]
    pub enum PaymentMode {
        PayAsYouGo,
        UpFront,
        FreeTrial,
    }

    #[derive(serde::Serialize, Clone)]
    pub enum DiscountType {
        Introductory,
        Subscription,
    }

    #[derive(serde::Serialize, Clone)]
    #[swift_bridge(swift_repr = "struct")]
    pub struct Discount {
        id: String,
        r#type: DiscountType,
        price: String,
        price_micros: f32,
        period: i32,
        period_unit: IPeriodUnit,
        payment_mode: PaymentMode,
    }

    #[derive(serde::Serialize, Clone)]
    #[swift_bridge(swift_repr = "struct")]
    pub struct Product {
        id: String,
        title: String,
        description: String,
        price: String,
        price_micros: f32,
        currency: String,
        country_code: String,
        intro_price: Option<String>,
        intro_price_micros: Option<f32>,
        intro_price_period: Option<i32>,
        intro_price_period_unit: Option<IPeriodUnit>,
        intro_price_payment_mode: Option<PaymentMode>,
        discounts: Option<Vec<Discount>>,
        group: Option<String>,
        billing_period: Option<i32>,
        billing_period_unit: Option<IPeriodUnit>,
    }
}
