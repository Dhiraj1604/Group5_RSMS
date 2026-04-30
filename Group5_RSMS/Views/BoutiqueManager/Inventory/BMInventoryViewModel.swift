//
//  BMInventoryViewModel.swift
//  Group5_RSMS
//
//  Boutique Manager — Inventory ViewModel.
//  Fetches low-stock alerts for the manager's own store
//  and manages the Endless Aisle transfer flow.
//

import Foundation
import Combine

@MainActor
final class BMInventoryViewModel: ObservableObject {

    // MARK: - Published State

    @Published private(set) var alerts: [LowStockAlert] = []
    @Published private(set) var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // Transfer flow
    @Published private(set) var transferSources: [TransferSource] = []
    @Published private(set) var isLoadingSources: Bool = false
    @Published private(set) var isTransferring: Bool = false
    @Published var transferSuccess: Bool = false
    @Published var transferError: String? = nil

    // Push flow (incoming) & Pull flow (outgoing)
    @Published private(set) var incomingRequests: [TransferRequest] = []
    @Published private(set) var isLoadingRequests: Bool = false
    
    @Published private(set) var myRequests: [TransferRequest] = []
    @Published private(set) var isLoadingMyRequests: Bool = false

    // Merchandising Insights
    @Published private(set) var soldProducts: [SoldProduct] = []
    @Published private(set) var fallbackItems: [InventoryProduct] = []
    @Published private(set) var weeklySalesData: [SalesTrendData] = []
    @Published private(set) var fastMovingProducts: [FastMovingProduct] = []
    @Published private(set) var isLoadingInsights: Bool = false
    @Published private(set) var isUpdatingFloorDisplay: Bool = false
    @Published private(set) var insightsError: String? = nil

    // MARK: - Computed

    var alertCount: Int { alerts.count }
    
    var criticalAlertsCount: Int {
        alerts.filter { $0.stockQuantity <= 2 }.count
    }
    
    var warningAlertsCount: Int {
        alerts.filter { $0.stockQuantity > 2 }.count
    }

    // MARK: - Load Low Stock (Single Store)

