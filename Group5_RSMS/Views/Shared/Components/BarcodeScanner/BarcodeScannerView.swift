//
//  BarcodeScannerView.swift
//  Group5_RSMS
//
//  Views/Shared/Components/BarcodeScanner — Generic, Reusable Module
//  Camera overlay UI component. Purely presentational — business
//  logic is handled by the consumer via the `onScan` closure.
//

import SwiftUI
import VisionKit
import UIKit

/// A reusable barcode scanner view with a luxury dark-themed overlay.
///
/// Usage:
/// ```swift
/// BarcodeScannerView { scannedValue in
///     print("Scanned: \(scannedValue)")
/// }
/// ```
@available(iOS 16.0, *)
struct BarcodeScannerView: View {

    /// Closure called with the decoded barcode string.
    let onScan: (String) -> Void

    @StateObject private var viewModel = BarcodeScannerViewModel()
    @State private var isFlashOn = false

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if viewModel.isScannerAvailable && viewModel.cameraPermission == .authorized {
                // Live camera feed
                scannerLayer
            } else if !viewModel.isScannerAvailable {
                // Simulator / unsupported device fallback
                simulatorFallbackView
            } else if viewModel.cameraPermission == .denied {
                permissionDeniedView
            } else {
                // Loading / requesting permission
                loadingView
            }
        }
        .onAppear {
            viewModel.prepareScanner()
        }
    }

    // MARK: - Scanner Layer

    private var scannerLayer: some View {
        ZStack {
#if os(iOS) && !targetEnvironment(macCatalyst)
            DataScannerRepresentable(
                onScan: onScan,
                onError: { viewModel.handleScannerError($0) }
            )
            .ignoresSafeArea()
#endif

            // Scan overlay frame
            scanOverlay
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Barcode scanner")
        .accessibilityHint("Point the camera at a barcode, or use manual SKU entry from the Scan toolbar.")
    }

    // MARK: - Scan Overlay

    private var scanOverlay: some View {
        ZStack {
            // Viewfinder frame - Centered via ZStack
            ZStack {
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                    .stroke(RSMSTheme.Colors.accentGold, lineWidth: 2)
                    .frame(width: 280, height: 180)
                    .shadow(color: RSMSTheme.Colors.accentGold.opacity(0.3), radius: 12, x: 0, y: 0)

                // Animated scan line
                ScanLineView()
                    .frame(width: 260, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
            }

            // Instruction label - Positioned at bottom without affecting viewfinder center
            VStack {
                Spacer()
                Text("Align barcode within the frame")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.accentGoldLight)
                    .padding(.horizontal, RSMSTheme.Spacing.xl)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(RSMSTheme.Colors.backgroundDeep.opacity(0.85))
                            .overlay(
                                Capsule()
                                    .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.4), lineWidth: 0.5)
                            )
                    )
                    .padding(.bottom, 140) // Balanced position for one-handed operation
                    .accessibilityLabel("Align barcode within the frame")
            }
        }
    }

    // MARK: - Fallback Views

    private var simulatorFallbackView: some View {
        VStack(spacing: RSMSTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.backgroundElevated)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.5), lineWidth: 1)
                    )

                Image(systemName: "camera.fill")
                    .font(.system(size: 36))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }

            VStack(spacing: RSMSTheme.Spacing.md) {
                Text("Camera Not Available")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.accentGoldLight)

                Text("Camera is not supported on Simulator.\nPlease use a physical device.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.accentGoldDark)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.xl)
                .fill(RSMSTheme.Colors.backgroundDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.xl)
                        .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, RSMSTheme.Spacing.xxl)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: RSMSTheme.Spacing.xl) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.backgroundElevated)
                    .frame(width: 100, height: 100)
                    .overlay(
                        Circle()
                            .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.5), lineWidth: 1)
                    )

                Image(systemName: "lock.shield.fill")
                    .font(.system(size: 36))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }

            VStack(spacing: RSMSTheme.Spacing.md) {
                Text("Camera Access Required")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.accentGoldLight)

                Text("Please enable camera access in\nSettings to scan barcodes.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.accentGoldDark)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }

            Button {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            } label: {
                Text("Open Settings")
                    .font(.system(size: 15, weight: .semibold, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.backgroundPrimary)
                    .padding(.horizontal, RSMSTheme.Spacing.xxl)
                    .padding(.vertical, RSMSTheme.Spacing.md)
                    .background(
                        Capsule()
                            .fill(RSMSTheme.Colors.accentGold)
                    )
            }
            .accessibilityLabel("Open Settings")
            .accessibilityHint("Opens iOS Settings so you can enable camera access.")
        }
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.xl)
                .fill(RSMSTheme.Colors.backgroundDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.xl)
                        .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.3), lineWidth: 1)
                )
        )
        .padding(.horizontal, RSMSTheme.Spacing.xxl)
    }

    private var loadingView: some View {
        VStack(spacing: RSMSTheme.Spacing.xl) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: RSMSTheme.Colors.accentGold))
                .scaleEffect(1.2)

            Text("Preparing Scanner…")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(RSMSTheme.Colors.accentGoldDark)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Preparing scanner")
    }
}

// MARK: - Scan Line Animation

/// Animated horizontal line that sweeps vertically within the viewfinder.
private struct ScanLineView: View {
    @State private var offset: CGFloat = -60

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        RSMSTheme.Colors.accentGold.opacity(0),
                        RSMSTheme.Colors.accentGold.opacity(0.6),
                        RSMSTheme.Colors.accentGold.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .frame(height: 2)
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
                ) {
                    offset = 60
                }
            }
    }
}
