//
//  AuditAction.swift
//  Group5_RSMS
//
//  Created by Zeeshan Khan on 16/04/26.
//


//
//  ActivityLogService.swift
//  Group5_RSMS
//
//  Sprint 1 — Task #8 (User Activity Monitor) — Zeeshan
//
//  Singleton middleware that intercepts every write in AppState and
//  persists a structured row to the `audit_logs` Supabase table.
//
//  Schema consumed (matches teammate's AuditLog.swift CodingKeys):
//    id            UUID  (server-generated, omitted on insert)
//    action        TEXT  e.g. "Product Created", "Boutique Deleted"
//    event_type    TEXT  matches AuditEntityType.rawValue
//    user_name     TEXT  the logged-in user's email
//    entity        TEXT  the entity's display name / SKU
//    before_data   JSONB [String: String] snapshot before change  (nullable)
//    after_data    JSONB [String: String] snapshot after change   (nullable)
//    created_at    TIMESTAMPTZ  (server-generated via DEFAULT now())
//

import Foundation
import Supabase

// MARK: - Action / Entity enums used by AppState callers

enum AuditAction {
    case created, updated, deleted, activated, deactivated

    /// Human-readable verb for the `action` column
    func label(for entityName: String) -> String {
        switch self {
        case .created:     return "\(entityName) Created"
        case .updated:     return "\(entityName) Updated"
        case .deleted:     return "\(entityName) Deleted"
        case .activated:   return "\(entityName) Activated"
        case .deactivated: return "\(entityName) Deactivated"
        }
    }
}

enum AuditEntity {
    case product, store

    /// Must match AuditEntityType.rawValue in teammate's AuditLog.swift
    var eventType: String {
        switch self {
        case .product: return "Products"
        case .store:   return "Stores"
        }
    }
}

// MARK: - Insert-only payload (no id / created_at — server fills these)

private struct AuditLogInsert: Encodable {
    let action: String
    let event_type: String
    let user_name: String
    let entity: String
    let before_data: [String: String]?
    let after_data: [String: String]?
}

// MARK: - Service

final class ActivityLogService {

    static let shared = ActivityLogService()
    private init() {}

    private let client = SupabaseManager.shared.client

    // MARK: - Generic log entry point

    /// Called by AppState after every mutating operation.
    /// `before` / `after` are Encodable snapshots — only changed fields are persisted.
    func log<B: Encodable, A: Encodable>(
        userEmail: String,
        action: AuditAction,
        entity: AuditEntity,
        entityName: String,
        entityId: String,
        details: String,
        before: B? = nil as String?,
        after: A? = nil as String?
    ) {
        let beforeDict: [String: String]?
        let afterDict: [String: String]?

        // When both snapshots exist → diff them so we only store changed fields
        if before != nil && after != nil {
            let diff = diffEncode(before: before, after: after)
            beforeDict = diff.beforeDiff
            afterDict  = diff.afterDiff
        } else {
            // Create (after only) or Delete (before only) — store full snapshot
            beforeDict = encode(before)
            afterDict  = encode(after)
        }

        let payload = AuditLogInsert(
            action:      action.label(for: entity.eventType.dropLast().description),
            event_type:  entity.eventType,
            user_name:   userEmail.isEmpty ? "system" : userEmail,
            entity:      entityName,
            before_data: beforeDict,
            after_data:  afterDict
        )

        Task.detached(priority: .utility) { [weak self] in
            guard let self else { return }
            do {
                try await self.client
                    .from("audit_logs")
                    .insert(payload)
                    .execute()
                print("✅ [AuditLog] \(payload.action) — \(entityName)")
            } catch {
                // Non-fatal: audit failure must never crash the app
                print("⚠️ [AuditLog] Failed to persist log: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Convenience overload (no before/after snapshot)

    func log(
        userEmail: String,
        action: AuditAction,
        entity: AuditEntity,
        entityName: String,
        entityId: String,
        details: String
    ) {
        log(
            userEmail:  userEmail,
            action:     action,
            entity:     entity,
            entityName: entityName,
            entityId:   entityId,
            details:    details,
            before:     nil as String?,
            after:      nil as String?
        )
    }

    // MARK: - Encoder helper

    /// Encodes any Encodable to [String: String] for the JSONB columns.
    /// Non-encodable values are safely ignored.
    private func encode<T: Encodable>(_ value: T?) -> [String: String]? {
        guard let value else { return nil }
        guard let data = try? JSONEncoder().encode(value),
              let raw  = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        // Flatten to [String: String] — keeps the schema simple and readable in the UI
        var result: [String: String] = [:]
        for (k, v) in raw {
            result[k] = "\(v)"
        }
        return result.isEmpty ? nil : result
    }

    // MARK: - Diff helper

    /// Compares two Encodable values and returns only the changed fields.
    /// `beforeDiff` contains old values of changed keys, `afterDiff` contains new values.
    /// Keys that are identical in both are excluded.
    /// Keys that exist only in before (removed) or only in after (added) are included.
    func diffEncode<B: Encodable, A: Encodable>(
        before: B?,
        after: A?
    ) -> (beforeDiff: [String: String]?, afterDiff: [String: String]?) {
        let beforeDict = encode(before) ?? [:]
        let afterDict  = encode(after) ?? [:]

        // Skip noise keys that aren't meaningful to users
        let noiseKeys: Set<String> = ["id", "created_at", "updated_at"]

        var changedBefore: [String: String] = [:]
        var changedAfter: [String: String] = [:]

        let allKeys = Set(beforeDict.keys).union(afterDict.keys).subtracting(noiseKeys)

        for key in allKeys {
            let oldVal = beforeDict[key]
            let newVal = afterDict[key]

            if oldVal != newVal {
                // Field changed
                if let old = oldVal {
                    changedBefore[key] = old
                } else {
                    changedBefore[key] = "(none)"
                }
                if let new = newVal {
                    changedAfter[key] = new
                } else {
                    changedAfter[key] = "(removed)"
                }
            }
        }

        return (
            beforeDiff: changedBefore.isEmpty ? nil : changedBefore,
            afterDiff:  changedAfter.isEmpty  ? nil : changedAfter
        )
    }
}

// MARK: - String helper used in label(for:)

private extension Substring {
    var description: String { String(self) }
}