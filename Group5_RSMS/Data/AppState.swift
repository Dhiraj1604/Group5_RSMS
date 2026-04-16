//
//  AppState.swift
//  Group5_RSMS
//
//  Sprint 1 — Central observable state for the entire application.
//  Manages authentication, role selection, and store data.
//

import SwiftUI
import Observation

@Observable
@MainActor
class AppState {
    // MARK: - Auth State
    var isLoggedIn: Bool = false
    var userEmail: String = ""
    var selectedRole: UserRole? = nil

    // MARK: - Store State
    var stores: [Store] = []
    var isLoadingStores: Bool = false
    var storeError: String? = nil
    var selectedStore: Store? = nil

    private let sync = SupabaseSyncManager.shared

    // MARK: - Navigation
    var hasSelectedRole: Bool {
        selectedRole != nil
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
        stores = []
    }

    func goBackToRoleSelection() {
        selectedRole = nil
    }

    // MARK: - Store Actions (Supabase-backed)

    func loadStores() async {
        isLoadingStores = true
        storeError = nil
        do {
            stores = try await sync.fetchStores()
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
        stores[index].isActive.toggle()          // optimistic update
        let updated = stores[index]
        do {
            try await sync.updateStore(updated)
        } catch {
            stores[index].isActive.toggle()      // rollback on failure
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
