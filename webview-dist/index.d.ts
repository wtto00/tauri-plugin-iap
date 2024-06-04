/**
 * Returns `true` if the payment platform is ready and available.
 */
export declare function canMakePayments(): Promise<boolean>;
/**
 * Returns the user's country.
 *
 * Returns the country code from SKStoreFrontWrapper.
 * @see https://developer.apple.com/documentation/storekit/skstorefront
 */
export declare function countryCode(): Promise<string | null>;
/**
 * Query product details for the given set of IDs.
 *
 * Identifiers in the underlying payment platform,
 * for example, [App Store Connect](https://appstoreconnect.apple.com/) for MacOS.
 */
export declare function startQueryProducts(identifiers: string[]): Promise<null>;
/**
 * Restore all previous purchases.
 *
 * @param applicationUserName The `applicationUserName` should match whatever was sent in the initial `requestPruchase`,
 * if anything. If no `applicationUserName` was specified in the initial `requestPruchase`, use null.
 */
export declare function restorePurchases(applicationUserName?: string): Promise<void>;
/**
 * Request a purchase.
 *
 * @param productIdentifier Identifier of the product of you want to purchase.
 * @param [quantity=1] The quantity of goods purchased
 * @param applicationUserName Used to mark `restorePurchases`.
 */
export declare function requestPruchase(productIdentifier: string, quantity?: number, applicationUserName?: string): Promise<void>;
/**
 * Must to call this method when a transaction's status is `TransactionStatus.purchased` or `TransactionStatus.restored`
 * @param transaction Transaction of purchased.
 */
export declare function completePurchase(transaction: Transaction): Promise<void>;
export declare enum TransactionStatus {
    /**
     * The purchase process is pending.
     *
     * You can update UI to let your users know the purchase is pending.
     */
    pending = 0,
    /**
     * The purchase is finished and successful.
     *
     * Update your UI to indicate the purchase is finished and deliver the product.
     */
    purchased = 1,
    /** Some error occurred in the purchase. The purchasing process if aborted. */
    failed = 2,
    /**
     * The purchase has been restored to the device.
     *
     * You should validate the purchase and if valid deliver the content. Once the
     * content has been delivered or if the receipt is invalid you should finish
     * the purchase by calling the `completePurchase` method.
     */
    restored = 3,
    /** The transaction is in the queue, but its final status is pending external action. */
    deferred = 4
}
/**
 * Transaction as reported by the device
 *
 * @see {@link Receipt}
 * @see {@link store.localTransactions}
 */
export interface Transaction {
    /**
     * Transaction identifier.
     * Only valid if state is SKPaymentTransactionStatePurchased or SKPaymentTransactionStateRestored.
     */
    transactionId?: String;
    /** The product identifier of the purchase. */
    productId: string;
    /**
     * The date when the transaction was added to the server queue.
     *
     * The value is `null` if `status` is not `TransactionStatus.purchased` or `TransactionStatus.restored`.
     */
    transactionDate?: String;
    /** The status that this transaction is currently on. */
    status: TransactionStatus;
    /** The error details when the [status] is [TransactionStatus.failed]. */
    error?: string;
    /** Application-specific user identifier. */
    applicationUserName?: string;
    /** The unique server-provided identifier of original transaction. */
    originalIdentifier?: string;
    /** The receipt for sending to the App Store for verification. */
    receiptData?: string;
}
/**
 * Listen to the callback result of the startQueryProducts method.
 */
export declare function listenTransactionUpdated(callback: (transactions: Transaction[]) => void): Promise<import("@tauri-apps/api/event").UnlistenFn>;
/** Unit for measuring durations */
export declare type IPeriodUnit = "Minute" | "Hour" | "Day" | "Week" | "Month" | "Year";
/** Mode of payment */
export declare enum PaymentMode {
    /** Used for subscriptions, pay at the beginning of each billing period */
    PAY_AS_YOU_GO = "PayAsYouGo",
    /** Pay the whole amount up front */
    UP_FRONT = "UpFront",
    /** Nothing to be paid */
    FREE_TRIAL = "FreeTrial"
}
export declare type DiscountType = "Introductory" | "Subscription";
/** Subscription discount offer */
export interface Discount {
    /** Discount identifier */
    id: string;
    /** Discount type */
    type: DiscountType;
    /** Localized price */
    price: string;
    /** Price in micro units */
    priceMicros: number;
    /** Number of periods */
    period: number;
    /** Subscription period unit */
    periodUnit: IPeriodUnit;
    /** Payment mode */
    paymentMode: PaymentMode;
}
/** Product as loaded from AppStore */
export interface Product {
    /** product id */
    id: string;
    /** localized title */
    title: string;
    /** localized description */
    description: string;
    /** localized price */
    price: number;
    /** Price in micro units */
    priceMicros: number;
    /** Currency used by this product */
    currency: string;
    /** AppStore country this product has been fetched for */
    countryCode?: string;
    /** The currency symbol for the locale, e.g. $ for US locale. */
    currencySymbol?: string;
    /** Number of period units in each billing cycle */
    billingPeriod?: number;
    /** Unit for the billing cycle */
    billingPeriodUnit?: IPeriodUnit;
    /** Localized price for introductory period */
    introPrice?: string;
    /** Introductory price in micro units */
    introPriceMicros?: number;
    /** Number of introductory price periods */
    introPricePeriod?: number;
    /** Duration of an introductory price period */
    introPricePeriodUnit?: IPeriodUnit;
    /** Payment mode for introductory price */
    introPricePaymentMode?: PaymentMode;
    /** Available discount offers */
    discounts?: Discount[];
    /** Group this product is member of */
    group?: string;
}
/**
 * Listen to the callback result of the startQueryProducts method.
 */
export declare function listenProductsUpdated(callback: (products: Product[]) => void): Promise<import("@tauri-apps/api/event").UnlistenFn>;
/**
 * Types of exceptional events.
 */
export declare enum ExceptionType {
    QueryProducts = "QueryProducts",
    RestorePurchases = "RestorePurchases",
    Purchase = "Purchase",
    TransactionUpdated = "TransactionUpdated",
    Unknown = "Unknown"
}
export interface Exception {
    type: ExceptionType;
    payload: {
        code: number;
        message: string;
    };
}
/**
 * Listening for callback of exceptional events
 */
export declare function listenException(callback: (err: Exception) => void): Promise<import("@tauri-apps/api/event").UnlistenFn>;
