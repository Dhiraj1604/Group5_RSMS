//
//  AppState.swift
//  Group5_RSMS
//
//  Merged AppState — Sprint 1 auth/store/product management.
//  Task #8 (Zeeshan): sets ActivityLogService.shared.currentUserEmail on login
//  so every service (TaxSettingsViewModel, OfferService, etc.) can log without
//  needing the email passed through every call site.
//

import SwiftUI
import Observation
#if canImport(Supabase)
import Supabase
#endif

@Observable
@MainActor
class AppState {

    // MARK: - Auth State
    var isLoggedIn: Bool = false
    var requiresPasswordChange: Bool = false
    var userEmail: String = ""
    var managerAuthId: UUID? = nil
    var selectedRole: UserRole? = nil
    /// The store ID assigned to the user profile in Supabase.
    var assignedStoreId: UUID? = nil

    // MARK: - Store State
    var stores: [Store] = []
    var isLoadingStores: Bool = false
    var storeError: String? = nil
    var selectedStore: Store? = nil
    var currentStoreID: UUID? = nil

    // MARK: - Product State
    var products: [Product] = []
    var isLoadingProducts: Bool = false
    var productError: String? = nil
    var totalInventoryCount: Int = 0

    // MARK: - Navigation
    var hasSelectedRole: Bool { selectedRole != nil }

    // MARK: - Private
    private let sync     = SupabaseSyncManager.shared
    private let auditLog = ActivityLogService.shared

    // MARK: - Auth Errors
    enum AuthError: Error, LocalizedError {
        case missingRole
        var errorDescription: String? {
            "Your account does not have an assigned role. Please contact your system administrator."
        }
    }

    // MARK: - Auth Actions

    func login(email: String) async throws {
        userEmail = email
        self.requiresPasswordChange = false

        // ── Task #8: make email available to all services immediately ──
        ActivityLogService.shared.currentUserEmail = email

        #if canImport(Supabase)
        do {
//             struct Profile: Codable { let role: String }
            struct Profile: Codable {
                let role: String
                let store_id: UUID?
                let requires_password_setup: Bool?
            }
            let session = try await SupabaseManager.shared.client.auth.session
            self.managerAuthId = session.user.id

            if let reqPass = session.user.userMetadata["requires_password_change"],
               reqPass == .bool(true) {
                self.requiresPasswordChange = true
            }

            let profile: Profile = try await SupabaseManager.shared.client
                .from("profiles")
                .select("role, store_id, requires_password_setup")
                .eq("id", value: session.user.id)
                .single()
                .execute()
                .value

            if let reqPass = profile.requires_password_setup, reqPass == true {
                 self.requiresPasswordChange = true
            }
            
            if let fetchedRole = UserRole(rawValue: profile.role) {
                self.selectedRole = fetchedRole
                self.assignedStoreId = profile.store_id
                
                // Directly map the employee's specific store id from their profile!
                if let assignedStore = profile.store_id {
                    self.currentStoreID = assignedStore
                }
            } else {
                throw AuthError.missingRole
            }
        } catch {
            print("Failed to fetch user role: \(error)")
            throw AuthError.missingRole
        }
        #endif

        isLoggedIn = true

        // ── Task #8: log the login event ──────────────────────────────
        let roleLabel = selectedRole?.rawValue ?? "Unknown"
        auditLog.log(
            action: .loggedIn,
            entity: .user,
            entityName: email,
            entityId: email,
            details: "User '\(email)' logged in with role: \(roleLabel).",
            after: ["email": email, "role": roleLabel]
        )
    }

    func selectRole(_ role: UserRole) {
        selectedRole = role
    }

    func signOut() {
        isLoggedIn = false
        selectedRole = nil
        stores = []
        userEmail = ""
        requiresPasswordChange = false
        ActivityLogService.shared.currentUserEmail = ""

        #if canImport(Supabase)
        Task { try? await SupabaseManager.shared.client.auth.signOut() }
        #endif
    }

    // MARK: - User Audit helper (called by UserManagementViewModel when a manager creates staff)
    /// Call this after successfully inserting a user into Supabase `profiles`.
    func logUserCreation(createdEmail: String, assignedRole: String) {
        auditLog.log(
            action: .created,
            entity: .user,
            entityName: createdEmail,
            entityId: createdEmail,
            details: "User '\(createdEmail)' created with role '\(assignedRole)' by \(userEmail).",
            after: ["email": createdEmail, "role": assignedRole, "created_by": userEmail]
        )
    }

