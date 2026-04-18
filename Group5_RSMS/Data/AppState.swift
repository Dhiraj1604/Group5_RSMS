//
//  AppState.swift
//  Group5_RSMS
//
//  Sprint 1 — Central observable state for the entire application.
//  Manages authentication, role selection, and store data.
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

    // MARK: - Store State
    var stores: [Store] = []
    var isLoadingStores: Bool = false
    var storeError: String? = nil
    var selectedStore: Store? = nil
    var currentStoreID: UUID? = nil

    // MARK: - Product Data
    var products: [InventoryProduct] = []
    var productError: String? = nil
    var isLoadingProducts: Bool = false

    private let sync = SupabaseSyncManager.shared

    // MARK: - Navigation
    var hasSelectedRole: Bool {
        selectedRole != nil
    }

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
        
        #if canImport(Supabase)
        do {
            struct Profile: Codable {
                let role: String
            }
            let session = try await SupabaseManager.shared.client.auth.session
            
            // Extract the metadata flag from the session invisible object!
            if let reqPass = session.user.userMetadata["requires_password_change"] {
                if reqPass == .bool(true) {
                    self.requiresPasswordChange = true
                }
            }
            
            let profile: Profile = try await SupabaseManager.shared.client
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
        #endif
        
        isLoggedIn = true
    }

    func selectRole(_ role: UserRole) {
        selectedRole = role
    }

    func logout() {
        isLoggedIn = false
        userEmail = ""
        selectedRole = nil
        stores = []
        
        #if canImport(Supabase)
        Task {
            try? await SupabaseManager.shared.client.auth.signOut()
        }
        #endif
    }

    func goBackToRoleSelection() {
        selectedRole = nil
    }

    // MARK: - Store Actions (Supabase-backed)

    func loadStores() async {
        isLoadingStores = true
        storeError = nil
        do {
            let fetchedStores = try await sync.fetchStores()
            self.stores = fetchedStores

            if selectedRole == .boutiqueManager {
                self.currentStoreID = fetchedStores.first(where: { $0.assignedManagerId == managerAuthId })?.id ?? UUID(uuidString: "b3fd8cb6-341b-453e-9ed4-8915aa25245c")
            } else if self.currentStoreID == nil, let first = fetchedStores.first {
                self.currentStoreID = first.id
            }
        } catch let DecodingError.keyNotFound(key, context) {
            print("❌ Key not found: \(key.stringValue)")
            print("❌ Context: \(context.debugDescription)")
            storeError = "Key not found: \(key.stringValue)"
        } catch let DecodingError.typeMismatch(type, context) {
            print("❌ Type mismatch: \(type)")
            print("❌ Context: \(context.debugDescription)")
            storeError = "Type mismatch: \(context.debugDescription)"
        } catch let DecodingError.valueNotFound(type, context) {
            print("❌ Value not found: \(type)")
            print("❌ Context: \(context.debugDescription)")
            storeError = "Value not found: \(context.debugDescription)"
        } catch {
            print("❌ Other error: \(error)")
            storeError = error.localizedDescription
        }
        isLoadingStores = false
    }

    func addStore(_ store: Store) async {
        do {
            try await sync.createStore(store)
            stores.append(store)
        } catch {
            storeError = error.localizedDescription
        }
    }

    func deleteStore(_ store: Store) async {
        do {
            try await sync.deleteStore(id: store.id)
            stores.removeAll { $0.id == store.id }
        } catch {
            storeError = error.localizedDescription
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
        let currentActive = stores[index].isActive ?? false
        stores[index].isActive = !currentActive
        let updated = stores[index]
        do {
            try await sync.updateStore(updated)
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
        } catch {
            stores[index] = backup
            storeError = error.localizedDescription
        }
    }

    // MARK: - Product Actions

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

    func submitRepair(for product: InventoryProduct, issueDescription: String, repairCost: Double) async -> Bool {
        do {
            let payload = RepairInsertPayload(
                product_id: product.id,
                issueDescription: issueDescription,
                repairCost: repairCost
            )

            try await SupabaseManager.shared.client
                .from("repair")
                .insert(payload)
                .execute()

            try await SupabaseManager.shared.client
                .from("products")
                .update(["inRepair": true])
                .eq("id", value: product.id)
                .execute()

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

    func resolveRepair(for product: InventoryProduct) async {
        do {
            try await SupabaseManager.shared.client
                .from("repair")
                .update(["status": "Completed", "resolved_at": Date().ISO8601Format()])
                .eq("product_id", value: product.id)
                .eq("status", value: "Pending")
                .execute()

            try await SupabaseManager.shared.client
                .from("products")
                .update(["inRepair": false])
                .eq("id", value: product.id)
                .execute()

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
