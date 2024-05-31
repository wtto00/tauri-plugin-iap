// The Swift Programming Language
// https://docs.swift.org/swift-book

import StoreKit
import SwiftRs

typealias AppleCallback = @convention(c) (UnsafeRawPointer?, Int32) -> Void

let Tag = "TauriIAP:"

@_cdecl("is_available")
func isAvailable() -> Bool {
  print(Tag, "isAvailable")
  return SKPaymentQueue.canMakePayments()
}

@_cdecl("purchase_subscription")
func purchaseSubscription(
  productId: SRString, callback_complete: AppleCallback, callback_error: AppleCallback
) {
  print(Tag, "Apple in-app purchase")
  ProductRequest.shared.requestProducts(
    for: [productId.toString()],
    completionHandler: { products, error in
      print(Tag, "Apple in-app products - callback")
      if let error = error {
        print(Tag, "Apple in-app products - got an error")
        let errorDict = ["error": "\(error)"]
        let serializedData = try! JSONSerialization.data(withJSONObject: errorDict)
        let dataPointer = serializedData.withUnsafeBytes { $0.baseAddress }
        let dataSize = serializedData.count
        callback_error(dataPointer, Int32(dataSize))
        return
      }
      if let products = products {
        let subscriptionData: [String: String] = [:]
        guard let product = products.first else {
          let serializedData = try! JSONSerialization.data(withJSONObject: subscriptionData)
          let dataPointer = serializedData.withUnsafeBytes { $0.baseAddress }
          let dataSize = serializedData.count
          callback_complete(dataPointer, Int32(dataSize))
          return
        }
        SubscriptionManager.shared.purchaseSubscription(
          product: product, callback_complete: callback_complete, callback_error: callback_error)
      }
    })
}

@_cdecl("query_products")
func queryProducts(
  productId: SRString, callback_complete: AppleCallback, callback_error: AppleCallback
) {
  print(Tag, "Apple in-app purchase - query products")
  ProductRequest.shared.requestProducts(
    for: [Set(productId.toString().components(separatedBy: ",")).first!],
    completionHandler: { products, error in
      if let error = error {
        print(Tag, "Apple in-app products - got an error")
        let errorDict = ["error": "\(error)"]
        emitCallback(data: errorDict, callback: callback_error)
        return
      }
      if let products = products {
        print(Tag, "Apple in-app products - found a product")
        var skProducts = []
        for product in products {
          let skProduct: [String: Any] = [
            "productIdentifier": product.productIdentifier,
            "price": product.price.stringValue,
            "priceLocale": product.priceLocale.identifier,
            "priceCurrencyCode": product.priceLocale.currencyCode ?? "",
            "priceCurrency": product.priceLocale.currencySymbol ?? "",
            "subscriptionPeriod": getSubscriptionPeriod(
              subscriptionPeriod: product.subscriptionPeriod),
            "introductoryPrice": discountToString(discount: product.introductoryPrice),
            "discounts": discountsToString(discounts: product.discounts),
          ]
          skProducts.append(skProduct)
        }
        emitCallback(data: skProducts, callback: callback_complete)
        return
      }
      print(Tag, "No products and no error?")
    })
}

func emitCallback(data: Any, callback: AppleCallback?) {
  let serializedData = try! JSONSerialization.data(withJSONObject: data)
  let dataPointer = serializedData.withUnsafeBytes { $0.baseAddress }
  let dataSize = serializedData.count
  callback?(dataPointer, Int32(dataSize))
}

func discountsToString(discounts: [SKProductDiscount]) -> [[String: String]] {
  var skDiscounts: [[String: String]] = []
  for discount in discounts {
    let data = discountToString(discount: discount)
    skDiscounts.append(data)
  }
  return skDiscounts
}

func discountToString(discount: SKProductDiscount?) -> [String: String] {
  guard let discount = discount else {
    return [:]
  }
  let priceFormatter = NumberFormatter()
  priceFormatter.numberStyle = .currency
  let formattedPrice = priceFormatter.string(from: discount.price)
  let skDiscount: [String: String] = [
    "discountPrice": formattedPrice ?? "",
    "discountPeriod": periodUnitToString(
      unit: discount.subscriptionPeriod.unit,
      numberOfUnits: discount.subscriptionPeriod.numberOfUnits),
    "discount": paymentModeToString(mode: discount.paymentMode),
  ]
  return skDiscount
}

func periodUnitToString(unit: SKProduct.PeriodUnit, numberOfUnits: Int) -> String {
  var periodString = "\(numberOfUnits)"
  switch unit {
  case .day:
    periodString += " day"
  case .week:
    periodString += " week"
  case .month:
    periodString += " month"
  case .year:
    periodString += " year"
  @unknown default:
    periodString += " unit"
  }
  if numberOfUnits > 1 {
    periodString += "s"
  }
  return periodString
}

func paymentModeToString(mode: SKProductDiscount.PaymentMode) -> String {
  switch mode {
  case .payAsYouGo:
    return "Pay as you go"
  case .payUpFront:
    return "Pay up front"
  case .freeTrial:
    return "Free trial"
  @unknown default:
    return "unknown"
  }
}

func getSubscriptionPeriod(subscriptionPeriod: SKProductSubscriptionPeriod?) -> String {
  if let subscriptionPeriod = subscriptionPeriod {
    let numberOfUnits = subscriptionPeriod.numberOfUnits
    let unit = subscriptionPeriod.unit

    // Format the subscription period as a string
    var periodString = "\(numberOfUnits)"
    switch unit {
    case .day:
      periodString += " day"
    case .week:
      periodString += " week"
    case .month:
      periodString += " month"
    case .year:
      periodString += " year"
    @unknown default:
      periodString += " unit"
    }

    // Add plural "s" if numberOfUnits > 1
    if numberOfUnits > 1 {
      periodString += "s"
    }

    if periodString == "1 month" {
      periodString = "Per month"
    }

    if periodString == "1 year" {
      periodString = "Yearly"
    }

    return periodString
  }
  return ""
}