    func loadAlerts(forStore storeId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            self.alerts = try await LowStockService.shared.fetchLowStockAlerts(forStore: storeId)
        } catch {
            if error is CancellationError { return }
            self.errorMessage = "Failed to load inventory: \(error.localizedDescription)"
            print("❌ [BMInventoryVM] \(error)")
        }
        isLoading = false
    }

    // MARK: - Clear Alerts

    func clearAlerts() {
        self.alerts = []
        self.errorMessage = nil
    }

    // MARK: - Load Transfer Sources

    func loadTransferSources(forProduct productId: UUID, excluding storeId: UUID) async {
        isLoadingSources = true
        transferError = nil
        transferSources = []
        do {
            self.transferSources = try await LowStockService.shared.fetchHighStockStores(
                forProduct: productId,
                excluding: storeId
            )
        } catch {
            if error is CancellationError { return }
            self.transferError = "Failed to find transfer sources: \(error.localizedDescription)"
            print("❌ [BMInventoryVM] \(error)")
        }
        isLoadingSources = false
    }

    // MARK: - Execute Transfer

    func executeTransfer(
        productId: UUID,
        fromSource: TransferSource,
        toStoreId: UUID,
        toStoreName: String,
        quantity: Int,
        productName: String
    ) async {
        isTransferring = true
        transferError = nil
        transferSuccess = false
        do {
            try await LowStockService.shared.executeTransfer(
                productId: productId,
                fromStoreId: fromSource.storeId,
                toStoreId: toStoreId,
                quantity: quantity,
                productName: productName,
                fromStoreName: fromSource.storeName,
                toStoreName: toStoreName
            )
            transferSuccess = true
        } catch {
            if error is CancellationError { return }
            self.transferError = error.localizedDescription
            print("❌ [BMInventoryVM] Transfer failed: \(error)")
        }
        isTransferring = false
    }

    // MARK: - Request Transfer (Pull Workflow)

    func requestTransfer(
        productId: UUID,
        fromSource: TransferSource,
        toStoreId: UUID,
        quantity: Int
    ) async {
        isTransferring = true
        transferError = nil
        transferSuccess = false
        do {
            try await LowStockService.shared.createTransferRequest(
                productId: productId,
                requestingStoreId: toStoreId,
                fulfillingStoreId: fromSource.storeId,
                quantity: quantity
            )
            transferSuccess = true
        } catch {
            if error is CancellationError { return }
            self.transferError = error.localizedDescription
            print("❌ [BMInventoryVM] Request failed: \(error)")
        }
        isTransferring = false
    }

    // MARK: - Incoming Requests (Push Workflow)

    func loadIncomingRequests(forStore storeId: UUID) async {
        isLoadingRequests = true
        errorMessage = nil
        do {
            self.incomingRequests = try await LowStockService.shared.fetchIncomingRequests(forStore: storeId)
        } catch {
            if error is CancellationError { return }
            self.errorMessage = "Failed to load incoming requests: \(error.localizedDescription)"
            print("❌ [BMInventoryVM] \(error)")
        }
        isLoadingRequests = false
    }

    // MARK: - Outgoing Requests (My Requests)

    func loadMyRequests(forStore storeId: UUID) async {
        isLoadingMyRequests = true
        errorMessage = nil
        do {
            self.myRequests = try await LowStockService.shared.fetchMyRequests(forStore: storeId)
        } catch {
            if error is CancellationError { return }
            self.errorMessage = "Failed to load outbound requests: \(error.localizedDescription)"
            print("❌ [BMInventoryVM] \(error)")
        }
        isLoadingMyRequests = false
    }

    func fulfillRequest(
        _ request: TransferRequest,
        fulfilledQuantity: Int,
        currentStoreName: String
    ) async {
        isTransferring = true
        transferError = nil
        transferSuccess = false
        do {
            try await LowStockService.shared.executeTransfer(
                productId: request.productId,
                fromStoreId: request.fulfillingStoreId,
                toStoreId: request.requestingStoreId,
                quantity: fulfilledQuantity,
                productName: request.productName,
                fromStoreName: currentStoreName,
                toStoreName: request.requestingStoreName,
                requestId: request.id
            )
            transferSuccess = true
            
            // Remove the fulfilled request from the local list
            DispatchQueue.main.async {
                self.incomingRequests.removeAll { $0.id == request.id }
            }
            
            // Refresh stock alerts to reflect the change
            await loadAlerts(forStore: request.fulfillingStoreId)
        } catch {
            if error is CancellationError { return }
            self.transferError = error.localizedDescription
            print("❌ [BMInventoryVM] Fulfillment failed: \(error)")
        }
        isTransferring = false
    }

    // MARK: - Reject Transfer Request

    func rejectRequest(
        _ request: TransferRequest,
        currentStoreName: String
    ) async {
        isTransferring = true
        transferError = nil
        do {
            try await LowStockService.shared.rejectTransferRequest(
                request,
                rejectingStoreName: currentStoreName
            )
            // Instantly remove from incoming list so it disappears from this manager's view
            self.incomingRequests.removeAll { $0.id == request.id }
        } catch {
            if error is CancellationError { return }
            self.transferError = "Failed to reject request: \(error.localizedDescription)"
            print("❌ [BMInventoryVM] Reject failed: \(error)")
        }
        isTransferring = false
    }

    // MARK: - Merchandising Insights

    func loadMerchandisingInsights(forStore storeId: UUID) async {
        isLoadingInsights = true
        insightsError = nil
        
        do {
            async let sold = MerchandisingService.shared.fetchSoldProducts(forStore: storeId)
            async let fallback = MerchandisingService.shared.fetchFallbackItems(forStore: storeId)
            async let trend = MerchandisingService.shared.fetchWeeklySalesTrend(forStore: storeId)
            async let fastMovers = MerchandisingService.shared.fetchFastMovingProducts(forStore: storeId)
            
            let (soldResult, fallbackResult, trendResult, fastMoverResult) = try await (sold, fallback, trend, fastMovers)
            
            self.soldProducts = soldResult
            self.fallbackItems = fallbackResult
            self.weeklySalesData = trendResult
            self.fastMovingProducts = fastMoverResult
            
        } catch {
            if error is CancellationError { return }
            self.insightsError = "Failed to load insights: \(error.localizedDescription)"
            print("❌ [BMInventoryVM] Insights error: \(error)")
        }
        
        isLoadingInsights = false
    }
    
    func toggleFloorDisplay(for product: FastMovingProduct, storeId: UUID, quantity: Int) async {
        isUpdatingFloorDisplay = true
        insightsError = nil
        
        do {
            try await MerchandisingService.shared.updateFloorDisplay(
                productId: product.id,
                storeId: storeId,
                isOnFloor: !product.isOnFloor,
                quantity: quantity
            )
            await loadMerchandisingInsights(forStore: storeId)
        } catch {
            if error is CancellationError { return }
            self.insightsError = "Failed to update floor display: \(error.localizedDescription)"
            print("❌ [BMInventoryVM] Floor update error: \(error)")
        }
        
        isUpdatingFloorDisplay = false
    }

}
