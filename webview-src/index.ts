import { invoke } from '@tauri-apps/api/tauri'
import { type EventCallback, listen } from '@tauri-apps/api/event'

/**
 * Returns `true` if the payment platform is ready and available.
 */
export async function canMakePayments() {
  return await invoke<boolean>('plugin:iap|can_make_payments')
}

/** 
 * Query product details for the given set of IDs.
 * 
 * Identifiers in the underlying payment platform, 
 * for example, [App Store Connect](https://appstoreconnect.apple.com/) for MacOS.
 */
export async function startQueryProducts(identifiers: string[]) {
  return await invoke('plugin:iap|query_products', { identifiers })
}

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
export async function restorePurchases(applicationUserName?: string) {
  await invoke('plugin:iap|restore_purchases')
}

/** Unit for measuring durations */
export type IPeriodUnit = "Minute" | "Hour" | "Day" | "Week" | "Month" | "Year";
/** Mode of payment */
export enum PaymentMode {
  /** Used for subscriptions, pay at the beginning of each billing period */
  PAY_AS_YOU_GO = "PayAsYouGo",
  /** Pay the whole amount up front */
  UP_FRONT = "UpFront",
  /** Nothing to be paid */
  FREE_TRIAL = "FreeTrial"
}
export type DiscountType = "Introductory" | "Subscription";
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
export async function listenProductsUpdated(callback: EventCallback<Product[]>) {
  return await listen('plugin:iap_products-updated', callback)
}

/**
 * Types of exceptional events.
 */
export enum ExceptionType {
  QueryProducts = "QueryProducts",
}
/**
 * Listening for callback of exceptional events
 */
export async function listenException(callback: EventCallback<{ type: ExceptionType, payload: { code: number, message: string } }>) {
  return await listen('plugin:iap_exception', callback)
}