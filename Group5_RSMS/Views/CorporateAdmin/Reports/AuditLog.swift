//
//  AuditLog.swift
//  Group5_RSMS
//
//

import Foundation
#if canImport(Supabase)
import Supabase
#endif

// MARK: - Model

struct AuditLog: Identifiable, Codable {
    let id: UUID?
    let action: String
    let eventType: AuditEntityType
    let userName: String
    let entity: String
    let beforeData: [String: String]?
    let afterData: [String: String]?
    let createdAt: Date?

    var actionType: AuditActionType {
        if action.lowercased().contains("created")     { return .created }
        if action.lowercased().contains("deleted")     { return .deleted }
        return .updated
    }

    enum CodingKeys: String, CodingKey {
        case id
        case action
        case eventType  = "event_type"
        case userName   = "user_name"
        case entity
        case beforeData = "before_data"
        case afterData  = "after_data"
        case createdAt  = "created_at"
    }

    // MARK: - Safe memberwise init (used in factory helper)
    init(id: UUID? = nil,
         action: String,
         eventType: AuditEntityType,
         userName: String,
         entity: String,
         beforeData: [String: String]? = nil,
         afterData: [String: String]? = nil,
         createdAt: Date? = nil) {
        self.id         = id
        self.action     = action
        self.eventType  = eventType
        self.userName   = userName
        self.entity     = entity
        self.beforeData = beforeData
        self.afterData  = afterData
        self.createdAt  = createdAt
    }

    // MARK: - Custom Decoder
    // Needed because:
    //  1. event_type strings like "Stores" must not crash if a case is added later
    //  2. before_data / after_data arrive as Supabase JSONB (AnyJSON), not [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        id         = try container.decodeIfPresent(UUID.self, forKey: .id)
        action     = try container.decode(String.self, forKey: .action)
        userName   = try container.decode(String.self, forKey: .userName)
        entity     = try container.decode(String.self, forKey: .entity)
        createdAt  = try container.decodeIfPresent(Date.self, forKey: .createdAt)

        // Safe eventType — unknown strings fall back to .product instead of crashing
        let typeRaw = try container.decodeIfPresent(String.self, forKey: .eventType) ?? ""
        eventType = AuditEntityType.allCases.first {
            $0.rawValue.lowercased() == typeRaw.lowercased()
        } ?? .product

        // JSONB columns — try [String: String] first, then AnyJSON via Supabase SDK
        beforeData = AuditLog.decodeStringMap(from: container, key: .beforeData)
        afterData  = AuditLog.decodeStringMap(from: container, key: .afterData)
    }

    // MARK: - Custom Encoder

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id,         forKey: .id)
        try container.encode(action,              forKey: .action)
        try container.encode(eventType.rawValue,  forKey: .eventType)
        try container.encode(userName,            forKey: .userName)
        try container.encode(entity,              forKey: .entity)
        try container.encodeIfPresent(beforeData, forKey: .beforeData)
        try container.encodeIfPresent(afterData,  forKey: .afterData)
        try container.encodeIfPresent(createdAt,  forKey: .createdAt)
    }

    // MARK: - JSONB → [String: String] helper

    private static func decodeStringMap(
        from container: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) -> [String: String]? {
        // Fast path: plain [String: String]
        if let plain = try? container.decodeIfPresent([String: String].self, forKey: key) {
            return plain
        }
        // Supabase SDK returns JSONB as [String: AnyJSON]
        #if canImport(Supabase)
        if let jsonDict = try? container.decodeIfPresent([String: AnyJSON].self, forKey: key) {
            var result = [String: String]()
            for (k, v) in jsonDict { result[k] = stringify(v) }
            return result.isEmpty ? nil : result
        }
        #endif
        return nil
    }

    #if canImport(Supabase)
    private static func stringify(_ json: AnyJSON) -> String {
        switch json {
        case .string(let s):   return s
        case .integer(let i):  return String(i)
        case .double(let d):   return String(d)
        case .bool(let b):     return b ? "true" : "false"
        case .null:            return "null"
        case .array(let arr):  return "[" + arr.map { stringify($0) }.joined(separator: ", ") + "]"
        case .object(let obj): return "{" + obj.map { "\($0.key): \(stringify($0.value))" }.joined(separator: ", ") + "}"
        }
    }
    #endif

    // MARK: - Formatted timestamps

    var formattedTimestamp: String {
        guard let createdAt else { return "Unknown" }
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy, h:mm a"
        return f.string(from: createdAt)
    }

    var relativeTimestamp: String {
        guard let createdAt else { return "Just now" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Entity Type
// NOTE: rawValue strings are written to the Supabase `event_type` column.
// Add new cases here AND in AuditEntity (AuditAction.swift) together.

enum AuditEntityType: String, CaseIterable, Codable {
    case product   = "Products"
    case store     = "Stores"
    case promotion = "Promotions"
    case user      = "Users"
    case tax       = "Tax"
    case inventoryTransfer = "inventory_transfer"

    var iconName: String {
        switch self {
        case .product:   return "tag.fill"
        case .store:     return "storefront.fill"
        case .promotion: return "gift.fill"
        case .user:      return "person.fill"
        case .tax:       return "percent"
//         case .tax:       return "doc.text.fill"
        case .inventoryTransfer: return "arrow.triangle.swap"
        }
    }
}

// MARK: - Action Type (UI only — derived from action string)

enum AuditActionType: String, CaseIterable {
    case created = "Created"
    case updated = "Updated"
    case deleted = "Deleted"

    var iconName: String {
        switch self {
        case .created: return "plus.circle.fill"
        case .updated: return "pencil.circle.fill"
        case .deleted: return "trash.circle.fill"
        }
    }
}

// MARK: - Category Filter (maps to AuditEntityType for UI)

enum AuditCategoryFilter: String, CaseIterable {
    case all        = "All"
    case products   = "Products"
    case stores     = "Stores"
    case promotions = "Promotions"
    case users      = "Users"
    case tax        = "Tax"
    case inventoryTransfer = "Inventory Transfers"
}

// MARK: - Operation Filter

enum AuditOperationFilter: String, CaseIterable {
    case all     = "All"
    case created = "Created"
    case updated = "Updated"
    case deleted = "Deleted"
}

// MARK: - Factory helper

extension AuditLog {
    static func createEntry(action: String,
                            type: AuditEntityType,
                            entityName: String,
                            before: [String: String]? = nil,
                            after: [String: String]? = nil) -> AuditLog {
        AuditLog(id: nil, action: action, eventType: type,
                 userName: "Current Admin", entity: entityName,
                 beforeData: before, afterData: after, createdAt: nil)
    }
}
