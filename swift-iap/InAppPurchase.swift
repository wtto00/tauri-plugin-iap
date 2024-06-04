// The Swift Programming Language
// https://docs.swift.org/swift-book
import StoreKit
import SwiftRs

typealias SwiftCallback = @convention(c) (UnsafeRawPointer?, Int32) -> Void

let Tag = "TauriIAP:"

@_cdecl("swift_initialize")
func initialize(
  onProductUpdated: SwiftCallback, onTransactionUpdated: SwiftCallback, onException: SwiftCallback
) -> Bool {
  if SKPaymentQueue.canMakePayments() {
    ProductRequest.shared = ProductRequest(
      onProductUpdated: onProductUpdated, onException: onException)
    PaymentTransactionObserver.shared = PaymentTransactionObserver(
      onTransactionUpdated: onTransactionUpdated, onException: onException)
    return true
  }
  return false
}

@_cdecl("swift_can_make_payments")
func canMakePayments() -> Bool {
  print(Tag, "canMakePayments")
  return SKPaymentQueue.canMakePayments()
}

@_cdecl("swift_country_code")
func country_code() -> SRString {
  print(Tag, "country_code")
  return SRString(SKPaymentQueue.default().storefront?.countryCode ?? "")
}

@_cdecl("swift_query_products")
func queryProducts(productId: SRString) {
  print(Tag, "query products")
  ProductRequest.shared!.requestProducts(Set(productId.toString().components(separatedBy: ",")))
}

@_cdecl("swift_restore_purchases")
func restorePurchases(applicationUserName: SRString) {
  print(Tag, "restore purchases")
  let username = applicationUserName.toString()
  if username.isEmpty {
    PaymentTransactionObserver.shared!.restorePurchases(applicationUserName: nil)
  } else {
    PaymentTransactionObserver.shared!.restorePurchases(applicationUserName: username)
  }
}

@_cdecl("swift_request_pruchase")
func requestPruchase(
  productId: SRString, quantity: Int, applicationUserName: SRString
) {
  print(Tag, "request pruchase")
  PaymentTransactionObserver.shared!.purchase(
    productId: productId.toString(), quantity: quantity,
    applicationUserName: applicationUserName.toString())
}

@_cdecl("swift_complete_pruchase")
func completePruchase(transactionId: SRString) {
  print(Tag, "complete pruchase")
}

func emitCallback(data: Any, callback: SwiftCallback?) {
  let serializedData = try! JSONSerialization.data(withJSONObject: data)
  let dataPointer = serializedData.withUnsafeBytes { $0.baseAddress }
  let dataSize = serializedData.count
  callback?(dataPointer, Int32(dataSize))
}
func emitException(type: String, code: any Numeric, message: String, callback: SwiftCallback?) {
  let serializedData = try! JSONSerialization.data(withJSONObject: [
    "type": type,
    "payload": [
      "code": code,
      "message": message,
    ],
  ])
  let dataPointer = serializedData.withUnsafeBytes { $0.baseAddress }
  let dataSize = serializedData.count
  callback?(dataPointer, Int32(dataSize))
}

func priceLocaleCurrencyCode(_ priceLocale: Locale) -> String {
  let numberFormatter = NumberFormatter()
  numberFormatter.locale = priceLocale
  return numberFormatter.currencyCode
}
func productUnitToString(_ unit: SKProduct.PeriodUnit?) -> String? {
  switch unit {
  case .day:
    return "Day"
  case .week:
    return "Week"
  case .month:
    return "Month"
  case .year:
    return "Year"
  default:
    return nil
  }
}
func productPaymentModeToString(_ mode: SKProductDiscount.PaymentMode?) -> String? {
  switch mode {
  case .payAsYouGo:
    return "PayAsYouGo"
  case .payUpFront:
    return "UpFront"
  case .freeTrial:
    return "FreeTrial"
  default:
    return nil
  }
}
func productDiscountTypeToString(_ type: SKProductDiscount.`Type`) -> String? {
  switch type {
  case .introductory:
    return "Introductory"
  case .subscription:
    return "Subscription"
  default:
    return nil
  }
}

class ProductRequest: NSObject, SKProductsRequestDelegate {
  static var shared: ProductRequest?
  private var onProductUpdated: SwiftCallback?
  private var onException: SwiftCallback?
  var products: [String: SKProduct] = [:]

  init(onProductUpdated: SwiftCallback, onException: SwiftCallback) {
    self.onProductUpdated = onProductUpdated
    self.onException = onException
  }

  private var productsRequest: SKProductsRequest?