class ProductRequest: NSObject, SKProductsRequestDelegate {
  static let shared = ProductRequest()
  private var productsRequest: SKProductsRequest?
  private var productsCompletionHandler: (([SKProduct]?, Error?) -> Void)?

  func requestProducts(
    for productIDs: Set<String>, completionHandler: @escaping ([SKProduct]?, Error?) -> Void
  ) {
    print(Tag, "requestProducts: ", productIDs)
    productsRequest?.cancel()
    productsCompletionHandler = completionHandler

    productsRequest = SKProductsRequest(productIdentifiers: productIDs)
    productsRequest!.delegate = self
    productsRequest!.start()
  }

  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    let products = response.products
    print(Tag, "productsRequest response: ", products.count)
    let invalidProductIdentifiers = response.invalidProductIdentifiers

    // Handle valid products
    productsCompletionHandler?(products, nil)

    // Handle invalid product identifiers if needed
    for invalidProductIdentifier in invalidProductIdentifiers {
      print("Invalid product identifier: \(invalidProductIdentifier)")
    }

    clearRequestAndHandler()
  }

  func productsRequest(_ request: SKProductsRequest, didFailWithError error: Error) {
    // Handle request failure
    print(Tag, "productsRequest error: ",error.localizedDescription)
    productsCompletionHandler?(nil, error)
    clearRequestAndHandler()
  }
    
  func requestDidFinish(_ request: SKRequest) {
    print(Tag, "productsRequest - requestDidFinish")
  }
  func request(_ request: SKRequest, didFailWithError error: any Error) {
    print(Tag, "productsRequest - didFailWithError: ",error.localizedDescription)
    productsCompletionHandler?(nil, error)
    clearRequestAndHandler()
  }

  private func clearRequestAndHandler() {
    productsRequest = nil
    productsCompletionHandler = nil
  }
}

class SubscriptionManager: NSObject, SKPaymentTransactionObserver {
  static let shared = SubscriptionManager()
  var successBlock: AppleCallback?
  var errorBlock: AppleCallback?

  override init() {
    super.init()
    SKPaymentQueue.default().add(self)
  }

  func purchaseSubscription(
    product: SKProduct, callback_complete: AppleCallback, callback_error: AppleCallback
  ) {
    self.successBlock = callback_complete
    self.errorBlock = callback_error
    print(Tag, "Can make payments")
    if SKPaymentQueue.canMakePayments() {
      print(Tag, "Product \(product.productIdentifier)")
      let payment = SKMutablePayment(product: product)
      payment.applicationUsername = "Testing"
      SKPaymentQueue.default().add(payment)
    } else {
      print(Tag, "User can't make payments")
      print("User can't make payments.")
    }
  }

  func restorePurchases() {
    SKPaymentQueue.default().restoreCompletedTransactions()
  }

  func paymentQueue(
    _ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]
  ) {
    for transaction in transactions {
      switch transaction.transactionState {
      case .purchased:
        print(Tag, "Subscription purchased \(transaction)")
        // Handle successful purchase
        complete(transaction: transaction)
        SKPaymentQueue.default().finishTransaction(transaction)
      case .failed:
        print(Tag, "Subscription failed \(String(describing: transaction.error))")
        // Handle failed transaction
        fail(transaction: transaction)
        SKPaymentQueue.default().finishTransaction(transaction)
      case .restored:
        print(Tag, "Subscription restored \(transaction)")
        // Handle restored transaction
        complete(transaction: transaction)
        SKPaymentQueue.default().finishTransaction(transaction)
      case .deferred:
        print(Tag, "Subscription in progress/deferred \(transaction)")
        // Transaction is in progress or deferred, no action needed
        complete(transaction: transaction)
      case .purchasing:
        print(Tag, "Subscription in progress/deferred \(transaction)")
        // Transaction is in progress or deferred, no action needed
        complete(transaction: transaction)
      @unknown default:
        break
      }
    }
  }

  func complete(transaction: SKPaymentTransaction) {
    print(Tag, "Transaction completed successfully.")
    let transactionData: [String: String] = [
      "productIdentifier": transaction.payment.productIdentifier,
      "transactionIdentifier": transaction.transactionIdentifier ?? "",
      "originalIdentifier": transaction.original?.transactionIdentifier ?? "",
      "applicationUsername": transaction.payment.applicationUsername ?? "",
      "transactionState": String(transaction.transactionState.rawValue),
      "transactionDate": transaction.transactionDate?.description ?? "",
    ]
    let serializedData = try! JSONSerialization.data(withJSONObject: transactionData)
    let dataPointer = serializedData.withUnsafeBytes { $0.baseAddress }
    let dataSize = serializedData.count
    self.successBlock?(dataPointer, Int32(dataSize))
  }

  func fail(transaction: SKPaymentTransaction) {
    print(Tag, "Transaction failed.")
    let transactionData: [String: String] = [
      "transactionState": String(transaction.transactionState.rawValue),
      "error": transaction.error?.localizedDescription ?? "",
    ]
    let serializedData = try! JSONSerialization.data(withJSONObject: transactionData)
    let dataPointer = serializedData.withUnsafeBytes { $0.baseAddress }
    let dataSize = serializedData.count
    self.errorBlock?(dataPointer, Int32(dataSize))
  }
}
