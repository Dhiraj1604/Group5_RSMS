//
//  AppState.swift
//  Group5_RSMS
//
//  Merged AppState — combines Sprint 1 auth/store logic with full product management.
//  Manages authentication, role selection, store data, and product inventory.
//

import SwiftUI
import Observation
import Supabase

@Observable
@MainActor
class AppState {

    // MARK: - Auth State
    var isLoggedIn: Bool = false
    var requiresPasswordChange: Bool = false
    var userEmail: String = ""
    var managerAuthId: UUID? = nil
    var selectedRole: UserRole? = nil

    // MARK: - Navigation
    var hasSelectedRole: Bool { selectedRole != nil }

    // MARK: - Store State
    var stores: [Store] = []
    var isLoadingStores: Bool = false
    var storeError: String? = nil
    var selectedStore: Store? = nil
    var currentStoreID: UUID? = nil

    // MARK: - Product State
    var products: [ProductNew] = []
    var isLoadingProducts: Bool = false
    var productError: String? = nil

    // MARK: - Supabase Client
    private var client: SupabaseClient {
        SupabaseManager.shared.client
    }

    // MARK: - Auth Errors

    enum AuthError: Error, LocalizedError {
        case missingRole

        var errorDescription: String? {
            switch self {
            case .missingRole:
                return "Your account does not have an assigned role. Please contact your system administrator."
            }
        }
    }

    // MARK: - Auth Actions

    func login(email: String) async throws {
        userEmail = email
        managerAuthId = UUID(uuidString: "3bb61198-7f75-4d11-9e72-28c5afdb53a7")

        do {
            struct Profile: Codable {
                let role: String
            }

            let session = try await client.auth.session

            if let reqPass = session.user.userMetadata["requires_password_change"],
               reqPass == .bool(true) {
                self.requiresPasswordChange = true
            }

            let profile: Profile = try await client
                .from("profiles")
                .select("role")
                .eq("id", value: session.user.id)
                .single()
                .execute()
                .value

            if let fetchedRole = UserRole(rawValue: profile.role) {
                self.selectedRole = fetchedRole
            } else {
                print("Unknown role: \(profile.role)")
                throw AuthError.missingRole
            }
        } catch {
            print("Failed to fetch user role: \(error)")
            throw AuthError.missingRole
        }

        isLoggedIn = true
    }

    func selectRole(_ role: UserRole) {
        selectedRole = role
    }

    func goBackToRoleSelection() {
        selectedRole = nil
    }

    func logout() {
        isLoggedIn = false
        userEmail = ""
        selectedRole = nil
        stores = []
        Task {
            try? await client.auth.signOut()
        }
    }

    // MARK: - Store Actions

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

            if selectedRole == .boutiqueManager {
                self.currentStoreID = fetched.first(where: { $0.assignedManagerId == managerAuthId })?.id
                    ?? UUID(uuidString: "b3fd8cb6-341b-453e-9ed4-8915aa25245c")
            } else if self.currentStoreID == nil, let first = fetched.first {
                self.currentStoreID = first.id
            }
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ Key not found: \(key.stringValue) — \(context.debugDescription)")
            storeError = "Key not found: \(key.stringValue)"
        } catch let DecodingError.typeMismatch(type, context) {
            print("❌ Type mismatch: \(type) — \(context.debugDescription)")
            storeError = "Type mismatch: \(context.debugDescription)"
        } catch let DecodingError.valueNotFound(type, context) {
            print("❌ Value not found: \(type) — \(context.debugDescription)")
            storeError = "Value not found: \(context.debugDescription)"
        } catch {
            print("❌ fetchStores: \(error)")
            storeError = "Failed to load boutiques: \(error.localizedDescription)"
        }
        isLoadingStores = false
    }

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
            print("❌ addStore: \(error)")
            return false
        }
    }

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
            print("❌ deleteStore: \(error)")
        }
    }

    func deleteStores(at offsets: IndexSet) async {
        let toDelete = offsets.map { stores[$0] }
        for store in toDelete {
            await deleteStore(store)
        }
    }

    func toggleStoreActive(_ store: Store) async {
        guard let index = stores.firstIndex(where: { $0.id == store.id }) else { return }
        let beforeStore = stores[index]
        let newState = !(stores[index].isActive ?? false)
        stores[index].isActive = newState
        let updatedStore = stores[index]

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
            stores[index].isActive = !newState  // rollback
            storeError = "Failed to update store status: \(error.localizedDescription)"
            print("❌ toggleStoreActive: \(error)")
        }
    }

    func updateStoreDetails(_ store: Store) async {
        guard let index = stores.firstIndex(where: { $0.id == store.id }) else { return }
        let backup = stores[index]
        stores[index] = store
        do {
            try await client
                .from("stores")
                .update(store)
                .eq("id", value: store.id)
                .execute()
        } catch {
            stores[index] = backup
            storeError = "Failed to update boutique: \(error.localizedDescription)"
            print("❌ updateStoreDetails: \(error)")
        }
    }

    // MARK: - Product Actions

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
            print("❌ fetchProducts: \(error)")
            productError = "Failed to load products: \(error.localizedDescription)"
        }
        isLoadingProducts = false
    }

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
            print("❌ addProduct: \(error)")
            return false
        }
    }

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

            products[index] = updated

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
        } catch {
            productError = "Failed to update product: \(error.localizedDescription)"
            print("❌ updateProduct: \(error)")
        }
    }

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
            print("❌ deleteProduct: \(error)")
        }
    }

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
            print("❌ toggleProductActive: \(error)")
        }
    }

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
            print("❌ toggleProductGlobalListing: \(error)")
        }
    }

    // MARK: - Repair Actions

    func submitRepair(for product: ProductNew, issueDescription: String, repairCost: Double) async -> Bool {
        do {
            let payload = RepairInsertPayload(
                product_id: product.id,
                issueDescription: issueDescription,
                repairCost: repairCost
            )

            try await client
                .from("repair")
                .insert(payload)
                .execute()

            try await client
                .from("ProductNew")
                .update(["inRepair": true])
                .eq("id", value: product.id)
                .execute()

            if let index = products.firstIndex(where: { $0.id == product.id }) {
                products[index].inRepair = true
            }
            return true
        } catch {
            print("❌ submitRepair: \(error)")
            return false
        }
    }

    func resolveRepair(for product: ProductNew) async {
        do {
            try await client
                .from("repair")
                .update(["status": "Completed", "resolved_at": Date().ISO8601Format()])
                .eq("product_id", value: product.id)
                .eq("status", value: "Pending")
                .execute()

            try await client
                .from("ProductNew")
                .update(["inRepair": false])
                .eq("id", value: product.id)
                .execute()

            if let index = products.firstIndex(where: { $0.id == product.id }) {
                products[index].inRepair = false
            }
        } catch {
            print("❌ resolveRepair: \(error)")
        }
    }
}
