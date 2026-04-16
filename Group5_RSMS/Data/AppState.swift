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
    var userEmail: String = ""
    var managerAuthId: UUID? = nil
    var selectedRole: UserRole? = nil

    // MARK: - Store State
    var stores: [Store] = []
    var isLoadingStores: Bool = false
    var storeError: String? = nil
    var selectedStore: Store? = nil
    var currentStoreID: UUID? = nil

    private let sync = SupabaseSyncManager.shared

    // MARK: - Navigation
    var hasSelectedRole: Bool {
        selectedRole != nil
    }

    // MARK: - Auth Actions
    func login(email: String) {
        userEmail = email
        isLoggedIn = true
        managerAuthId = UUID(uuidString: "3bb61198-7f75-4d11-9e72-28c5afdb53a7") // Mock auth user id for current session
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
            
            // Set current store context for Scanner operations or BM locking
            if selectedRole == .boutiqueManager {
                // Lock to the assigned store for Boutique Manager
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
        stores[index].isActive = !currentActive          // optimistic update
        let updated = stores[index]
        do {
            try await sync.updateStore(updated)
        } catch {
            stores[index].isActive = currentActive      // rollback on failure
            storeError = error.localizedDescription
        }
    }

    func updateStoreDetails(_ store: Store) async {
        guard let index = stores.firstIndex(where: { $0.id == store.id }) else { return }
        let backup = stores[index]
        stores[index] = store // optimistic update
        do {
            try await sync.updateStore(store)
        } catch {
            stores[index] = backup // rollback on failure
            storeError = error.localizedDescription
        }
    }
}
