import { invoke } from '@tauri-apps/api/tauri'
import { type EventCallback, listen } from '@tauri-apps/api/event'

/**
 * Returns `true` if the payment platform is ready and available.
 */
export async function canMakePayments() {
  return await invoke<boolean>('plugin:iap|can_make_payments')
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

/** 
 * Query product details for the given set of IDs.
 * 
 * Identifiers in the underlying payment platform, 
 * for example, [App Store Connect](https://appstoreconnect.apple.com/) for iOS/MacOS.
 */
export async function queryProductDetails(identifiers: string[]) {
  return await invoke('plugin:iap|query_product_details', { identifiers })
}

export async function listenProductsUpdate(callback: EventCallback<object>) {
  return await listen('products-update', callback)
}

export type ExceptionType = "queryProductDetails"
export async function listenException(callback: EventCallback<{ type: ExceptionType, payload?: string }>) {
  return await listen('exception', callback)
}