    /// Call this after a role change in Supabase `profiles`.
    func logRoleChange(targetEmail: String, oldRole: String, newRole: String) {
        auditLog.log(
            action: .roleAssigned,
            entity: .user,
            entityName: targetEmail,
            entityId: targetEmail,
            details: "Role changed from '\(oldRole)' to '\(newRole)' for '\(targetEmail)' by \(userEmail).",
            before: ["email": targetEmail, "role": oldRole],
            after:  ["email": targetEmail, "role": newRole]
        )
    }

    // MARK: - Store Actions

    func loadStores() async {
        isLoadingStores = true
        storeError = nil
        do {
            let fetchedStores = try await sync.fetchStores()
            self.stores = fetchedStores
            // Priority context logic:
            if let assigned = assignedStoreId {
                 // 1. Prioritize store explicitly assigned in profile
                self.currentStoreID = assigned
            } else if self.currentStoreID == nil && selectedRole == .boutiqueManager {
                 // 2. Fallback to manager field (legacy mapping)
                self.currentStoreID = fetchedStores.first(where: { $0.assignedManagerId == managerAuthId })?.id
                    // ✅ Fallback to Dior New York Fifth Avenue ID from your screenshot
                    ?? UUID(uuidString: "8232958a-d93e-44d5-bfc4-68b7604f7736")
            } else if self.currentStoreID == nil, let first = fetchedStores.first {
                // 3. Fallback to first available store (for Admins or unassigned users)
                self.currentStoreID = first.id
            }
        } catch let DecodingError.keyNotFound(key, context) {
            print("Key not found: \(key.stringValue) — \(context.debugDescription)")
            storeError = "Key not found: \(key.stringValue) — \(context.debugDescription)"
        } catch let DecodingError.typeMismatch(type, context) {
            print("Type mismatch: \(type) — \(context.debugDescription)")
            storeError = "Type mismatch: \(context.debugDescription)"
        } catch let DecodingError.valueNotFound(type, context) {
            print("Value not found: \(type) — \(context.debugDescription)")
            storeError = "Value not found: \(context.debugDescription)"
        } catch {
            print("Other error: \(error)")
            storeError = error.localizedDescription

        }
        isLoadingStores = false
    }

    func addStore(_ store: Store) async {
        do {
            try await sync.createStore(store)
            stores.append(store)
            auditLog.log(
                action: .created, entity: .store,
                entityName: store.name, entityId: store.id.uuidString,
                details: "Store created in \(store.city), \(store.country)",
                after: store
            )
        } catch { storeError = error.localizedDescription }
    }

    func deleteStore(_ store: Store) async {
        do {
            try await sync.deleteStore(id: store.id)
            stores.removeAll { $0.id == store.id }
            auditLog.log(
                action: .deleted, entity: .store,
                entityName: store.name, entityId: store.id.uuidString,
                details: "Store deleted",
                before: store
            )
        } catch { storeError = error.localizedDescription }
    }

    func deleteStores(at offsets: IndexSet) async {
        let toDelete = offsets.map { stores[$0] }
        for store in toDelete { await deleteStore(store) }
    }

    func toggleStoreActive(_ store: Store) async {
        guard let index = stores.firstIndex(where: { $0.id == store.id }) else { return }
        let currentActive = stores[index].isActive ?? false
        stores[index].isActive = !currentActive
        let updated = stores[index]
        do {
            try await sync.updateStore(updated)
            auditLog.log(
                action: !currentActive ? .activated : .deactivated, entity: .store,
                entityName: store.name, entityId: store.id.uuidString,
                details: "Store \(!currentActive ? "activated" : "deactivated")"
            )
        } catch {
            stores[index].isActive = currentActive
            storeError = error.localizedDescription
        }
    }

    func updateStoreDetails(_ store: Store) async {
        guard let index = stores.firstIndex(where: { $0.id == store.id }) else { return }
        let backup = stores[index]
        stores[index] = store
        do {
            try await sync.updateStore(store)
            auditLog.log(
                action: .updated, entity: .store,
                entityName: store.name, entityId: store.id.uuidString,
                details: "Store details updated",
                before: backup, after: store
            )
        } catch {
            stores[index] = backup
            storeError = error.localizedDescription
        }
    }

    // MARK: - Product Actions

    func fetchProducts() async {
        guard !isLoadingProducts else { return }
        isLoadingProducts = true
        productError = nil
        do {
            let fetched: [Product] = try await SupabaseManager.shared.client
                .from("products").select().order("created_at", ascending: false).execute().value
            self.products = fetched
        } catch {
            self.productError = "Failed to load products: \(error.localizedDescription)"
        }
        isLoadingProducts = false
    }

