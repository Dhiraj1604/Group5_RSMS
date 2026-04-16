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
    var managerAuthId: UUID? = nil
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
                .order("createdAt", ascending: false)
                .execute()
                .value
            self.stores = fetchedStores
            
            // Set current store context for Scanner operations or BM locking
            if selectedRole == .boutiqueManager {
                // Lock to the assigned store for Boutique Manager
                self.currentStoreID = fetchedStores.first(where: { $0.assignedManagerId == managerAuthId })?.id ?? UUID(uuidString: "b3fd8cb6-341b-453e-9ed4-8915aa25245c")
            } else if self.currentStoreID == nil, let first = fetchedStores.first {
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

    // Toggle active — isActive is now synced with DB as Bool?
    func toggleStoreActive(_ store: Store) {
        if let index = stores.firstIndex(where: { $0.id == store.id }) {
            stores[index].isActive = !(stores[index].isActive ?? true)
        }
    }
}
