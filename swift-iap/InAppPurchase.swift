//
//  InAppPurchase.swift
//  TauriIAP
//
//  Created by wtto on 2024/6/5.
//

import OSLog
import StoreKit
import SwiftRs

typealias SwiftCallback = @convention(c) (UnsafeRawPointer?, Int32) -> Void

let log = OSLog(subsystem: "tauri", category: "plugin.apple.iap")

@_cdecl("swift_initialize")
func initialize(
  onProductsUpdated: SwiftCallback,
  onTransactionsUpdated: SwiftCallback,
  onRestoreCompleted: SwiftCallback,
  onException: SwiftCallback
) -> Bool {
  os_log(.debug, log: log, "initialize")
  if SKPaymentQueue.canMakePayments() {
    InAppPurchaseHandler.shared = InAppPurchaseHandler(
      onProductsUpdated: onProductsUpdated,
      onTransactionsUpdated: onTransactionsUpdated,
      onRestoreCompleted: onRestoreCompleted,
      onException: onException
    )
    return true
  }
  return false
}

@_cdecl("swift_can_make_payments")
func canMakePayments() -> Bool {
  os_log(.debug, log: log, "can make payments")
  return SKPaymentQueue.canMakePayments()
}

@_cdecl("swift_country_code")
func countryCode() -> SRString? {
  os_log(.debug, log: log, "country code")
  let country = SKPaymentQueue.default().storefront?.countryCode
  if country == nil {
    return nil
  }
  return SRString(SKPaymentQueue.default().storefront!.countryCode)
}

@_cdecl("swift_query_products")
func queryProducts(productId: SRString) {
  os_log(.debug, log: log, "query products")
  InAppPurchaseHandler.shared!.requestProducts(
    Set(productId.toString().components(separatedBy: ","))
  )
}

@_cdecl("swift_restore_purchases")
func restorePurchases(applicationUserName: SRString) {
  os_log(.debug, log: log, "restore purchases")
  InAppPurchaseHandler.shared!.restore(applicationUserName.toString())
}

@_cdecl("swift_request_pruchase")
func requestPruchase(
  productId: SRString,
  quantity: Int,
  applicationUserName: SRString
) {
  os_log(.debug, log: log, "request pruchase")
  InAppPurchaseHandler.shared!.purchase(
    productId: productId.toString(),
    quantity: quantity,
    applicationUserName: applicationUserName.toString()
  )
}

@_cdecl("swift_finish_transaction")
func finishTransaction(transactionId: SRString) {
  os_log(.debug, log: log, "finish transaction")
  InAppPurchaseHandler.shared!.finishTransaction(transactionId.toString())
}

class InAppPurchaseHandler: NSObject {
  static var shared: InAppPurchaseHandler?

  private let onProductsUpdated: SwiftCallback
  private let onTransactionsUpdated: SwiftCallback
  private let onRestoreCompleted: SwiftCallback
  private let onException: SwiftCallback

  private var productsRequest: SKProductsRequest?
  private var products: [String: SKProduct] = [:]
  private var transactions: [String: SKPaymentTransaction] = [:]

  init(
    onProductsUpdated: SwiftCallback,
    onTransactionsUpdated: SwiftCallback,
    onRestoreCompleted: SwiftCallback,
    onException: SwiftCallback
  ) {
    self.onProductsUpdated = onProductsUpdated
    self.onTransactionsUpdated = onTransactionsUpdated
    self.onRestoreCompleted = onRestoreCompleted
    self.onException = onException
    super.init()
    SKPaymentQueue.default().add(self)
  }
}
// MARK: Impl SKPaymentTransactionObserver
extension InAppPurchaseHandler: SKPaymentTransactionObserver {
  func paymentQueue(
    _ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]
  ) {
    os_log(
      .debug,
      log: log,
      "paymentQueue updatedTransactions receiptString"
    )
    sendTransactions(transactions)
  }

  // Failed to restore purchase
  func paymentQueue(
    _ queue: SKPaymentQueue,
    restoreCompletedTransactionsFailedWithError error: any Error
  ) {
    os_log(.debug, log: log, "paymentQueue restoreCompletedTransactionsFailedWithError")
    emitException(
      type: "RestorePurchases",
      code: 3,
      message: error.localizedDescription
    )
  }

  func paymentQueueRestoreCompletedTransactionsFinished(_ queue: SKPaymentQueue) {
    os_log(.debug, log: log, "paymentQueueRestoreCompletedTransactionsFinished")
    emitVoidCallback(onRestoreCompleted)
  }

  func paymentQueue(
    _ queue: SKPaymentQueue, removedTransactions transactions: [SKPaymentTransaction]
  ) {
    os_log(.debug, log: log, "paymentQueue removedTransactions")
  }
}
// MARK: Impl SKProductsRequestDelegate
extension InAppPurchaseHandler: SKProductsRequestDelegate {
  func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
    os_log(
      .debug,
      log: log,
      "productsRequest didReceive: %s",
      response.products.map { $0.productIdentifier }.joined()
    )
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
    emitProductsUpdated(skProducts)
  }

  func productsRequest(_ request: SKProductsRequest, didFailWithError error: Error) {
    // Handle request failure
    os_log(.debug, log: log, "products request error: %s", error.localizedDescription)
    emitException(type: "QueryProducts", code: 1, message: error.localizedDescription)
  }

  func request(_ request: SKRequest, didFailWithError error: any Error) {
    os_log(.debug, log: log, "products request - didFailWithError: %s", error.localizedDescription)
    emitException(type: "QueryProducts", code: 2, message: error.localizedDescription)
  }
}
// MARK: Public methods
extension InAppPurchaseHandler {
  func requestProducts(_ productIds: Set<String>) {
    os_log(.debug, log: log, "requestProducts: %s", productIds.joined())

    productsRequest = SKProductsRequest(productIdentifiers: productIds)
    productsRequest!.delegate = self
    productsRequest!.start()
  }

