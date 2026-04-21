//
//  AuditLog.swift
//  Group5_RSMS
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
    
    // We keep these for the UI color coding
    var actionType: AuditActionType {
        if action.lowercased().contains("created") { return .created }
        if action.lowercased().contains("deleted") { return .deleted }
        return .updated
    }

    enum CodingKeys: String, CodingKey {
        case id
        case action
        case eventType = "event_type"
        case userName = "user_name"
        case entity
        case beforeData = "before_data"
        case afterData = "after_data"
        case createdAt = "created_at"
    }

    init(id: UUID? = nil, action: String, eventType: AuditEntityType, userName: String, entity: String, beforeData: [String: String]? = nil, afterData: [String: String]? = nil, createdAt: Date? = nil) {
        self.id = id
        self.action = action
        self.eventType = eventType
        self.userName = userName
        self.entity = entity
        self.beforeData = beforeData
        self.afterData = afterData
        self.createdAt = createdAt
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decodeIfPresent(UUID.self, forKey: .id)
        self.action = try container.decode(String.self, forKey: .action)
        
        let typeString = try container.decodeIfPresent(String.self, forKey: .eventType)
        self.eventType = AuditEntityType.allCases.first { $0.rawValue.lowercased() == typeString?.lowercased() } ?? .product
        
        self.userName = try container.decode(String.self, forKey: .userName)
        self.entity = try container.decode(String.self, forKey: .entity)
        
        #if canImport(Supabase)
        self.beforeData = AuditLog.extractStringMap(from: container, key: .beforeData)
        self.afterData = AuditLog.extractStringMap(from: container, key: .afterData)
        #else
        self.beforeData = try container.decodeIfPresent([String: String].self, forKey: .beforeData)
        self.afterData = try container.decodeIfPresent([String: String].self, forKey: .afterData)
        #endif
        
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encode(action, forKey: .action)
        try container.encode(eventType.rawValue, forKey: .eventType)
        try container.encode(userName, forKey: .userName)
        try container.encode(entity, forKey: .entity)
        try container.encodeIfPresent(beforeData, forKey: .beforeData)
        try container.encodeIfPresent(afterData, forKey: .afterData)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }

    #if canImport(Supabase)
    private static func extractStringMap(from container: KeyedDecodingContainer<CodingKeys>, key: CodingKeys) -> [String: String]? {
        guard let jsonDict = try? container.decodeIfPresent([String: AnyJSON].self, forKey: key) else { return nil }
        var map = [String: String]()
        for (k, v) in jsonDict {
            map[k] = stringify(v)
        }
        return map
    }

    private static func stringify(_ json: AnyJSON) -> String {
        switch json {
        case .string(let s): return s
        case .integer(let i): return String(i)
        case .double(let d): return String(d)
        case .bool(let b): return b ? "true" : "false"
        case .null: return "null"
        case .array(let arr): return "[" + arr.map { stringify($0) }.joined(separator: ", ") + "]"
        case .object(let obj): return "{" + obj.map { "\($0.key): \(stringify($0.value))" }.joined(separator: ", ") + "}"
        }
    }
    #endif

    var formattedTimestamp: String {
        guard let createdAt = createdAt else { return "Unknown" }
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy, h:mm a"
        return f.string(from: createdAt)
    }

    var relativeTimestamp: String {
        guard let createdAt = createdAt else { return "Just now" }
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: createdAt, relativeTo: Date())
    }
}

// MARK: - Entity Type (Category filter)
enum AuditEntityType: String, CaseIterable, Codable {
    case product   = "Products"
    case promotion = "Promotions"
    case user      = "Users"
    case tax       = "Tax"
    case inventoryTransfer = "inventory_transfer"

    var iconName: String {
        switch self {
        case .product:   return "tag.fill"
        case .promotion: return "gift.fill"
        case .user:      return "person.fill"
        case .tax:       return "doc.text.fill"
        case .inventoryTransfer: return "arrow.triangle.swap"
        }
    }
}

// MARK: - Action Type (Operation filter - UI Only)
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

// MARK: - Category Filter Enum
enum AuditCategoryFilter: String, CaseIterable {
    case all        = "All"
    case products   = "Products"
    case promotions = "Promotions"
    case users      = "Users"
    case tax        = "Tax"
    case inventoryTransfer = "Inventory Transfers"
}

// MARK: - Action Filter Enum
enum AuditOperationFilter: String, CaseIterable {
    case all     = "All"
    case created = "Created"
    case updated = "Updated"
    case deleted = "Deleted"
}
extension AuditLog {
    static func createEntry(
        action: String,
        type: AuditEntityType,
        entityName: String,
        before: [String: String]? = nil,
        after: [String: String]? = nil
    ) -> AuditLog {
        return AuditLog(
            id: nil, // Supabase generates this
            action: action,
            eventType: type,
            userName: "Current Admin", // Replace with actual Auth user name
            entity: entityName,
            beforeData: before,
            afterData: after,
            createdAt: nil // Supabase generates this
        )
    }
}
