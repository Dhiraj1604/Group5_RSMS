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

    // MARK: - Computed

    var alertCount: Int { alerts.count }

    // MARK: - Load Low Stock (Single Store)

    func loadAlerts(forStore storeId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            self.alerts = try await LowStockService.shared.fetchLowStockAlerts(forStore: storeId)
        } catch {
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
        } catch {
            self.transferError = error.localizedDescription
            print("❌ [BMInventoryVM] Fulfillment failed: \(error)")
        }
        isTransferring = false
    }
}
