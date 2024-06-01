#[derive(serde::Serialize, Clone)]
pub struct ExceptionError {
    pub code: u32,
    pub message: String,
}

#[derive(serde::Serialize, Clone)]
enum ExceptionType {
    QueryProducts,
}

#[derive(serde::Serialize, Clone)]
pub struct ExceptionPayload {
    pub r#type: ExceptionType,
    pub payload: ExceptionError,
}
