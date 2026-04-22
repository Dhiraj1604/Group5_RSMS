import Foundation

struct EmployeeOrder: Codable, Identifiable {
    let id: UUID
    let employeeId: UUID
    let boutiqueId: UUID?
    let totalAmount: Double
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case employeeId = "employee_id"
        case boutiqueId = "boutique_id"
        case totalAmount = "total_amount"
        case createdAt = "created_at"
    }
}
