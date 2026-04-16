//
//  AuditLogsViewModel.swift
//  Group5_RSMS
//

import Foundation
import Combine

@MainActor
class AuditLogsViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: AuditCategoryFilter   = .all
    @Published var selectedOperation: AuditOperationFilter = .all
    @Published var logs: [AuditLog] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let service = AuditLogService()

    var filteredLogs: [AuditLog] {
        var result = logs

        // 1 — Category filter (eventType)
        switch selectedCategory {
        case .all:        break
        case .products:   result = result.filter { $0.eventType == .product }
        case .promotions: result = result.filter { $0.eventType == .promotion }
        case .users:      result = result.filter { $0.eventType == .user }
        case .tax:        result = result.filter { $0.eventType == .tax }
        }

        // 2 — Operation filter (actionType)
        switch selectedOperation {
        case .all:     break
        case .created: result = result.filter { $0.actionType == .created }
        case .updated: result = result.filter { $0.actionType == .updated }
        case .deleted: result = result.filter { $0.actionType == .deleted }
        }

        // 3 — Search
        guard !searchText.isEmpty else { return result }
        let q = searchText.lowercased()
        return result.filter {
            $0.action.lowercased().contains(q) ||
            $0.userName.lowercased().contains(q)   ||
            $0.entity.lowercased().contains(q)
        }
    }

    var isEmpty: Bool { filteredLogs.isEmpty }

    func loadLogs() async {
        isLoading = true
        errorMessage = nil
        do {
            self.logs = try await service.fetchLogs()
        } catch {
            self.errorMessage = "Failed to load logs: \(error.localizedDescription)"
            print("Fetch error: \(error)")
        }
        isLoading = false
    }
}
