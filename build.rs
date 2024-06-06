use swift_rs::SwiftLinker;

fn main() {
    // swift-rs has a minimum of macOS 10.13
    // Ensure the same minimum supported macOS version is specified as in your `Package.swift` file.
    SwiftLinker::new("10.15")
        .with_package("TauriIAP", "./swift-iap/")
        .link();

    // Other build steps
}
