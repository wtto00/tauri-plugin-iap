#[derive(serde::Serialize, serde::Deserialize, Clone)]
enum IPeriodUnit {
    Minute,
    Hour,
    Day,
    Week,
    Month,
    Year,
}

#[derive(serde::Serialize, serde::Deserialize, Clone)]
enum PaymentMode {
    PayAsYouGo,
    UpFront,
    FreeTrial,
}

#[derive(serde::Serialize, serde::Deserialize, Clone)]
enum DiscountType {
    Introductory,
    Subscription,
}

#[derive(serde::Serialize, serde::Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
struct Discount {
    id: String,
    r#type: DiscountType,
    price: String,
    price_micros: f32,
    period: i32,
    period_unit: IPeriodUnit,
    payment_mode: PaymentMode,
}

#[derive(serde::Serialize, serde::Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct Product {
    id: String,
    title: String,
    description: String,
    price: f32,
    price_micros: f32,
    currency: String,
    country_code: Option<String>,
    currency_symbol: Option<String>,
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
