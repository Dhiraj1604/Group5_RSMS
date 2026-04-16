//
//  ICScanViewModel.swift
//  Group5_RSMS
//
//  Views/InventoryController/Scan — Role-Specific Implementation
//  Receives scanned SKU values and prepares them for Supabase
//  integration (stub). Updates published state for the UI card.
//  Now pulls active tax rule from TaxSettingsViewModel.shared.
//

import Foundation
import Combine
import PostgREST
import Supabase

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
    @Published private(set) var scanError: String?
    @Published private(set) var isSearching: Bool = false

    // MARK: - Types

    struct ScanRecord: Identifiable {
        let id = UUID()
        let sku: String
        let timestamp: Date
    }

    // MARK: - Private

    private var cancellables = Set<AnyCancellable>()

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

    // MARK: - Public API

    /// Processes a newly scanned barcode value.
    /// - Parameters:
    ///   - sku: The raw string extracted from the barcode.
    ///   - storeId: The ID of the currently active store from AppState.
    func didScanBarcode(_ sku: String, storeId: UUID?) {
        // Update published state
        scannedSKU = sku
        lastScanDate = Date()
        scanCount += 1
        scanError = nil

        // Append to session history
        let record = ScanRecord(sku: sku, timestamp: Date())
        scanHistory.insert(record, at: 0)

        print("📦 [InventoryController] Scanned SKU: \(sku) at store: \(storeId?.uuidString ?? "nil")")
        
        Task {
            await fetchProductAndInventory(sku: sku, storeId: storeId)
        }
    }
    
    private func fetchProductAndInventory(sku: String, storeId: UUID?) async {
        isSearching = true
        scanError = nil
        currentStock = nil
        
        do {
            // 1. Live Database Fetch for Product
            let product: Product = try await SupabaseManager.shared.client
                .from("products")
                .select()
                .eq("sku", value: sku)
                .eq("is_active", value: true) // Filter for only active products
                .single()
                .execute()
                .value
            
            self.currentProduct = product
            
            // 2. Load active tax rule
            let rule = TaxSettingsViewModel.shared.activeRule
                ?? TaxRule(name: "Default VAT - 20%", rate: 0.20, isInclusive: true)
            self.currentTaxRule = rule
            
            // 3. Process Breakdown
            self.currentBreakdown = PricingService.calculate(product: product, taxRule: rule)
            
            // 4. Fetch Inventory Stock if storeId is known
            guard let storeId = storeId else {
                self.scanError = "No active store selected. Cannot fetch inventory."
                isSearching = false
                return
            }
            
            // We use standard struct to map the response
            struct InventoryRecord: Decodable {
                let stock_quantity: Int
            }
            
            let inventoryResult = try await SupabaseManager.shared.client
                .from("inventory")
                .select("stock_quantity")
                .eq("product_id", value: product.id)
                .eq("store_id", value: storeId)
                .single()
                .execute()
            
            let decoder = JSONDecoder()
            let record = try decoder.decode(InventoryRecord.self, from: inventoryResult.data)
            
            self.currentStock = record.stock_quantity
            
        } catch {
            print("❌ [InventoryController] Failed to process scan: \(error)")
            self.scanError = "SKU \(sku) not found in master catalog."
            self.currentProduct = nil
            self.currentBreakdown = nil
            self.currentTaxRule = nil
            self.currentStock = nil
        }
        
        isSearching = false
    }
    
    /// Logs an inventory action to the audit rules and mutates the inventory.
    /// - Parameters:
    ///   - actionType: "restock" or "sale"
    ///   - storeId: The active store executing the action
    func logInventoryAction(actionType: String, storeId: UUID?) async -> Bool {
        guard let product = currentProduct, let storeId = storeId, let currentCount = currentStock else {
            self.scanError = "Missing product or store context to log action."
            return false
        }
        
        isSearching = true
        scanError = nil
        
        let newCount = actionType == "sale" ? max(0, currentCount - 1) : currentCount + 1
        let user = "Inventory Controller" // Should ideally come from Auth State
        
        do {
            // Update the inventory
            try await SupabaseManager.shared.client
                .from("inventory")
                .update(["stock_quantity": newCount])
                .eq("product_id", value: product.id)
                .eq("store_id", value: storeId)
                .execute()
                
            // Log the audit
            struct AuditPayload: Encodable {
                let action: String
                let event_type: String
                let user_name: String
                let entity: String
            }
            
            let audit = AuditPayload(
                action: "Inventory \(actionType.capitalized) - SKU: \(product.sku)",
                event_type: "inventory_\(actionType)",
                user_name: user,
                entity: "Inventory"
            )
            
            try await SupabaseManager.shared.client
                .from("audit_logs")
                .insert(audit)
                .execute()
                
            // Update local state
            self.currentStock = newCount
            isSearching = false
            return true
            
        } catch {
            print("❌ [InventoryController] Failed to log action: \(error)")
            self.scanError = "Database update failed: \(error.localizedDescription)"
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
        scanError = nil
    }
}
