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

    // MARK: - Store Actions
    func addStore(_ store: Store) {
        stores.append(store)
    }

    func deleteStore(_ store: Store) {
        stores.removeAll { $0.id == store.id }
    }

    func deleteStores(at offsets: IndexSet) {
        stores.remove(atOffsets: offsets)
    }

    func toggleStoreActive(_ store: Store) {
        if let index = stores.firstIndex(where: { $0.id == store.id }) {
            stores[index].isActive.toggle()
        }
    }
}