  func purchase(productId: String, quantity: Int, applicationUserName: String) {
    let product = products[productId]
    if product == nil {
      emitException(type: "Purchase", code: 4, message: "Product does not exist.")
    } else {
      let payment = SKMutablePayment(product: product!)
      if !applicationUserName.isEmpty {
        payment.applicationUsername = applicationUserName
      }
      payment.quantity = quantity
      SKPaymentQueue.default().add(payment)
    }
  }

  func finishTransaction(_ transactionId: String) {
    let transaction = transactions[transactionId]
    if transaction != nil {
      SKPaymentQueue.default().finishTransaction(transaction!)
    } else {
      os_log(
        .debug, log: log,
        "finishTransaction: The transaction you want to finish is not exist. Maybe you should call restorePurchases firstly or the transactionId is invalid."
      )
    }
  }

  func restore(_ applicationUserName: String) {
    if applicationUserName.isEmpty {
      SKPaymentQueue.default().restoreCompletedTransactions()
    } else {
      SKPaymentQueue.default().restoreCompletedTransactions(
        withApplicationUsername: applicationUserName)
    }
  }
}
// MARK: Emit rust methods
extension InAppPurchaseHandler {
  private func emitProductsUpdated(_ data: [[String: Any?]]) {
    emitCallback(
      data: data,
      callback: onProductsUpdated
    )
  }

  private func emitTransactionsUpdated(_ data: [[String: Any?]]) {
    emitCallback(
      data: data,
      callback: onTransactionsUpdated
    )
  }

  private func emitException(type: String, code: Int8, message: String) {
    emitCallback(
      data: [
        "type": type,
        "payload": [
          "code": code,
          "message": message,
        ],
      ],
      callback: onException
    )
  }
  private func emitCallback(data: Any, callback: SwiftCallback) {
    do {
      let serializedData = try JSONSerialization.data(withJSONObject: data)
      let dataPointer = serializedData.withUnsafeBytes { $0.baseAddress }
      let dataSize = serializedData.count
      callback(dataPointer, Int32(dataSize))
    } catch let jsonException {
      os_log(.error, log: log, "JSON parse error: %s", jsonException.localizedDescription)
    }
  }
  private func emitVoidCallback(_ callback: SwiftCallback) {
    callback(nil, 0)
  }
}
// MARK: Util Methods
extension InAppPurchaseHandler {
  private func getReceiptString() -> String? {
    var receiptString: String?
    if let appStoreReceiptURL = Bundle.main.appStoreReceiptURL,
      FileManager.default.fileExists(atPath: appStoreReceiptURL.path)
    {
      do {
        let receiptData = try Data(contentsOf: appStoreReceiptURL, options: .alwaysMapped)
        receiptString = receiptData.base64EncodedString(options: [])
      } catch {
        os_log(
          .debug,
          log: log,
          "Couldn't read receipt data with error: %s",
          error.localizedDescription
        )
      }
    }
    return receiptString
  }

  private func sendTransactions(_ transactions: [SKPaymentTransaction]) {
    let receiptString = getReceiptString()
    var skTransactions: [[String: Any?]] = []
    for transaction in transactions {
      if transaction.transactionIdentifier != nil {
        self.transactions.updateValue(transaction, forKey: transaction.transactionIdentifier!)
      }
      skTransactions.append([
        "productId": transaction.payment.productIdentifier,
        "transactionId": transaction.transactionIdentifier,
        "transactionDate": transaction.transactionDate?.timeIntervalSince1970,
        "status": transaction.transactionState.rawValue,
        "error": getTransactionError(transaction.error as? NSError),
        "applicationUserName": transaction.payment.applicationUsername,
        "originalIdentifier": transaction.original?.transactionIdentifier,
        "receiptData": receiptString,
      ])
    }
    emitTransactionsUpdated(skTransactions)
  }

  private func getTransactionError(_ error: NSError?) -> String? {
    if error == nil {
      return nil
    }
    if error!.domain == SKErrorDomain {
      switch error!.code {
      case SKError.clientInvalid.rawValue:
        return "Client is not allowed to issue the request"
      case SKError.paymentCancelled.rawValue:
        return "User cancelled the request"
      case SKError.paymentInvalid.rawValue:
        return "Purchase identifier was invalid"
      case SKError.paymentNotAllowed.rawValue:
        return "This device is not allowed to make the payment"
      case SKError.unknown.rawValue:
        return "Unknown error"
      default:
        return error!.localizedDescription
      }
    }
    return error!.localizedDescription
  }

  private func priceLocaleCurrencyCode(_ priceLocale: Locale) -> String {
    let numberFormatter = NumberFormatter()
    numberFormatter.locale = priceLocale
    return numberFormatter.currencyCode
  }

  private func productUnitToString(_ unit: SKProduct.PeriodUnit?) -> String? {
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

  private func productPaymentModeToString(_ mode: SKProductDiscount.PaymentMode?) -> String? {
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

  private func productDiscountTypeToString(_ type: SKProductDiscount.`Type`) -> String? {
    switch type {
    case .introductory:
      return "Introductory"
    case .subscription:
      return "Subscription"
    default:
      return nil
    }
  }
}
