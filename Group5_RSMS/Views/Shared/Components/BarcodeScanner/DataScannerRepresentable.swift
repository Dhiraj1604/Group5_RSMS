//
//  DataScannerRepresentable.swift
//  Group5_RSMS
//
//  Views/Shared/Components/BarcodeScanner — Generic, Reusable Module
//  Bridges iOS 16+ DataScannerViewController into SwiftUI.
//

import SwiftUI
import VisionKit

#if os(iOS) && !targetEnvironment(macCatalyst)
/// A `UIViewControllerRepresentable` that wraps `DataScannerViewController`
/// for barcode scanning via the VisionKit framework.
///
/// - Note: Requires iOS 16+ and a physical device with camera support.
@available(iOS 16.0, *)
struct DataScannerRepresentable: UIViewControllerRepresentable {

    // MARK: - Properties

    /// Closure invoked when a barcode string is successfully recognized.
    let onScan: (String) -> Void

    /// Closure invoked if the scanner encounters an error.
    let onError: (Error) -> Void

    // MARK: - UIViewControllerRepresentable

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.barcode()],
            qualityLevel: .accurate,
            recognizesMultipleItems: false,
            isHighFrameRateTrackingEnabled: false,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ uiViewController: DataScannerViewController, context: Context) {
        // Start scanning if not already active
        if !uiViewController.isScanning {
            try? uiViewController.startScanning()
        }
    }

    static func dismantleUIViewController(_ uiViewController: DataScannerViewController, coordinator: Coordinator) {
        // Ensure camera session is fully released to prevent memory leaks
        uiViewController.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onScan: onScan, onError: onError)
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {

        let onScan: (String) -> Void
        let onError: (Error) -> Void

        /// Tracks the last scanned value to avoid duplicate callbacks.
        private var lastScannedValue: String?

        init(onScan: @escaping (String) -> Void, onError: @escaping (Error) -> Void) {
            self.onScan = onScan
            self.onError = onError
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            guard let item = addedItems.first else { return }

            switch item {
            case .barcode(let barcode):
                guard let value = barcode.payloadStringValue,
                      value != lastScannedValue else { return }
                lastScannedValue = value
                DispatchQueue.main.async { [weak self] in
                    self?.onScan(value)
                }
            default:
                break
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didRemove removedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            // Reset duplicate guard when items leave the viewport
            if allItems.isEmpty {
                lastScannedValue = nil
            }
        }

        func dataScanner(_ dataScanner: DataScannerViewController, becameUnavailableWithError error: DataScannerViewController.ScanningUnavailable) {
            DispatchQueue.main.async { [weak self] in
                self?.onError(error)
            }
        }
    }
}
#endif
