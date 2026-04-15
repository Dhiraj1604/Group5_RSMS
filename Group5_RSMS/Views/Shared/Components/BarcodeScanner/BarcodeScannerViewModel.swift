//
//  BarcodeScannerViewModel.swift
//  Group5_RSMS
//
//  Views/Shared/Components/BarcodeScanner — Generic, Reusable Module
//  Manages camera permissions and device capability checks.
//

import SwiftUI
import VisionKit
import AVFoundation
import Combine
/// View model responsible for verifying device scanning capabilities
/// and managing camera authorization state.
@available(iOS 16.0, *)
@MainActor
final class BarcodeScannerViewModel: ObservableObject {

    // MARK: - Published State

    /// Whether the current device supports DataScanner (camera + on-device ML).
    @Published private(set) var isScannerAvailable: Bool = false

    /// Current camera authorization status.
    @Published private(set) var cameraPermission: CameraPermission = .undetermined

    /// Human-readable error message for UI display.
    @Published var errorMessage: String?

    // MARK: - Types

    enum CameraPermission: Equatable {
        case undetermined
        case authorized
        case denied
    }

    // MARK: - Initialization

    init() {
        checkScannerSupport()
    }

    // MARK: - Public API

    /// Checks device support and requests camera access if needed.
    func prepareScanner() {
        checkScannerSupport()

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            cameraPermission = .authorized
        case .notDetermined:
            requestCameraAccess()
        case .denied, .restricted:
            cameraPermission = .denied
            errorMessage = "Camera access is required for barcode scanning. Please enable it in Settings."
        @unknown default:
            cameraPermission = .denied
            errorMessage = "Unable to determine camera permission status."
        }
    }

    /// Handles errors surfaced by the `DataScannerRepresentable`.
    func handleScannerError(_ error: Error) {
        errorMessage = "Scanner error: \(error.localizedDescription)"
    }

    // MARK: - Private

    private func checkScannerSupport() {
#if os(iOS) && !targetEnvironment(macCatalyst)
        isScannerAvailable = DataScannerViewController.isSupported && DataScannerViewController.isAvailable
#else
        isScannerAvailable = false
#endif
    }

    private func requestCameraAccess() {
        Task {
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            cameraPermission = granted ? .authorized : .denied
            if !granted {
                errorMessage = "Camera access was denied. Please enable it in Settings to scan barcodes."
            }
        }
    }
}
