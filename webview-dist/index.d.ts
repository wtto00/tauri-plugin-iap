import { type EventCallback } from '@tauri-apps/api/event';
/**
 * Returns `true` if the payment platform is ready and available.
 */
export declare function canMakePayments(): Promise<boolean>;
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
/**
 * Query product details for the given set of IDs.
 *
 * Identifiers in the underlying payment platform,
 * for example, [App Store Connect](https://appstoreconnect.apple.com/) for iOS/MacOS.
 */
export declare function queryProductDetails(identifiers: string[]): Promise<unknown>;
export declare function listenProductsUpdate(callback: EventCallback<object>): Promise<import("@tauri-apps/api/event").UnlistenFn>;
export declare type ExceptionType = "queryProductDetails";
export declare function listenException(callback: EventCallback<{
    type: ExceptionType;
    payload?: string;
}>): Promise<import("@tauri-apps/api/event").UnlistenFn>;
