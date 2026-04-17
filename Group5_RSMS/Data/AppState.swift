//
//  AppState.swift
//  Group5_RSMS
//
//  Sprint 1 — Central observable state for the entire application.
//  Manages authentication, role selection, and store data.
//

import SwiftUI
import Observation
import Supabase
@Observable
class AppState {
    // MARK: - Auth State
    var isLoggedIn: Bool = false
    var userEmail: String = ""
    var selectedRole: UserRole? = nil

    // MARK: - Navigation
    var hasSelectedRole: Bool {
        selectedRole != nil
    }

    // MARK: - Store Data
    var stores: [Store] = []
    var storeError: String? = nil
    var isLoadingStores: Bool = false
    var currentStoreID: UUID? = nil

    // MARK: - Product Data
    var products: [InventoryProduct] = []
    var productError: String? = nil
    var isLoadingProducts: Bool = false

    // MARK: - Auth Actions
    func login(email: String) {
        userEmail = email
        isLoggedIn = true
    }

    func selectRole(_ role: UserRole) {
        selectedRole = role
    }

    func logout() {
        isLoggedIn = false
        userEmail = ""
        selectedRole = nil
    }

    func goBackToRoleSelection() {
        selectedRole = nil
    }

    // MARK: - Supabase Store Actions

    @MainActor
    func fetchStores() async {
        isLoadingStores = true
        storeError = nil
        do {
            let fetchedStores: [Store] = try await SupabaseManager.shared.client
                .from("stores")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            self.stores = fetchedStores
            
            // Set current store context for Scanner operations
            if self.currentStoreID == nil, let first = fetchedStores.first {
                self.currentStoreID = first.id
            }
        } catch {
            print("❌ Failed to fetch stores: \(error)")
            self.storeError = "Failed to load stores: \(error.localizedDescription)"
        }
        isLoadingStores = false
    }

    @MainActor
    func addStore(_ store: Store) async -> Bool {
        storeError = nil
        do {
            let insertedStore: Store = try await SupabaseManager.shared.client
                .from("stores")
                .insert(store.insertPayload)
                .select()
                .single()
                .execute()
                .value
            
            // Insert at the top of the local list
            self.stores.insert(insertedStore, at: 0)
            return true
        } catch {
            print("❌ Failed to insert store: \(error)")
            self.storeError = "Failed to register boutique: \(error.localizedDescription)"
            return false
        }
    }

    @MainActor
    func deleteStore(_ store: Store) async {
        storeError = nil
        do {
            try await SupabaseManager.shared.client
                .from("stores")
                .delete()
                .eq("id", value: store.id)
                .execute()
            
            self.stores.removeAll { $0.id == store.id }
        } catch {
            print("❌ Failed to delete store: \(error)")
            self.storeError = "Failed to delete store: \(error.localizedDescription)"
        }
    }

    // Toggle active remains an in-memory operation for now since isActive isn't in DB Schema
    func toggleStoreActive(_ store: Store) {
        if let index = stores.firstIndex(where: { $0.id == store.id }) {
            stores[index].isActive.toggle()
        }
    }

    @MainActor
    func fetchProducts() async {
        isLoadingProducts = true
        productError = nil
        do {
            let fetched: [InventoryProduct] = try await SupabaseManager.shared.client
                .from("products")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            self.products = fetched
        } catch {
            print("❌ Failed to fetch products: \(error)")
            self.productError = "Failed to load products: \(error.localizedDescription)"
        }
        isLoadingProducts = false
    }

    @MainActor
    func submitRepair(for product: InventoryProduct, issueDescription: String, repairCost: Double) async -> Bool {
        do {
            // 1. Insert into repairs table
            let payload = RepairInsertPayload(
                product_id: product.id,
                issueDescription: issueDescription,
                repairCost: repairCost
            )
            
            try await SupabaseManager.shared.client
                .from("repair")
                .insert(payload)
                .execute()
            
            // 2. Update product status
            try await SupabaseManager.shared.client
                .from("products")
                .update(["inRepair": true])
                .eq("id", value: product.id)
                .execute()
                
            // Update local state
            if let index = products.firstIndex(where: { $0.id == product.id }) {
                products[index] = InventoryProduct(
                    id: product.id,
                    sku: product.sku,
                    name: product.name,
                    description: product.description,
                    base_Price: product.base_Price,
                    category_id: product.category_id,
                    image_Url: product.image_Url,
                    created_at: product.created_at,
                    inRepair: true
                )
            }
            return true
        } catch {
            print("❌ Failed to submit repair: \(error)")
            return false
        }
    }

    @MainActor
    func resolveRepair(for product: InventoryProduct) async {
        do {
            // 1. Update repairs table (mark as resolved)
            // Assuming there's an active repair for this product we can resolve. Note: this might affect all active repairs for this product.
            try await SupabaseManager.shared.client
                .from("repair")
                .update(["status": "Completed", "resolved_at": Date().ISO8601Format()])
                .eq("product_id", value: product.id)
                .eq("status", value: "Pending") // Only resolve pending ones
                .execute()
                
            // 2. Update product status
            try await SupabaseManager.shared.client
                .from("products")
                .update(["inRepair": false])
                .eq("id", value: product.id)
                .execute()

            // Update local state
            if let index = products.firstIndex(where: { $0.id == product.id }) {
                products[index] = InventoryProduct(
                    id: product.id,
                    sku: product.sku,
                    name: product.name,
                    description: product.description,
                    base_Price: product.base_Price,
                    category_id: product.category_id,
                    image_Url: product.image_Url,
                    created_at: product.created_at,
                    inRepair: false
                )
            }
        } catch {
            print("❌ Failed to resolve repair: \(error)")
        }
    }
}