  func requestProducts(
    _ productIDs: Set<String>
  ) {
    print(Tag, "requestProducts: ", productIDs)

    productsRequest = SKProductsRequest(productIdentifiers: productIDs)
    productsRequest!.delegate = self
    productsRequest!.start()
  }

  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    // Handle valid products
    var skProducts: [[String: Any?]] = []
    for product in response.products {
      products.updateValue(product, forKey: product.productIdentifier)

      let discounts: [[String: Any?]] = product.discounts.map { discount in
        return [
          "id": discount.identifier,
          "type": productDiscountTypeToString(discount.type),
          "price": discount.price,
          "priceMicros": discount.price.multiplying(byPowerOf10: 6),
          "period": discount.numberOfPeriods * discount.subscriptionPeriod.numberOfUnits,
          "periodUnit": productUnitToString(discount.subscriptionPeriod.unit),
          "paymentMode": productPaymentModeToString(discount.paymentMode),
        ]
      }
      var countryCode = product.priceLocale.regionCode
      if #available(macOS 13, *) {
        countryCode = product.priceLocale.region?.identifier
      }
      skProducts.append([
        "id": product.productIdentifier,
        "title": product.localizedTitle,
        "description": product.localizedDescription,
        "price": product.price,
        "priceMicros": product.price.multiplying(byPowerOf10: 6),
        "currency": priceLocaleCurrencyCode(product.priceLocale),
        "countryCode": countryCode,
        "currencySymbol": product.priceLocale.currencySymbol,
        "introPrice": product.introductoryPrice?.price,
        "introPriceMicros": product.introductoryPrice?.price.multiplying(byPowerOf10: 6),
        "introPricePeriod": product.introductoryPrice != nil
          ? product.introductoryPrice!.numberOfPeriods
            * product.introductoryPrice!.subscriptionPeriod.numberOfUnits : nil,
        "introPricePeriodUnit": productUnitToString(
          product.introductoryPrice?.subscriptionPeriod.unit),
        "introPricePaymentMode": productPaymentModeToString(
          product.introductoryPrice?.paymentMode),
        "discounts": discounts,
        "group": product.subscriptionGroupIdentifier,
        "billingPeriod": product.subscriptionPeriod?.numberOfUnits,
        "billingPeriodUnit": productUnitToString(product.subscriptionPeriod?.unit),
      ])
    }
    emitCallback(data: skProducts, callback: onProductUpdated)
  }

  func productsRequest(_ request: SKProductsRequest, didFailWithError error: Error) {
    // Handle request failure
    print(Tag, "products request error: ", error.localizedDescription)
    emitException(
      type: "QueryProducts", code: 1, message: error.localizedDescription, callback: onException)
  }

  func request(_ request: SKRequest, didFailWithError error: any Error) {
    print(Tag, "products request - didFailWithError: ", error.localizedDescription)
    emitException(
      type: "QueryProducts", code: 2, message: error.localizedDescription, callback: onException)
  }
}

class PaymentTransactionObserver: NSObject, SKPaymentTransactionObserver {
  static var shared: PaymentTransactionObserver?
  private var onTransactionUpdated: SwiftCallback?
  private var onException: SwiftCallback?
  var cachedTransactions: [String: SKPaymentTransaction] = [:]

  init(onTransactionUpdated: SwiftCallback, onException: SwiftCallback) {
    super.init()
    self.onTransactionUpdated = onTransactionUpdated
    self.onException = onException
    SKPaymentQueue.default().add(self)
  }

  func purchase(productId: String, quantity: Int, applicationUserName: String) {
    let product = ProductRequest.shared?.products[productId]
    if product == nil {
      emitException(
        type: "Purchase", code: 4, message: "Product does not exist.", callback: onException)
    } else {
      let payment = SKMutablePayment(product: product!)
      if !applicationUserName.isEmpty {
        payment.applicationUsername = applicationUserName
      }
      payment.quantity = quantity
      SKPaymentQueue.default().add(payment)
    }
  }

  func restorePurchases(applicationUserName: String?) {
    SKPaymentQueue.default().restoreCompletedTransactions(
      withApplicationUsername: applicationUserName)
  }

  func completePruchase(transactionId: String) {
    let transaction = cachedTransactions[transactionId]
    if transaction != nil {
      SKPaymentQueue.default().finishTransaction(transaction!)
    }
  }

  func paymentQueue(
    _ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]
  ) {
    var skTransactions: [[String: Any?]] = []
    for transaction in transactions {
      if transaction.transactionIdentifier != nil {
        // purchased or restored
        cachedTransactions.updateValue(transaction, forKey: transaction.transactionIdentifier!)
      }
      var receiptString: String? = nil
      if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
        FileManager.default.fileExists(atPath: appStoreReceiptURL.path)
      {
        do {
          let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
          receiptString = receiptData.base64EncodedString(options: [])
        } catch {
          print(Tag, "Couldn't read receipt data with error: " + error.localizedDescription)
        }
      }
      skTransactions.append([
        "productId": transaction.payment.productIdentifier,
        "transactionId": transaction.transactionIdentifier,
        "transactionDate": transaction.transactionDate,
        "status": transaction.transactionState,
        "error": transaction.error?.localizedDescription,
        "applicationUserName": transaction.payment.applicationUsername,
        "originalIdentifier": transaction.original?.transactionIdentifier,
        "receiptData": receiptString,
      ])
      emitCallback(data: skTransactions, callback: onTransactionUpdated)
    }
  }

  // Failed to restore purchase
  func paymentQueue(
    _ queue: SKPaymentQueue, restoreCompletedTransactionsFailedWithError error: any Error
  ) {
    emitException(
      type: "RestorePurchases", code: 3, message: error.localizedDescription,
      callback: onException)
  }
}
