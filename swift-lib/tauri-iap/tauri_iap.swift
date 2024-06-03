import StoreKit

let Tag = "Tauri-IAP:"

func canMakePayments() -> Bool {
  print(Tag, "swift_can_make_payments")
  return SKPaymentQueue.canMakePayments()
}

func queryProducts(productIDs: RustVec<RustString>) {
  ProductRequest.shared.startRequestProducts(Set(productIDs.map { $0.as_str().toString() }))
}

class ProductRequest: NSObject, SKProductsRequestDelegate {
  static let shared = ProductRequest()
  private var productsRequest: SKProductsRequest?

  func startRequestProducts(_ productIDs: Set<String>) {
    print(Tag, "startRequestProducts: ", productIDs)

    productsRequest?.cancel()

    productsRequest = SKProductsRequest(productIdentifiers: productIDs)
    productsRequest!.delegate = self
    productsRequest!.start()
  }

  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    let products = response.products
    let invalidProductIdentifiers = response.invalidProductIdentifiers

    // Handle valid products
      // let validProducts: RustVec<Rust> = []
    rustUpdateProducts()

    clearRequestAndHandler()
  }

  func productsRequest(_ request: SKProductsRequest, didFailWithError error: Error) {
    // Handle request failure
    print(Tag, "productsRequest error: ", error.localizedDescription)
    rustExceptionCallback("QueryProducts", -1, error.localizedDescription)
    clearRequestAndHandler()
  }

  func request(_ request: SKRequest, didFailWithError error: any Error) {
    print(Tag, "productsRequest - didFailWithError: ", error.localizedDescription)
    rustExceptionCallback("QueryProducts", -1, error.localizedDescription)
    clearRequestAndHandler()
  }

  private func clearRequestAndHandler() {
    productsRequest = nil
  }
}
