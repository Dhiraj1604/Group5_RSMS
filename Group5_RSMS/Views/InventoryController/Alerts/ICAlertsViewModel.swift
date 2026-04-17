//
//  ICAlertsViewModel.swift
//  Group5_RSMS
//
//  Inventory Controller — Alerts ViewModel.
//  Fetches all low-stock alerts across every store.
//

import Foundation
import Combine

@MainActor
final class ICAlertsViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var alerts: [LowStockAlert] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var searchText: String = ""

    // MARK: - Computed

    var filteredAlerts: [LowStockAlert] {
        guard !searchText.isEmpty else { return alerts }
        let q = searchText.lowercased()
        return alerts.filter {
            $0.productName.lowercased().contains(q) ||
            $0.productSku.lowercased().contains(q) ||
            $0.storeName.lowercased().contains(q) ||
            $0.storeCity.lowercased().contains(q)
        }
    }

    var isEmpty: Bool { filteredAlerts.isEmpty }

    var totalAlertCount: Int { alerts.count }

    var criticalCount: Int { alerts.filter { $0.stockQuantity <= 1 }.count }

    // MARK: - Load

    func loadAlerts() async {
        isLoading = true
        errorMessage = nil
        do {
            self.alerts = try await LowStockService.shared.fetchAllLowStockAlerts()
        } catch {
            self.errorMessage = "Failed to load alerts: \(error.localizedDescription)"
            print("❌ [ICAlertsVM] \(error)")
        }
        isLoading = false
    }
}
