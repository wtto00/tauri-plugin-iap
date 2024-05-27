use objc2::{
    declare_class, msg_send_id, mutability,
    rc::Retained,
    runtime::{NSObject, NSObjectProtocol},
    ClassType, DeclaredClass,
};
use objc2_foundation::NSError;
use objc2_store_kit::SKRequest;
use objc2_store_kit::{
    SKProductsRequest, SKProductsRequestDelegate, SKProductsResponse, SKRequestDelegate,
};
use serde_json::{Map, Value as JsonValue};

use crate::{
    exception::{IAPException, IAPExceptionType},
    global_data::emit_event,
};

declare_class!(
    #[derive(Debug)]
    pub struct ProductsRequestDelegate;

    unsafe impl ClassType for ProductsRequestDelegate {
        type Super = NSObject;
        type Mutability = mutability::InteriorMutable;
        const NAME: &'static str = "ProductsRequestDelegate";
    }

    impl DeclaredClass for ProductsRequestDelegate {
    }

    unsafe impl NSObjectProtocol for ProductsRequestDelegate {}

    unsafe impl SKRequestDelegate for ProductsRequestDelegate {
        #[method(requestDidFinish:)]
        unsafe fn request_did_finish(&self, _request: &SKRequest) {
            println!("requestDidFinish: {:?}", _request);
        }

        #[method(request:didFailWithError:)]
        unsafe fn request_did_fail_with_error(&self, _request: &SKRequest, error: &NSError) {
            println!("request_didFailWithError: {:?}", error);
            println!("request_didFailWithError: {:?}", error.code());
            println!("request_didFailWithError: {:?}", error.domain());
            println!("request_didFailWithError: {:?}", error.userInfo());
            println!("request_didFailWithError: {:?}", error.localizedDescription());
            println!("request_didFailWithError: {:?}", error.localizedFailureReason());
            println!("request_didFailWithError: {:?}", error.localizedRecoverySuggestion());
            emit_event("exception", IAPException {
                r#type: IAPExceptionType::QueryProductDetails,
                message: error.domain().to_string()
            }.to_json());
        }
    }

    unsafe impl SKProductsRequestDelegate for ProductsRequestDelegate {
        #[method(productsRequest:didReceiveResponse:)]
        unsafe fn products_request_did_receive_response(
            &self,
            _request: &SKProductsRequest,
            response: &SKProductsResponse,
        ) {
            let mut valid_products: Vec<JsonValue> = vec![];
            let origin_products = response.products();
            let products_count = origin_products.count();
            println!("products_count: {:?}", products_count);
            if products_count == 0 {
                return;
            };
            for index in 1..products_count {
                let product = origin_products.objectAtIndex(index);
                let mut product_item = Map::new();
                product_item.insert(
                    "id".to_string(),
                    JsonValue::String(product.productIdentifier().to_string()),
                );
                println!("product_item: {:?}", product_item);
                valid_products.push(JsonValue::Object(product_item));
            }
            println!("valid_products: {:?}", valid_products);
            emit_event("products-update", JsonValue::Array(valid_products));
        }
    }
);

impl ProductsRequestDelegate {
    pub fn new() -> Retained<Self> {
        unsafe { msg_send_id![Self::alloc(), init] }
    }
}
