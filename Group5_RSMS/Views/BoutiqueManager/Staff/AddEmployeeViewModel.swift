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
    @Published var shiftStartTime: Date = Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var shiftEndTime: Date = Calendar.current.date(bySettingHour: 18, minute: 0, second: 0, of: Date()) ?? Date()
    @Published var weeklyOff: String = "Sunday"
    
    let roles = ["Sales Associate", "Store Supervisor", "Cashier", "Visual Merchandiser", "Alteration Tailor"]
    let countryCodes = ["+91", "+1", "+44", "+61", "+971", "+81", "+86"]
    let days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"]
    
    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        return formatter
    }()
    
    func setupForEditing(_ employee: Employee) {
        self.name = employee.name
        self.email = employee.email ?? ""
        self.role = employee.role
        self.salary = employee.salary.map { String(format: "%.0f", $0) } ?? ""
        self.joiningDate = employee.joiningDate ?? Date()
        self.weeklyOff = employee.weeklyOff ?? "Sunday"
        
        if let shift = employee.assignedShift {
            let parts = shift.split(separator: "-").map { $0.trimmingCharacters(in: .whitespaces) }
            if parts.count == 2 {
                if let start = timeFormatter.date(from: parts[0]),
                   let end = timeFormatter.date(from: parts[1]) {
                    self.shiftStartTime = start
                    self.shiftEndTime = end
                }
            }
        }
        
        if let phone = employee.phone {
            let parts = phone.split(separator: " ", maxSplits: 1)
            if parts.count == 2 {
                self.countryCode = String(parts[0])
                self.phone = String(parts[1])
            } else {
                self.phone = phone
            }
        }
    }
    
    func createEmployee(boutiqueId: UUID, existingId: UUID? = nil) -> Employee {
        let fullPhone = phone.isEmpty ? nil : "\(countryCode) \(phone)"
        let formattedShift = "\(timeFormatter.string(from: shiftStartTime)) - \(timeFormatter.string(from: shiftEndTime))"
        
        return Employee(
            id: existingId ?? UUID(),
            boutiqueId: boutiqueId,
            name: name,
            email: email.isEmpty ? nil : email,
            phone: fullPhone,
            role: role,
            salary: Double(salary),
            joiningDate: joiningDate,
            isActive: true,
            assignedShift: formattedShift,
            weeklyOff: weeklyOff,
            createdAt: Date()
        )
    }
}
