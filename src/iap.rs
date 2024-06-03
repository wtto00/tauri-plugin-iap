use objc2::{
    rc::Retained,
    runtime::{NSObjectProtocol, ProtocolObject},
    ClassType, Encoding, Message, RefEncode,
};
use objc2_foundation::{NSArray, NSError, NSSet, NSString};
use objc2_store_kit::{
    SKPayment, SKPaymentQueue, SKPaymentTransaction, SKPaymentTransactionObserver,
    SKPaymentTransactionState, SKProduct, SKProductsRequest,
};
use serde_json::Value as JsonValue;

use crate::{
    global_data::{set_emit_handler, DELEGATE},
    products_request_delegate::ProductsRequestDelegate,
};

#[derive(Default)]
pub struct IAP {
    pub initialized: bool,
}

impl IAP {
    pub fn can_make_payments() -> bool {
        unsafe { SKPaymentQueue::canMakePayments() }
    }
}

impl IAP {
    pub fn init<F: FnMut(&str, JsonValue) + Send + 'static>(
        &mut self,
        handler: F,
    ) -> Result<(), &str> {
        if Self::can_make_payments() {
            self.initialized = true;
            set_emit_handler(handler).map_err(|_e| "Failed to initialize listen callback.")
        } else {
            Err("System does't support Apple IAP.")
        }
    }

    pub fn start_product_request(&self, identifiers: Vec<String>) {
        if identifiers.is_empty() {
            return;
        };
        let identifiers_set: Retained<NSSet<NSString>> = NSSet::new();
        for identifier in identifiers {
            unsafe { identifiers_set.setByAddingObject(&NSString::from_str(identifier.as_str())) };
        }
        let request = unsafe {
            SKProductsRequest::initWithProductIdentifiers(
                SKProductsRequest::alloc(),
                identifiers_set.as_ref(),
            )
        };
        let delegate = ProductsRequestDelegate::new();
        println!("delegate: {:?}", delegate);
        unsafe { request.setDelegate(Some(ProtocolObject::from_ref(&*delegate))) };
        unsafe { request.start() };
        unsafe {
            DELEGATE = Some(delegate);
        };
    }
}

unsafe impl RefEncode for IAP {
    const ENCODING_REF: Encoding = Encoding::Object;
}
unsafe impl Message for IAP {}
unsafe impl NSObjectProtocol for IAP {}

unsafe impl SKPaymentTransactionObserver for IAP {
    unsafe fn paymentQueue_updatedTransactions(
        &self,
        _queue: &SKPaymentQueue,
        transactions: &NSArray<SKPaymentTransaction>,
    ) {
        let mut state: Option<String> = None;
        let mut product_id: Option<String> = None;
        let mut transaction_identifier: Option<String> = None;
        let mut transaction_date: Option<String> = None;
        let discount_id: Option<String> = None;

        let len = transactions.len();
        let mut index = 0;
        loop {
            if index >= len {
                break;
            }
            if let Some(transaction) = transactions.get(index) {
                product_id = Some(transaction.payment().productIdentifier().to_string());
                match transaction.transactionState() {
                    SKPaymentTransactionState::Purchasing => {
                        state = Some("PaymentTransactionStatePurchasing".to_string());
                    }
                    SKPaymentTransactionState::Purchased => {
                        state = Some("PaymentTransactionStatePurchased".to_string());
                        transaction_identifier =
                            transaction.transactionIdentifier().map(|s| s.to_string());
                        transaction_date = transaction
                            .transactionDate()
                            .map(|d| d.timeIntervalSince1970().to_string())
                    }
                    SKPaymentTransactionState::Restored => {
                        state = Some("PaymentTransactionStateRestored".to_string());
                    }
                    SKPaymentTransactionState::Failed => {
                        state = Some("PaymentTransactionStateFailed".to_string());
                    }
                    SKPaymentTransactionState::Deferred => {
                        state = Some("PaymentTransactionStateDeferred".to_string());
                    }
                    _ => {
                        continue;
                    }
                }
            } else {
                index += 1;
                continue;
            }
        }
    }

    unsafe fn paymentQueue_removedTransactions(
        &self,
        _queue: &SKPaymentQueue,
        _transactions: &NSArray<SKPaymentTransaction>,
    ) {
    }

    unsafe fn paymentQueue_restoreCompletedTransactionsFailedWithError(
        &self,
        _queue: &SKPaymentQueue,
        _error: &NSError,
    ) {
    }

    unsafe fn paymentQueueRestoreCompletedTransactionsFinished(&self, _queue: &SKPaymentQueue) {}

    unsafe fn paymentQueue_shouldAddStorePayment_forProduct(
        &self,
        _queue: &SKPaymentQueue,
        _payment: &SKPayment,
        _product: &SKProduct,
    ) -> bool {
        true
    }

    unsafe fn paymentQueueDidChangeStorefront(&self, _queue: &SKPaymentQueue) {}

    unsafe fn paymentQueue_didRevokeEntitlementsForProductIdentifiers(
        &self,
        _queue: &SKPaymentQueue,
        _product_identifiers: &NSArray<NSString>,
    ) {
    }
}