    func addProduct(_ product: Product) async -> Bool {
        do {
            try await SupabaseManager.shared.client.from("products").insert(product).execute()
            products.insert(product, at: 0)
            auditLog.log(
                action: .created, entity: .product,
                entityName: product.name, entityId: product.id.uuidString,
                details: "Product created (SKU: \(product.sku))",
                after: product
            )
            return true
        } catch {
            productError = "Failed to add product: \(error.localizedDescription)"
            return false
        }
    }

    func updateProduct(_ product: Product) async {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        let backup = products[index]
        products[index] = product
        do {
            try await SupabaseManager.shared.client
                .from("products").update(product).eq("id", value: product.id).execute()
            auditLog.log(
                action: .updated, entity: .product,
                entityName: product.name, entityId: product.id.uuidString,
                details: "Product updated (SKU: \(product.sku))",
                before: backup, after: product
            )
        } catch {
            products[index] = backup
            productError = "Failed to update product: \(error.localizedDescription)"
        }
    }

    func toggleProductActive(_ product: Product) async {
        guard let index = products.firstIndex(where: { $0.id == product.id }) else { return }
        let wasActive = products[index].isActive
        var updated = products[index]
        updated.isActive.toggle()
        products[index] = updated
        do {
            try await SupabaseManager.shared.client
                .from("products").update(updated).eq("id", value: updated.id).execute()
            auditLog.log(
                action: wasActive ? .deactivated : .activated, entity: .product,
                entityName: updated.name, entityId: updated.id.uuidString,
                details: "Product \(wasActive ? "deactivated" : "activated")"
            )
        } catch {
            products[index].isActive = wasActive
            productError = "Failed to update product: \(error.localizedDescription)"
        }
    }

    func deleteProduct(_ product: Product) async {
        do {
            try await SupabaseManager.shared.client
                .from("products")
                .delete()
                .eq("id", value: product.id)
                .execute()

            products.removeAll { $0.id == product.id }  // instant UI update
            productError = nil

            auditLog.log(
                action: .deleted, entity: .product,
                entityName: product.name, entityId: product.id.uuidString,
                details: "Product deleted (SKU: \(product.sku))",
                before: product
            )

        } catch {
            productError = "Failed to delete product: \(error.localizedDescription)"
        }
    }
    
    func submitRepair(for product: Product, issueDescription: String, repairCost: Double) async -> Bool {
        do {
            let payload = RepairInsertPayload(
                product_id: product.id,
                issueDescription: issueDescription,
                repairCost: repairCost
            )
            try await SupabaseManager.shared.client.from("repair").insert(payload).execute()
            try await SupabaseManager.shared.client
                .from("products").update(["in_repair": true]).eq("id", value: product.id).execute()
            await fetchProducts()
            return true
        } catch {
            print("❌ Failed to submit repair: \(error)")
            return false
        }
    }

    func resolveRepair(for product: Product) async {
        do {
            try await SupabaseManager.shared.client
                .from("repair")
                .update(["status": "Completed", "resolved_at": Date().ISO8601Format()])
                .eq("product_id", value: product.id)
                .eq("status", value: "Pending")
                .execute()
            try await SupabaseManager.shared.client
                .from("products").update(["in_repair": false]).eq("id", value: product.id).execute()
            await fetchProducts()
        } catch {
            print("❌ Failed to resolve repair: \(error)")
        }
    }

//     func fetchTotalInventoryCount() async {
//         do {
//             struct InventoryRecord: Decodable { let stock_quantity: Int }
//             let records: [InventoryRecord] = try await SupabaseManager.shared.client
//                 .from("inventory").select("stock_quantity").execute().value
//             self.totalInventoryCount = records.reduce(0) { $0 + $1.stock_quantity }
    func fetchTotalInventoryCount(storeId: UUID? = nil) async {
        do {
            struct InventoryRecord: Decodable {
                let stock_quantity: Int
            }
            
            var query = SupabaseManager.shared.client
                .from("inventory")
                .select("stock_quantity")
            
            if let targetStoreId = storeId ?? currentStoreID {
                query = query.eq("store_id", value: targetStoreId)
            }
            
            let records: [InventoryRecord] = try await query.execute().value
            
            let total = records.reduce(0) { $0 + $1.stock_quantity }
            self.totalInventoryCount = total
        } catch {
            print("❌ Failed to fetch total inventory count: \(error)")
        }
    }
}
