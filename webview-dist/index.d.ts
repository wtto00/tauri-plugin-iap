import { type EventCallback } from '@tauri-apps/api/event';
/**
 * Returns `true` if the payment platform is ready and available.
 */
export declare function canMakePayments(): Promise<boolean>;
/**
 * Query product details for the given set of IDs.
 *
 * Identifiers in the underlying payment platform,
 * for example, [App Store Connect](https://appstoreconnect.apple.com/) for MacOS.
 */
export declare function startQueryProducts(identifiers: string[]): Promise<unknown>;
/**
 * Restore all previous purchases.
 *
 * @param applicationUserName The `applicationUserName` should match whatever was sent in the initial `PurchaseParam`,
 * if anything. If no `applicationUserName` was specified in the initial `PurchaseParam`, use null.
 *
 * Restored purchases are delivered through the `purchaseStream` with a status of `PurchaseStatus.restored`.
 * You should listen for these purchases, validate their receipts,
 * deliver the content and mark the purchase complete by calling the `completePurchase` method for each purchase.
 *
 * This does not return consumed products. If you want to restore unused consumable products,
 * you need to persist consumable product information for your user on your own server.
 */
export declare function restorePurchases(applicationUserName?: string): Promise<void>;
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
    price: string;
    /** Price in micro units */
    priceMicros: number;
    /** Currency used by this product */
    currency: string;
    /** AppStore country this product has been fetched for */
    countryCode: string;
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
export declare function listenProductsUpdated(callback: EventCallback<Product[]>): Promise<import("@tauri-apps/api/event").UnlistenFn>;
/**
 * Types of exceptional events.
 */
export declare enum ExceptionType {
    QueryProducts = "QueryProducts"
}
/**
 * Listening for callback of exceptional events
 */
export declare function listenException(callback: EventCallback<{
    type: ExceptionType;
    payload: {
        code: number;
        message: string;
    };
}>): Promise<import("@tauri-apps/api/event").UnlistenFn>;
