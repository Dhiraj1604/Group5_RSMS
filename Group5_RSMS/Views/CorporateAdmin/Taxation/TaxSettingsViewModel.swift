//
//  TaxSettingsViewModel.swift
//  Group5_RSMS
//
//  Views/CorporateAdmin/Taxation — Tax Rules ViewModel
//  Manages CRUD operations for TaxRule objects.
//  Publishes the active rule so ICScanViewModel can pick it up.
//  Reads available stores from AppState (Store Registration — Task 1).
//

import SwiftUI
import Foundation
import Combine
import PostgREST
import Supabase
// MARK: - View Model

@MainActor
final class TaxSettingsViewModel: ObservableObject {

    // MARK: - Shared Instance
    /// Singleton so that ICScanViewModel can read the current active rule.
    static let shared = TaxSettingsViewModel()

    // MARK: - Published State
    @Published var taxRules: [TaxRule] = []
    @Published var activeRuleId: UUID?
    @Published var availableStores: [Store] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Computed
    var activeRule: TaxRule? {
        guard let activeId = activeRuleId else { return taxRules.first }
        return taxRules.first(where: { $0.id == activeId }) ?? taxRules.first
    }

    // MARK: - Init
    init() {
        // Data loading is now driven by views to support async/await via tasks
    }

    // MARK: - AppState Integration
    func fetchAvailableStores(from appState: AppState) {
        availableStores = appState.stores
    }

    // MARK: - Supabase TaxRule CRUD

    func fetchTaxRules() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetchedRules: [TaxRule] = try await SupabaseManager.shared.client
                .from("tax_rules")
                .select()
                .execute()
                .value
            
            self.taxRules = fetchedRules
            
            // Set first rule as active if none selected
            if activeRuleId == nil, let first = fetchedRules.first {
                activeRuleId = first.id
            }
            notifyScannerOfChange()
        } catch {
            print("❌ Failed to fetch tax rules: \(error)")
            self.errorMessage = "Failed to load tax rules: \(error.localizedDescription)"
        }
        isLoading = false
    }

    func saveRule(_ rule: TaxRule) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            // Upsert the rule: if id exists, it updates; else, inserts
            let savedRule: TaxRule = try await SupabaseManager.shared.client
                .from("tax_rules")
                .upsert(rule) // Now correctly serializes TaxRule
                .select()
                .single()
                .execute()
                .value
            
            // Refresh fully to ensure Single Source of Truth
            await fetchTaxRules()
            
            isLoading = false
            return true
        } catch {
            print("❌ Failed to save tax rule: \(error)")
            let errorMsg = error.localizedDescription
            if errorMsg.contains("duplicate key") || errorMsg.contains("tax_rules_store_id_name_key") {
                self.errorMessage = "A rule with this name already exists for this location."
            } else {
                self.errorMessage = "Failed to save tax rule: \(errorMsg)"
            }
            isLoading = false
            return false
        }
    }

    func deleteRule(_ rule: TaxRule) async {
        isLoading = true
        errorMessage = nil
        do {
            try await SupabaseManager.shared.client
                .from("tax_rules")
                .delete()
                .eq("id", value: rule.id)
                .execute()
            
            // Refresh fully to ensure Single Source of Truth
            await fetchTaxRules()
        } catch {
            print("❌ Failed to delete tax rule: \(error)")
            self.errorMessage = "Failed to delete tax rule: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Local Actions
    func setActiveRule(_ rule: TaxRule) {
        activeRuleId = rule.id
        print("🎯 [TaxSettings] Active rule → \(rule.name)")
        notifyScannerOfChange()
    }

    private func notifyScannerOfChange() {
        NotificationCenter.default.post(
            name: .taxRuleDidChange,
            object: nil,
            userInfo: ["rule": activeRule as Any]
        )
    }

    func store(for storeId: UUID) -> Store? {
        availableStores.first(where: { $0.id == storeId })
    }

    func storeName(for storeId: UUID) -> String {
        store(for: storeId)?.name ?? "Unknown Boutique"
    }
}

// MARK: - Notification Name
extension Notification.Name {
    static let taxRuleDidChange = Notification.Name("taxRuleDidChange")
}
