//
//  AuditAction.swift
//  Group5_RSMS
//
//

import Foundation
import Supabase

// MARK: - AuditAction

enum AuditAction {
    case created, updated, deleted, activated, deactivated, priceSet, loggedIn, roleAssigned

    func label(for entityType: String) -> String {
        switch self {
        case .created:      return "\(entityType) Created"
        case .updated:      return "\(entityType) Updated"
        case .deleted:      return "\(entityType) Deleted"
        case .activated:    return "\(entityType) Activated"
        case .deactivated:  return "\(entityType) Deactivated"
        case .priceSet:     return "\(entityType) Price Set"
        case .loggedIn:     return "\(entityType) Logged In"
        case .roleAssigned: return "\(entityType) Role Assigned"
        }
    }
}

// MARK: - AuditEntity
// eventType MUST match AuditEntityType.rawValue in AuditLog.swift

enum AuditEntity {
    case product, store, tax, promotion, user

    var eventType: String {
        switch self {
        case .product:   return "Products"
        case .store:     return "Stores"
        case .tax:       return "Tax"
        case .promotion: return "Promotions"
        case .user:      return "Users"
        }
    }
}

// MARK: - Insert payload (no id / created_at — Supabase DEFAULT now())

private struct AuditLogInsert: @preconcurrency Encodable, Sendable {
    let action:      String
    let event_type:  String
    let user_name:   String
    let entity:      String
    let before_data: [String: String]?
    let after_data:  [String: String]?
}

// MARK: - ActivityLogService

final class ActivityLogService {

    static let shared = ActivityLogService()
    private init() {}

    /// Set this once in AppState.login() so every service can read the current user.
    var currentUserEmail: String = ""

    private var client: SupabaseClient { SupabaseManager.shared.client }

    // MARK: - Full log (with optional typed before/after snapshots)

    func log<B: Encodable, A: Encodable>(
        userEmail: String? = nil,
        action: AuditAction,
        entity: AuditEntity,
        entityName: String,
        entityId: String,
        details: String,
        before: B? = nil as String?,
        after: A? = nil as String?
    ) {
        let email = userEmail ?? currentUserEmail
        let beforeDict: [String: String]?
        let afterDict:  [String: String]?

        if before != nil && after != nil {
            let diff = diffEncode(before: before, after: after)
            beforeDict = diff.beforeDiff
            afterDict  = diff.afterDiff
        } else {
            beforeDict = encode(before)
            afterDict  = encode(after)
        }

        let payload = AuditLogInsert(
            action:      action.label(for: entity.eventType),
            event_type:  entity.eventType,
            user_name:   email.isEmpty ? "system" : email,
            entity:      entityName,
            before_data: beforeDict,
            after_data:  afterDict
        )

        Task.detached(priority: .utility) {
            do {
                try await SupabaseManager.shared.client
                    .from("audit_logs")
                    .insert(payload)
                    .execute()
                print("[Audit] \(payload.action) — \(entityName)")
            } catch {
                print("[Audit] Persist failed: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Convenience overload (no snapshots)

    func log(
        userEmail: String? = nil,
        action: AuditAction,
        entity: AuditEntity,
        entityName: String,
        entityId: String,
        details: String
    ) {
        log(
            userEmail: userEmail, action: action, entity: entity,
            entityName: entityName, entityId: entityId, details: details,
            before: nil as String?, after: nil as String?
        )
    }

    // MARK: - Encoder helpers

    func encode<T: Encodable>(_ value: T?) -> [String: String]? {
        guard let value else { return nil }
        guard let data = try? JSONEncoder().encode(value),
              let raw  = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        var result: [String: String] = [:]
        for (k, v) in raw { result[k] = "\(v)" }
        return result.isEmpty ? nil : result
    }

    func diffEncode<B: Encodable, A: Encodable>(
        before: B?, after: A?
    ) -> (beforeDiff: [String: String]?, afterDiff: [String: String]?) {
        let b = encode(before) ?? [:]
        let a = encode(after)  ?? [:]
        let noise: Set<String> = ["id", "created_at", "updated_at"]
        var cb: [String: String] = [:]
        var ca: [String: String] = [:]
        for key in Set(b.keys).union(a.keys).subtracting(noise) {
            let old = b[key]; let new = a[key]
            if old != new {
                cb[key] = old ?? "(none)"
                ca[key] = new ?? "(removed)"
            }
        }
        return (cb.isEmpty ? nil : cb, ca.isEmpty ? nil : ca)
    }
}
