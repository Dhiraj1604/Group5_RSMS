//
//  AuditLogService.swift
//  Group5_RSMS
//

import Foundation
import Supabase

class AuditLogService {
    private let client = SupabaseManager.shared.client
    
    func fetchLogs() async throws -> [AuditLog] {
        let response: [AuditLog] = try await client
            .from("audit_logs")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
        return response
    }
    
    func createLog(_ log: AuditLog) async throws {
        try await client
            .from("audit_logs")
            .insert(log)
            .execute()
    }
}
