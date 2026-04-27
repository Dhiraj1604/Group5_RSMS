//
//  ICScanViewModel.swift
//  Group5_RSMS
//
//  Views/InventoryController/Scan — Role-Specific Implementation
//  Receives scanned SKU values and prepares them for Supabase
//  integration (stub). Updates published state for the UI card.
//  Now pulls active tax rule from TaxSettingsViewModel.shared.
//814935
import Foundation
import Combine
import PostgREST
import Supabase
import UIKit
import SwiftUI
/// View model for the Inventory Controller's Scan tab.
/// Manages scanned SKU state and will later handle Supabase persistence.
@MainActor
final class ICScanViewModel: ObservableObject {

    // MARK: - Published State

    /// The most recently scanned SKU string.
    @Published private(set) var scannedSKU: String?

    /// Timestamp of the last successful scan.
    @Published private(set) var lastScanDate: Date?

    /// Total number of items scanned this session.
    @Published private(set) var scanCount: Int = 0

    /// History of scanned SKUs for the current session.
    @Published private(set) var scanHistory: [ScanRecord] = []

    // MARK: - Global Taxation Engine
    @Published private(set) var currentProduct: Product?
    @Published private(set) var currentTaxRule: TaxRule?
    @Published private(set) var currentBreakdown: PricingBreakdown?
    
    // MARK: - Inventory Management
    @Published private(set) var currentStock: Int?
    @Published private(set) var originalStock: Int? // Tracking for batch save
    @Published private(set) var scanError: String?
    @Published private(set) var successMessage: String?
    @Published private(set) var isSearching: Bool = false
    
    // MARK: - Real-time HUD
    @Published var showSuccessHUD: Bool = false
    @Published var showErrorHUD: Bool = false
    @Published private(set) var lastScannedName: String?

    // MARK: - Types

    struct ScanRecord: Identifiable {
        let id = UUID()
        let sku: String
        let timestamp: Date
    }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()
    private var lastProcessTime: [String: Date] = [:]

    // MARK: - Init

    init() {
        observeTaxRuleChanges()
    }

    // MARK: - Tax Rule Observation

    /// Listens for changes from TaxSettingsViewModel so the scanner
    /// always uses the current active rule.
    private func observeTaxRuleChanges() {
        NotificationCenter.default
            .publisher(for: .taxRuleDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] notification in
                guard let self else { return }
                if let newRule = notification.userInfo?["rule"] as? TaxRule {
                    self.currentTaxRule = newRule
                    print("🔄 [Scanner] Tax rule updated → \(newRule.name)")

                    // Re-calculate breakdown if a product is loaded
                    if let product = self.currentProduct {
                        self.currentBreakdown = PricingService.calculate(
                            product: product,
                            taxRule: newRule
                        )
                    }
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Haptics

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }

    private func triggerNotificationHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        UINotificationFeedbackGenerator().notificationOccurred(type)
    }

