# Tauri Plugin IAP

A plugin of In App Purchase for Tauri on MacOS.

## Installation

- Add dependencies in file `src-tauri/Cargo.toml`:

  ```yaml
  [target.'cfg(target_os = "macos")'.dependencies]
  tauri-plugin-iap = { git = "https://github.com/wtto00/tauri-plugin-iap", tag = "v0.0.1" }
  ```

- Add dependencies of front-end:

  ```shell
  pnpm add https://github.com/wtto00/tauri-plugin-iap.git
  # yarn add https://github.com/wtto00/tauri-plugin-iap.git
  # npm i --save https://github.com/wtto00/tauri-plugin-iap.git
  ```

- Enable plugins in `src-tauri/main.rs`

  ```rs
  fn main() {
    tauri::Builder::default()
        .setup(move |app| {
            // Add this line
            #[cfg(target_os="macos")]
            app.app_handle().plugin(tauri_plugin_iap::init())?;

            Ok(())
        })
        .run(tauri::generate_context!())
        .expect("error while running tauri application");
  }
  ```

## Prepare

1. This plugin requires a minimum MacOS version of 10.15 or higher, so you must configure it in `src-tauri/tauri.config.json`.

   ```json
   {
     "tauri": {
       "bundle": {
         "macOS": {
           "minimumSystemVersion": "10.15"
         }
       }
     }
   }
   ```

