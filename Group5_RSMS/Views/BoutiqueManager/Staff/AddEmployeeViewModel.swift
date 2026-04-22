//
//  AddEmployeeViewModel.swift
//  Group5_RSMS
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class AddEmployeeViewModel: ObservableObject {
    @Published var name: String = ""
    @Published var email: String = ""
    @Published var countryCode: String = "+91"
    @Published var phone: String = ""
    @Published var role: String = "Sales Associate"
    @Published var salary: String = ""
    @Published var joiningDate: Date = Date()
    
    let roles = ["Sales Associate", "Store Supervisor", "Cashier", "Visual Merchandiser", "Alteration Tailor"]
    let countryCodes = ["+91", "+1", "+44", "+61", "+971", "+81", "+86"]
    
    func createEmployee(boutiqueId: UUID) -> Employee {
        let fullPhone = phone.isEmpty ? nil : "\(countryCode) \(phone)"
        return Employee(
            id: UUID(),
            boutiqueId: boutiqueId,
            name: name,
            email: email.isEmpty ? nil : email,
            phone: fullPhone,
            role: role,
            salary: Double(salary),
            joiningDate: joiningDate,
            isActive: true,
            createdAt: Date()
        )
    }
}
