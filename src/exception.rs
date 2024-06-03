#[derive(serde::Serialize, Clone)]
pub struct ExceptionError {
    pub code: u32,
    pub message: String,
}

#[derive(serde::Serialize, Clone)]
pub struct ExceptionPayload {
    pub exception_type: String,
    pub payload: ExceptionError,
}
