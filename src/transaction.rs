#[derive(serde_repr::Serialize_repr, serde_repr::Deserialize_repr, Clone)]
#[repr(u8)]
enum TransactionStatus {
    Pending = 0,
    Purchased = 1,
    Failed = 2,
    Restored = 3,
    Deferred = 4,
}

#[derive(serde::Serialize, serde::Deserialize, Clone)]
#[serde(rename_all = "camelCase")]
pub struct Transaction {
    product_id: String,
    transaction_id: Option<String>,
    transaction_date: Option<i32>,
    status: TransactionStatus,
    error: Option<String>,
    application_user_name: Option<String>,
    original_identifier: Option<String>,
    receipt_data: Option<String>,
}