1. You can only test IAP in a signed app. Since `Tauri` cannot be signed in development environment, you'll need to sign it and upload it to `AppConnect` for testing, then install and test it from `TestFlight`. See details at: <https://github.com/tauri-apps/tauri/issues/7930>

   About uploading to `AppConnect`, see [Publish](#publish)

## Usage

```typescript
import {
  canMakePayments,
  initialize,
  startQueryProducts,
  TransactionStatus,
  finishTransaction,
  requestPruchase,
  restorePurchases,
  type Product,
  type Transaction,
  type Exception,
} from "tauri-plugin-iap-api";

// This maybe fetch from your own server api
const product_identifiers = ["product_id_1", "product_id_2"];

// The verified and available products are displayed in the interface.
let products_validated = [];

// TODO: Send receiptData to your own server api to validate the transaction is valid or not.
// You should cache verified receiptData or transactionId to avoid repeatedly verifying the same data. About caching transactionId, you can refer to https://stackoverflow.com/questions/45705069/ios-storekit-transaction-identifier-does-not-match-receipt
function validate(transaction: Transaction) {
  return true;
}

function onProductsUpdated(products: Product[]) {
  products_validated.push(...products);
}
async function onTransactionsUpdated(transactions: Transaction[]) {
  for await (const transaction of transactions) {
    if (transaction.status === TransactionStatus.pending) {
      // Just Show loading
      continue;
    }
    let msg = "";
    if (transaction.status === TransactionStatus.failed) {
      msg ||= transaction.error || "Something wrong.";
    } else if (
      transaction.status === TransactionStatus.purchased ||
      transaction.status === TransactionStatus.restored
    ) {
      const isValid = await validate();
      if (isValid) {
        // TODO: Distribute the verified purchased items to the user.
        msg ||= "Success";

        // if this is not called a transaction will keep being triggered automatically on app start
        finishTransaction(transaction.transactionId);
      }
    }
    if (msg) {
      // Just toast msg
    }
  }
}
function onRestoreCompleted() {
  // If user only purchases items that are not restorable, such as a non-renewing subscription or a consumable product.
  // In this situation, `onTransactionsUpdated` cannot be called back.
  // So you can inform the user that the restoration has been completed through this method.
}
function onException(err: Exception) {
  // Just toast some error message
}
if (await canMakePayments()) {
  const inited = await initialize({
    onProductsUpdated,
    onTransactionsUpdated,
    onRestoreCompleted,
    onException,
  });
  if (inited) {
    startQueryProducts(product_identifiers);
  }
}

// restore finished purchase
restorePurchases();

// request a purchase
requestPruchase(product_identifiers[0]);
```

## Api

### canMakePayments

if the payment platform is ready and available or not.

[Apple Document Link](https://developer.apple.com/documentation/storekit/appstore/3822277-canmakepayments)

```ts
const isAvailable = await canMakePayments();
```

### countryCode

The three-letter code that represents the country or region associated with the App Store storefront.

[Apple Document Link](https://developer.apple.com/documentation/storekit/storefront/3792000-countrycode)

```ts
const code = await countryCode();
```

### initialize

Initialize the plugin.

If the initialization is not successful, you cannot call the `startQueryProducts`, `restorePurchases`, `requestPurchase`, `finishTransaction` interfaces.

```ts
const inited = await initialize({
  onProductsUpdated: (products: Product[]) => {},
  onTransactionsUpdated: async (transactions: Transaction[]) => {},
  onRestoreCompleted: () => {},
  onException: (err: Exception) => {},
});
```

### startQueryProducts

Requests product data from the App Store.

[Apple Document Link](https://developer.apple.com/documentation/storekit/product/3851116-products)

```ts
const productIdentifiers = ["com.example.productA", "com.example.productB"];
void startQueryProducts(productIdentifiers);
```

The query result is returned in the `onProductsUpdated` callback in the `initialize` function. [Apple Document Link](https://developer.apple.com/documentation/storekit/skproductsrequestdelegate/1506070-productsrequest)

### restorePurchases

Asks the payment queue to restore previously completed purchases.

[Apple Document Link](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506123-restorecompletedtransactions)

```ts
void restorePurchases();
```

### requestPruchase

Request a purchase.

```ts
void requestPruchase("com.example.productA");
```

### finishTransaction

[Apple Document Link](https://developer.apple.com/documentation/storekit/skpaymentqueue/1506003-finishtransaction)

```ts
void finishTransaction("someTransactionId");
```

## Publish

Please replace the `COMPANY_NAME`, `TEAM_ID`, `APP_NAME`, `APP_IDENTIFIER` with your specific information.

1. Preparation

   - Ensure that the certificate `3rd Party Mac Developer Application: COMPANY_NAME (TEAM_ID)` and `3rd Party Mac Developer Installer: COMPANY_NAME (TEAM_ID)` is installed on the local machine.  
     You can see it in `Keychain Access` app.  
     Created in <https://developer.apple.com/account/resources/certificates/add>, and select `Mac App Distribution`, `Mac Installer Distribution` in `Software` section.
   - Make sure to download the correct provision profile file from AppConnect to `src-tauri/entitlements/Mac_App_Distribution.provisionprofile`.  
     Ceated in <https://developer.apple.com/account/resources/profiles/add>, and select `Mac App Store Connect` in `Distribution` section.
   - Ensure that the entitlements file has been created in `src-tauri/entitlements/APP_NAME.entitlements`.  
     Reference content is as follows:

     ```xml
     <?xml version="1.0" encoding="UTF-8"?>
     <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
     <plist version="1.0">
       <dict>
         <key>com.apple.security.app-sandbox</key>
         <true/>
         <key>com.apple.security.network.client</key>
         <true/>
         <key>com.apple.security.files.user-selected.read-write</key>
         <true/>
         <key>com.apple.application-identifier</key>
         <string>TEAM_ID.APP_IDENTIFIER</string>
         <key>com.apple.developer.team-identifier</key>
         <string>TEAM_ID</string>
       </dict>
     </plist>
     ```

     The list of entitlements can be found [here](https://developer.apple.com/library/archive/documentation/Miscellaneous/Reference/EntitlementKeyReference/Chapters/AboutEntitlements.html#//apple_ref/doc/uid/TP40011195-CH1-SW1). If you want to publish an app on the App Store, you need to ensure that it does not include unused entitlements.

2. Execute the following script

   ```shell
   unset APPLE_SIGNING_IDENTITY
   unset APPLE_CERTIFICATE
   sign_app="3rd Party Mac Developer Application: COMPANY_NAME (TEAM_ID)"
   sign_install="3rd Party Mac Developer Installer: COMPANY_NAME (TEAM_ID)"
   profile="src-tauri/entitlements/Mac_App_Distribution.provisionprofile"

   target="universal-apple-darwin"

   npx tauri build --target "${target}" --verbose
   # cargo tauri build --target "${target}" --verbose

   app_path="src-tauri/target/${target}/release/bundle/macos/APP_NAME.app"
   build_name="src-tauri/target/${target}/release/bundle/macos/APP_NAME.pkg"
   cp_dir="src-tauri/target/${target}/release/bundle/macos/APP_NAME.app/Contents/embedded.provisionprofile"
   entitlements="src-tauri/entitlements/APP_NAME.entitlements"

   cp "${profile}" "${cp_dir}"

   codesign --deep --force -s "${sign_app}" --entitlements ${entitlements} "${app_path}"

   productbuild --component "${app_path}" /Applications/ --sign "${sign_install}" "${build_name}"
   ```

3. Upload to AppConnect  
   Now you will find the file `src-tauri/target/${target}/release/bundle/macos/APP_NAME.pkg`. Upload this pkg file to `AppConnect` by `Transporter`.

4. Install from TestFlight

   After you upload to `AppConnect`, you can see the app you just uploaded on `TestFlight` a few minutes later, install it, and test it.

## Debug

You can see the debug message of this plugin by this command:

```shell
log stream --level debug --predicate 'subsystem == "tauri" && category == "plugin.apple.iap"'
```
