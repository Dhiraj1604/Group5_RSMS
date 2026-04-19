//  AppState.swift
//  Group5_RSMS
//
//  Sprint 1 — Central observable state for the entire application.

import SwiftUI
import Observation
import Supabase

@Observable
class AppState {

    // MARK: - Auth State
    var isLoggedIn: Bool = false
    var userEmail: String = ""
    var selectedRole: UserRole? = nil
    var currentStoreID: UUID? = nil

    var hasSelectedRole: Bool { selectedRole != nil }

    // MARK: - Store State
    var stores: [Store] = []
    var isLoadingStores: Bool = false
    var storeError: String? = nil

    // MARK: - Product State
    var products: [ProductNew] = []
    var isLoadingProducts: Bool = false
    var productError: String? = nil

    // MARK: - Supabase Client
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

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

    // MARK: - Store Actions (Supabase)

    @MainActor
    func fetchStores() async {
        isLoadingStores = true
        storeError = nil
        do {
            let fetched: [Store] = try await client
                .from("stores")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            self.stores = fetched
        } catch {
            self.storeError = "Failed to load boutiques: \(error.localizedDescription)"
            print("❌ [AppState] fetchStores: \(error)")
        }
        isLoadingStores = false
    }

    @MainActor
    @discardableResult
    func addStore(_ store: Store) async -> Bool {
        do {
            let saved: Store = try await client
                .from("stores")
                .insert(store)
                .select()
                .single()
                .execute()
                .value
            stores.insert(saved, at: 0)

            ActivityLogService.shared.log(
                userEmail: userEmail,
                action: .created,
                entity: .store,
                entityName: saved.name,
                entityId: saved.id.uuidString,
                details: "Boutique '\(saved.name)' (\(saved.code)) registered in \(saved.city).",
                before: nil as String?,
                after: saved
            )
            return true
        } catch {
            storeError = "Failed to register boutique: \(error.localizedDescription)"
            print("❌ [AppState] addStore: \(error)")
            return false
        }
    }

    @MainActor
    func deleteStore(_ store: Store) async {
        do {
            try await client
                .from("stores")
                .delete()
                .eq("id", value: store.id)
                .execute()
            stores.removeAll { $0.id == store.id }

            ActivityLogService.shared.log(
                userEmail: userEmail,
                action: .deleted,
                entity: .store,
                entityName: store.name,
                entityId: store.id.uuidString,
                details: "Boutique '\(store.name)' permanently deleted.",
                before: store,
                after: nil as String?
            )
        } catch {
            storeError = "Failed to delete boutique: \(error.localizedDescription)"
            print("❌ [AppState] deleteStore: \(error)")
        }
    }

    @MainActor
    func toggleStoreActive(_ store: Store) {
        guard let index = stores.firstIndex(where: { $0.id == store.id }) else { return }
        let newState = !stores[index].isActive
        let beforeStore = stores[index]
        stores[index].isActive = newState
        let updatedStore = stores[index]

        Task {
            do {
                try await client
                    .from("stores")
                    .update(["is_active": newState])
                    .eq("id", value: store.id)
                    .execute()

                ActivityLogService.shared.log(
                    userEmail: userEmail,
                    action: newState ? .activated : .deactivated,
                    entity: .store,
                    entityName: store.name,
                    entityId: store.id.uuidString,
                    details: "Boutique '\(store.name)' \(newState ? "activated" : "deactivated").",
                    before: beforeStore,
                    after: updatedStore
                )
            } catch {
                stores[index].isActive = !newState   // rollback
                storeError = "Failed to update store status: \(error.localizedDescription)"
                print("❌ [AppState] toggleStoreActive: \(error)")
            }
        }
    }

    // MARK: - Product Actions

    @MainActor
    func fetchProducts() async {
        isLoadingProducts = true
        productError = nil
        do {
            let fetched: [ProductNew] = try await client
                .from("ProductNew")
                .select()
                .order("created_at", ascending: false)
                .execute()
                .value
            self.products = fetched
        } catch {
            self.productError = "Failed to load products: \(error.localizedDescription)"
        }
        isLoadingProducts = false
    }

