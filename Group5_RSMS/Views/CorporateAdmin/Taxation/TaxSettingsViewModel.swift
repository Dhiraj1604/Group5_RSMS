//
//  TaxSettingsViewModel.swift
//  Group5_RSMS
//
//  Sprint 1 — Tax Rules ViewModel
//  Task #8 (Zeeshan): saveRule / deleteRule now call ActivityLogService.shared.log()
//  No userEmail parameter needed — the service reads currentUserEmail set at login.
//

import SwiftUI
import Foundation
import Combine
import PostgREST
import Supabase

@MainActor
final class TaxSettingsViewModel: ObservableObject {

    // MARK: - Singleton
    static let shared = TaxSettingsViewModel()

    // MARK: - Published
    @Published var taxRules: [TaxRule] = []
    @Published var activeRuleId: UUID?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var selectedFilter: TaxFilter = .all

    enum TaxFilter: String, CaseIterable {
        case all = "All"
        case inclusive = "Inclusive"
        case exclusive = "Exclusive"
    }

    var activeRule: TaxRule? {
        guard let id = activeRuleId else { return taxRules.first }
        return taxRules.first(where: { $0.id == id }) ?? taxRules.first
    }

    var filteredRules: [TaxRule] {
        switch selectedFilter {
        case .all: return taxRules
        case .inclusive: return taxRules.filter { $0.isInclusive }
        case .exclusive: return taxRules.filter { !$0.isInclusive }
        }
    }

    init() {}

    // MARK: - Fetch

    func fetchTaxRules() async {
        isLoading = true
        errorMessage = nil
        do {
            let fetched: [TaxRule] = try await SupabaseManager.shared.client
                .from("tax_rules").select().execute().value
            self.taxRules = fetched
            if activeRuleId == nil, let first = fetched.first { activeRuleId = first.id }
            notifyScannerOfChange()
        } catch {
            print("❌ fetchTaxRules: \(error)")
            self.errorMessage = "Failed to load additional tax rules: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Save (add or update)

    func saveRule(_ rule: TaxRule) async -> Bool {
        isLoading = true
        errorMessage = nil

        let isNew = !taxRules.contains(where: { $0.id == rule.id })
        let previousRule = taxRules.first(where: { $0.id == rule.id })

        do {
            let saved: TaxRule = try await SupabaseManager.shared.client
                .from("tax_rules")
                .upsert(rule)
                .select()
                .single()
                .execute()
                .value

            await fetchTaxRules()

            ActivityLogService.shared.log(
                action: isNew ? .created : .updated,
                entity: .tax,
                entityName: saved.name,
                entityId: saved.id.uuidString,
                details: isNew
                    ? "Additional tax rule '\(saved.name)' for \(saved.category.rawValue) created at \(String(format: "%.1f", saved.rate * 100))%."
                    : "Additional tax rule '\(saved.name)' updated.",
                before: previousRule,
                after: saved
            )

            isLoading = false
            return true
        } catch {
            print("❌ saveRule: \(error)")
            self.errorMessage = "Failed to save additional tax rule: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }

    // MARK: - Delete

    func deleteRule(_ rule: TaxRule) async {
        isLoading = true
        errorMessage = nil
        do {
            try await SupabaseManager.shared.client
                .from("tax_rules").delete().eq("id", value: rule.id).execute()

            await fetchTaxRules()

            ActivityLogService.shared.log(
                action: .deleted,
                entity: .tax,
                entityName: rule.name,
                entityId: rule.id.uuidString,
                details: "Additional tax rule '\(rule.name)' deleted.",
                before: rule,
                after: nil as String?
            )
        } catch {
            print("❌ deleteRule: \(error)")
            self.errorMessage = "Failed to delete tax rule: \(error.localizedDescription)"
        }
        isLoading = false
    }

    // MARK: - Local actions

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
}

extension Notification.Name {
    static let taxRuleDidChange = Notification.Name("taxRuleDidChange")
}
