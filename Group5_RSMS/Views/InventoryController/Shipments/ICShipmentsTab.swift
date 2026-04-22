//
//  ICShipmentsTab.swift
//  Group5_RSMS
//
//  Inventory Controller — Shipments Tab.
//  Displays inventory transfer actions across the company's boutiques.
//

import SwiftUI

struct ICShipmentsTab: View {
    @State private var shipments: [AuditLog] = []
    @State private var isLoading = false
    @State private var fetchError: String? = nil

    private let logService = AuditLogService()

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                if isLoading {
                    loadingState
                } else if let error = fetchError {
                    errorState(error)
                } else if shipments.isEmpty {
                    emptyState
                } else {
                    shipmentsList
                }
            }
            .navigationTitle("Shipments")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await loadShipments()
            }
            .refreshable {
                await loadShipments()
            }
        }
    }

    private func loadShipments() async {
        isLoading = true
        fetchError = nil
        do {
            let logs = try await logService.fetchLogs()
            // Filter logs directly based on the eventType string parsing or exact match
            self.shipments = logs.filter { $0.eventType == .inventoryTransfer }
        } catch {
            self.fetchError = error.localizedDescription
        }
        isLoading = false
    }

    private var shipmentsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 16) {
                ForEach(shipments) { log in
                    shipmentCard(for: log)
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
            .padding(.top, RSMSTheme.Spacing.md)
            .padding(.bottom, 40)
        }
    }

    private func shipmentCard(for log: AuditLog) -> some View {
        let fromStore = log.beforeData?["from_store"] ?? "Unknown Store"
        let toStore = log.afterData?["to_store"] ?? "Unknown Store"
        let quantity = log.afterData?["quantity_transferred"] ?? "N/A"
        let product = log.afterData?["product"] ?? log.entity

        return VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                        .frame(width: 50, height: 50)
                    Image(systemName: "box.truck.fill")
                        .font(.system(size: 20))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(product)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)

                    HStack(spacing: 4) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 10))
                        Text(fromStore)
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)

                    HStack(spacing: 4) {
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                        Text("To: \(toStore)")
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                }

                Spacer()

                // Quantity
                VStack(spacing: 2) {
                    Text(quantity)
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(RSMSTheme.Colors.success)
                    Text("Qty")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.success.opacity(0.7))
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
            }

            Divider()
                .background(RSMSTheme.Colors.borderLight)
                .padding(.vertical, RSMSTheme.Spacing.md)

            // Bottom section
            HStack {
                Text(log.formattedTimestamp)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 10))
                    Text("Processed")
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RSMSTheme.Colors.border)
                .cornerRadius(4)
            }
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(RSMSTheme.Colors.accentGold)
                .scaleEffect(1.5)
            Text("Loading shipments data...")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
        }
    }

    private func errorState(_ msg: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 32))
                .foregroundColor(RSMSTheme.Colors.error)
            Text("Error loading shipments")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)
            Text(msg)
                .font(.system(size: 14))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
            Button("Retry") {
                Task { await loadShipments() }
            }
            .buttonStyle(GoldButtonStyle())
            .padding(.top, 8)
        }
        .padding(32)
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.border.opacity(0.3))
                    .frame(width: 88, height: 88)
                Image(systemName: "shippingbox.circle.fill")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
            }
            VStack(spacing: 8) {
                Text("No Shipments Found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("There are no recent inter-store\ntransfers to display.")
                    .font(.system(size: 15))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
    }
}