    @MainActor
    @discardableResult
    func addProduct(_ product: ProductNew) async -> Bool {
        do {
            let saved: ProductNew = try await client
                .from("ProductNew")
                .insert(product)
                .select()
                .single()
                .execute()
                .value
            products.insert(saved, at: 0)
            
            ActivityLogService.shared.log(
                userEmail: userEmail,
                action: .created,
                entity: .product,
                entityName: saved.name,
                entityId: saved.id.uuidString,
                details: "New product '\(saved.name)' added to inventory.",
                before: nil as String?,
                after: saved
            )
            return true
        } catch {
            productError = "Failed to add product: \(error.localizedDescription)"
            return false
        }
    }

    @MainActor
    func updateProduct(_ product: ProductNew) async {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        let beforeProduct = products[index]
        
        do {
            var updated = product
            updated.updatedAt = Date()
            
            try await client
                .from("ProductNew")
                .update(updated)
                .eq("id", value: product.id)
                .execute()
                
            ActivityLogService.shared.log(
                userEmail: userEmail,
                action: .updated,
                entity: .product,
                entityName: product.name,
                entityId: product.id.uuidString,
                details: "Updated details for \(product.sku)",
                before: beforeProduct,
                after: updated
            )
            
            products[index] = updated
        } catch {
            productError = "Failed to update product: \(error.localizedDescription)"
        }
    }

    @MainActor
    func deleteProduct(_ product: ProductNew) async {
        do {
            try await client
                .from("ProductNew")
                .delete()
                .eq("id", value: product.id)
                .execute()
            
            products.removeAll { $0.id == product.id }

            ActivityLogService.shared.log(
                userEmail: userEmail,
                action: .deleted,
                entity: .product,
                entityName: product.name,
                entityId: product.id.uuidString,
                details: "Product '\(product.name)' (SKU: \(product.sku)) permanently deleted.",
                before: product,
                after: nil as String?
            )
        } catch {
            productError = "Failed to delete product: \(error.localizedDescription)"
            print("❌ [AppState] deleteProduct: \(error)")
        }
    }

    @MainActor
    func toggleProductActive(_ product: ProductNew) async {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        let beforeProduct = products[index]
        let newState = !products[index].isActive
        
        var updatedProduct = products[index]
        updatedProduct.isActive = newState
        updatedProduct.updatedAt = Date()
        
        do {
            try await client
                .from("ProductNew")
                .update(updatedProduct)
                .eq("id", value: product.id)
                .execute()

            products[index] = updatedProduct

            ActivityLogService.shared.log(
                userEmail: userEmail,
                action: newState ? .activated : .deactivated,
                entity: .product,
                entityName: product.name,
                entityId: product.id.uuidString,
                details: "Product status changed to \(newState ? "Active" : "Inactive").",
                before: beforeProduct,
                after: updatedProduct
            )
        } catch {
            productError = "Failed to update status: \(error.localizedDescription)"
            print("❌ [AppState] toggleProductActive: \(error)")
        }
    }

    @MainActor
    func toggleProductGlobalListing(_ product: ProductNew) async {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        let beforeProduct = products[index]
        let newState = !products[index].isGloballyListed
        
        var updatedProduct = products[index]
        updatedProduct.isGloballyListed = newState
        updatedProduct.updatedAt = Date()

        do {
            try await client
                .from("ProductNew")
                .update(updatedProduct)
                .eq("id", value: product.id)
                .execute()

            products[index] = updatedProduct

            ActivityLogService.shared.log(
                userEmail: userEmail,
                action: .updated,
                entity: .product,
                entityName: product.name,
                entityId: product.id.uuidString,
                details: "Global listing visibility \(newState ? "Enabled" : "Disabled").",
                before: beforeProduct,
                after: updatedProduct
            )
        } catch {
            productError = "Failed to update listing: \(error.localizedDescription)"
            print("❌ [AppState] toggleProductGlobalListing: \(error)")
        }
    }
}
