#[derive(serde::Serialize, serde::Deserialize, Clone)]
pub struct ExceptionError {
    pub code: i32,
    pub message: String,
}

#[derive(serde::Serialize, serde::Deserialize, Clone)]
pub enum ExceptionType {
    QueryProducts,
    RestorePurchases,
    Purchase,
    TransactionUpdated,
    JsonParse,
}

#[derive(serde::Serialize, serde::Deserialize, Clone)]
pub struct ExceptionPayload {
    pub r#type: ExceptionType,
    pub payload: ExceptionError,
}
