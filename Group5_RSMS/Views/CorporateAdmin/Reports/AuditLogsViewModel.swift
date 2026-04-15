// AuditLogsViewModel.swift
// Group5_RSMS — Audit Logs ViewModel (inside Reports)

import Foundation
import Combine

class AuditLogsViewModel: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedCategory: AuditCategoryFilter   = .all
    @Published var selectedOperation: AuditOperationFilter = .all

    let allLogs: [AuditLog] = AuditLogMockData.logs

    var filteredLogs: [AuditLog] {
        var result = allLogs

        // 1 — Category filter
        switch selectedCategory {
        case .all:        break
        case .products:   result = result.filter { $0.entityType == .product }
        case .promotions: result = result.filter { $0.entityType == .promotion }
        case .users:      result = result.filter { $0.entityType == .user }
        case .tax:        result = result.filter { $0.entityType == .tax }
        }

        // 2 — Operation filter
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
            $0.user.lowercased().contains(q)   ||
            $0.entity.lowercased().contains(q)
        }
    }

    var isEmpty: Bool { filteredLogs.isEmpty }
}