    /// Triggers an error HUD with haptics and auto-hides it after a delay.
    private func showTemporaryError(_ message: String) {
        self.scanError = message
        triggerNotificationHaptic(.error)
        withAnimation {
            showErrorHUD = true
        }
        
        // Auto-hide after 3 seconds
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            withAnimation {
                // Only hide if it's still showing the SAME error or if no new error has overwritten it
                if self.scanError == message {
                    self.showErrorHUD = false
                    self.scanError = nil
                }
            }
        }
    }

    // MARK: - Public API

    /// Entry point for barcode scans or manual SKU entries.
    func didScanBarcode(_ sku: String, storeId: UUID?) {
        Task {
            await processSKU(sku, storeId: storeId)
        }
    }

    /// Unified processing flow for both scan and manual input.
    /// Performs SKU validation, product lookup, store-specific inventory check, and stock increment.
    func processSKU(_ sku: String, storeId: UUID?) async {
        let cleanSKU = sku.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        guard !cleanSKU.isEmpty else {
            showTemporaryError("Invalid SKU")
            return
        }

        // Debounce: Prevent duplicate rapid scans (2 seconds)
        if let lastTime = lastProcessTime[cleanSKU], Date().timeIntervalSince(lastTime) < 2.0 {
            print("⏳ [Scanner] Debouncing rapid scan for SKU: \(cleanSKU)")
            return
        }
        lastProcessTime[cleanSKU] = Date()

        isSearching = true
        scanError = nil
        successMessage = nil
        showSuccessHUD = false
        showErrorHUD = false
        currentProduct = nil
        currentStock = nil
        
        // Update session history
        scannedSKU = cleanSKU
        lastScanDate = Date()
        scanCount += 1
        let record = ScanRecord(sku: cleanSKU, timestamp: Date())
        scanHistory.insert(record, at: 0)

        print("📦 [InventoryController] Processing SKU: \(cleanSKU) for Store: \(storeId?.uuidString ?? "nil")")

        do {
            // 1. Find the product in master catalog
            let productResult = try await SupabaseManager.shared.client
                .from("products")
                .select()
                .eq("sku", value: cleanSKU)
                .execute()
            
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            let products = try decoder.decode([Product].self, from: productResult.data)
            
            guard let foundProduct = products.first else {
                showTemporaryError("Product does not exist")
                isSearching = false
                return
            }
            
            self.currentProduct = foundProduct
            
            // Load active tax rule for UI breakdown
            let rule = TaxSettingsViewModel.shared.activeRule
                ?? TaxRule(name: "Default VAT - 20%", rate: 0.20, isInclusive: true)
            self.currentTaxRule = rule
            self.currentBreakdown = PricingService.calculate(product: foundProduct, taxRule: rule)
            self.currentBreakdown = PricingService.calculate(product: foundProduct, taxRule: rule)

            // 2. Validate current store context
            guard let storeId = storeId else {
                showTemporaryError("No active store assigned.")
                isSearching = false
                return
            }

            // 3. Check if product exists in this store's inventory (Strict Mode)
            struct InventoryRecord: Decodable {
                let stock_quantity: Int
            }

            let inventoryResult = try await SupabaseManager.shared.client
                .from("inventory")
                .select("stock_quantity")
                .eq("product_id", value: foundProduct.id)
                .eq("store_id", value: storeId)
                .execute()

            let inventoryRecords = try decoder.decode([InventoryRecord].self, from: inventoryResult.data)

            guard let record = inventoryRecords.first else {
                showTemporaryError("Product does not exist in this store")
                isSearching = false
                return
            }

            // 4. Increment stock quantity by 1 and update last_updated
            let newStock = record.stock_quantity + 1
            
            struct InventoryUpdate: Encodable {
                let stock_quantity: Int
                let last_updated: String
            }
            
            let updatePayload = InventoryUpdate(
                stock_quantity: newStock, 
                last_updated: Date().ISO8601Format()
            )
            
            try await SupabaseManager.shared.client
                .from("inventory")
                .update(updatePayload)
                .eq("product_id", value: foundProduct.id)
                .eq("store_id", value: storeId)
                .execute()

            // Update local state for success feedback
            self.currentStock = newStock
            self.originalStock = newStock // Reset original to the newly saved value
            self.lastScannedName = foundProduct.name
            self.successMessage = "Inventory updated successfully"
            
            // Real-time HUD & Haptics
            triggerNotificationHaptic(.success)
            withAnimation {
                showSuccessHUD = true
            }
            
            // Auto-hide HUD after 2 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation {
                    showSuccessHUD = false
                }
            }
            
            print("✅ [InventoryController] Successfully incremented stock for SKU: \(cleanSKU)")

        } catch {
            print("❌ [InventoryController] Processing failed: \(error)")
            showTemporaryError("System error: \(error.localizedDescription)")
        }
        
        isSearching = false
    }
    
    /// Updates the stock counter locally without hitting Supabase.
    func adjustStockLocal(actionType: String) {
        guard let current = currentStock else { return }
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            if actionType == "sale" {
                currentStock = max(0, current - 1)
            } else {
                currentStock = current + 1
            }
        }
        triggerHaptic(.light)
    }

    /// Persists all local adjustments to Supabase in one batch.
    func commitManualAdjustment(storeId: UUID?) async -> Bool {
        guard let product = currentProduct, let storeId = storeId, let finalCount = currentStock else {
            showTemporaryError("Missing product or store context.")
            return false
        }
        
        isSearching = true
        scanError = nil
        
        let user = "Inventory Controller"
        
        do {
            // 1. Update the inventory table with the FINAL count
            struct FinalUpdate: Encodable {
                let stock_quantity: Int
                let last_updated: String
            }
            
            let updatePayload = FinalUpdate(
                stock_quantity: finalCount,
                last_updated: Date().ISO8601Format()
            )
            
            try await SupabaseManager.shared.client
                .from("inventory")
                .update(updatePayload)
                .eq("product_id", value: product.id)
                .eq("store_id", value: storeId)
                .execute()
                
            // 2. Log a single batch audit entry
            let delta = finalCount - (originalStock ?? finalCount)
            let actionText = delta >= 0 ? "Adjustment (+ \(delta))" : "Adjustment (\(delta))"
            
            struct AuditPayload: Encodable {
                let action: String
                let event_type: String
                let user_name: String
                let entity: String
            }
            
            let audit = AuditPayload(
                action: "Inventory \(actionText) - SKU: \(product.sku)",
                event_type: "inventory_adjustment",
                user_name: user,
                entity: "Inventory"
            )
            
            try await SupabaseManager.shared.client
                .from("audit_logs")
                .insert(audit)
                .execute()
                
            // 3. Update state & Trigger HUD
            self.originalStock = finalCount
            self.lastScannedName = product.name
            
            withAnimation {
                showSuccessHUD = true
            }
            triggerNotificationHaptic(.success)
            
            // Auto-hide HUD after 2 seconds
            Task {
                try? await Task.sleep(nanoseconds: 2_000_000_000)
                withAnimation {
                    showSuccessHUD = false
                }
            }
            
            isSearching = false
            return true
            
        } catch {
            print("❌ [InventoryController] Failed to commit adjustment: \(error)")
            showTemporaryError("Database update failed: \(error.localizedDescription)")
            isSearching = false
            return false
        }
    }

    /// Clears the current scan result (resets the card).
    func clearScan() {
        scannedSKU = nil
        lastScanDate = nil
        currentProduct = nil
        currentTaxRule = nil
        currentBreakdown = nil
        currentStock = nil
        scanError = nil
        successMessage = nil
    }

    /// Resets the entire session history.
    func resetSession() {
        scannedSKU = nil
        lastScanDate = nil
        scanCount = 0
        scanHistory.removeAll()
        currentProduct = nil
        currentTaxRule = nil
        currentBreakdown = nil
        currentStock = nil
        originalStock = nil
        scanError = nil
        successMessage = nil
    }
}
