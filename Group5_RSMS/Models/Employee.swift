//
//  Employee.swift
//  Group5_RSMS
//
//  Created by Apple on 19/04/26.
//


import Foundation

struct Employee: Codable, Identifiable {
    let id: UUID
    let boutiqueId: UUID
    let name: String
    let email: String?
    let phone: String?
    let role: String
    let salary: Double?
    let joiningDate: Date?
    let isActive: Bool?
    let createdAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case boutiqueId  = "boutique_id"
        case name
        case email
        case phone
        case role
        case salary
        case joiningDate = "joining_date"
        case isActive    = "is_active"
        case createdAt   = "created_at"
    }
    
}
struct EmployeeSalesSummary: Codable {
    let employeeId: UUID
    let totalSales: Double

    enum CodingKeys: String, CodingKey {
        case employeeId  = "employee_id"
        case totalSales  = "sum"
    }
}
