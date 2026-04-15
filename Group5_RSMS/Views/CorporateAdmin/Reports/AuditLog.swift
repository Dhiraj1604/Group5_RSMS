// AuditLog.swift
// Group5_RSMS — Audit Logs feature (self-contained inside Reports)

import Foundation

// MARK: - Model
struct AuditLog: Identifiable {
    let id: UUID
    let action: String
    let user: String
    let entity: String
    let entityType: AuditEntityType
    let actionType: AuditActionType        // Created / Updated / Deleted
    let beforeData: [String: String]
    let afterData: [String: String]
    let timestamp: Date

    var formattedTimestamp: String {
        let f = DateFormatter()
        f.dateFormat = "d MMM yyyy, h:mm a"
        return f.string(from: timestamp)
    }

    var relativeTimestamp: String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: timestamp, relativeTo: Date())
    }
}

// MARK: - Entity Type (Category filter)
enum AuditEntityType: String, CaseIterable {
    case product   = "Products"
    case promotion = "Promotions"
    case user      = "Users"
    case tax       = "Tax"

    var iconName: String {
        switch self {
        case .product:   return "tag.fill"
        case .promotion: return "gift.fill"
        case .user:      return "person.fill"
        case .tax:       return "doc.text.fill"
        }
    }
}

// MARK: - Action Type (Operation filter)
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
}

// MARK: - Action Filter Enum
enum AuditOperationFilter: String, CaseIterable {
    case all     = "All"
    case created = "Created"
    case updated = "Updated"
    case deleted = "Deleted"
}

// MARK: - Mock Data
struct AuditLogMockData {
    static let logs: [AuditLog] = [
        AuditLog(
            id: UUID(),
            action: "Updated Product Price",
            user: "admin@luxebrand.com",
            entity: "Silk Evening Gown – SKU#1041",
            entityType: .product,
            actionType: .updated,
            beforeData: ["Price": "₹8,500", "Status": "Active", "Discount": "0%"],
            afterData:  ["Price": "₹9,800", "Status": "Active", "Discount": "0%"],
            timestamp: Date().addingTimeInterval(-3600)
        ),
        AuditLog(
            id: UUID(),
            action: "Deleted Product",
            user: "store.manager@luxebrand.com",
            entity: "Cashmere Overcoat – SKU#2209",
            entityType: .product,
            actionType: .deleted,
            beforeData: ["Status": "Active", "Visibility": "Visible", "Stock": "42 units"],
            afterData:  [:],
            timestamp: Date().addingTimeInterval(-7200)
        ),
        AuditLog(
            id: UUID(),
            action: "Created Diwali Offer",
            user: "marketing@luxebrand.com",
            entity: "Diwali Festive Collection 2024",
            entityType: .promotion,
            actionType: .created,
            beforeData: [:],
            afterData:  ["Discount": "20% off", "Valid From": "1 Nov 2024", "Valid To": "5 Nov 2024", "Code": "DIWALI20"],
            timestamp: Date().addingTimeInterval(-14400)
        ),
        AuditLog(
            id: UUID(),
            action: "Updated Tax Rule",
            user: "finance@luxebrand.com",
            entity: "GST – Apparel Category",
            entityType: .tax,
            actionType: .updated,
            beforeData: ["Tax Rate": "5%", "Applied To": "All Apparel", "Rule Status": "Active"],
            afterData:  ["Tax Rate": "12%", "Applied To": "All Apparel", "Rule Status": "Active"],
            timestamp: Date().addingTimeInterval(-28800)
        ),
        AuditLog(
            id: UUID(),
            action: "Updated Promotion Details",
            user: "marketing@luxebrand.com",
            entity: "Summer End Sale",
            entityType: .promotion,
            actionType: .updated,
            beforeData: ["Discount": "15% off", "Min Order": "₹3,000", "Status": "Active"],
            afterData:  ["Discount": "25% off", "Min Order": "₹2,000", "Status": "Active"],
            timestamp: Date().addingTimeInterval(-54000)
        ),
        AuditLog(
            id: UUID(),
            action: "Created New User",
            user: "admin@luxebrand.com",
            entity: "Priya Nair – Customer",
            entityType: .user,
            actionType: .created,
            beforeData: [:],
            afterData:  ["Name": "Priya Nair", "Email": "priya.nair@email.com", "Role": "Customer", "Tier": "Gold"],
            timestamp: Date().addingTimeInterval(-86400)
        ),
        AuditLog(
            id: UUID(),
            action: "Deleted Promotion",
            user: "marketing@luxebrand.com",
            entity: "Flash Sale – Republic Day",
            entityType: .promotion,
            actionType: .deleted,
            beforeData: ["Discount": "30% off", "Code": "REPUBLIC30", "Status": "Active"],
            afterData:  [:],
            timestamp: Date().addingTimeInterval(-129600)
        ),
        AuditLog(
            id: UUID(),
            action: "Created Product",
            user: "inventory@luxebrand.com",
            entity: "Heritage Leather Bag – SKU#3310",
            entityType: .product,
            actionType: .created,
            beforeData: [:],
            afterData:  ["Price": "₹24,500", "Stock": "28 units", "Status": "Active"],
            timestamp: Date().addingTimeInterval(-172800)
        )
    ]
}
