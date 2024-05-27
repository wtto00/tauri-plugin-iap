use std::fmt::Display;

use serde_json::{Map as JsonMap, Value as JsonValue};

pub enum IAPExceptionType {
    QueryProductDetails,
}

impl Display for IAPExceptionType {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            IAPExceptionType::QueryProductDetails => write!(f, "queryProductDetails"),
        }
    }
}

pub struct IAPException {
    pub r#type: IAPExceptionType,
    pub message: String,
}

impl IAPException {
    pub fn to_json(&self) -> JsonValue {
        let mut event = JsonMap::new();
        event.insert(
            "type".to_string(),
            JsonValue::String(self.r#type.to_string()),
        );
        event.insert(
            "message".to_string(),
            JsonValue::String(self.message.clone()),
        );
        JsonValue::Object(event)
    }
}
