//
//  StaffViewModel.swift
//  Group5_RSMS
//

import Foundation
import Combine

@MainActor
final class StaffViewModel: ObservableObject {

    @Published var employees: [Employee] = []
    @Published var employeeSales: [UUID: Double] = [:]   // employeeId → total sales in selected period
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let sync = SupabaseSyncManager.shared

    // MARK: - Fetch all employees for a boutique
    func fetchEmployees(boutiqueId: UUID) async {
        if employees.isEmpty { isLoading = true }
        errorMessage = nil
        do {
            employees = try await sync.fetchEmployees(boutiqueId: boutiqueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Fetch sales total per employee (all time)
    func fetchSalesPerEmployee(boutiqueId: UUID) async {
        do {
            let sales = try await sync.fetchSalesPerEmployee(boutiqueId: boutiqueId)
            var map: [UUID: Double] = [:]
            for sale in sales { map[sale.employeeId] = sale.totalSales }
            employeeSales = map
        } catch {
            // Silently ignore — sales data may not be set up yet in the DB
            employeeSales = [:]
        }
    }

    // MARK: - Fetch sales for a specific date range
    func fetchSalesPerEmployee(boutiqueId: UUID, from: Date, to: Date) async {
        do {
            let sales = try await sync.fetchSalesPerEmployee(boutiqueId: boutiqueId, from: from, to: to)
            var map: [UUID: Double] = [:]
            for sale in sales { map[sale.employeeId] = sale.totalSales }
            employeeSales = map
        } catch {
            // Silently ignore — sales data may not be set up yet in the DB
            employeeSales = [:]
        }
    }

    // MARK: - Helper: total sales for one employee
    func totalSales(for employeeId: UUID) -> Double {
        return employeeSales[employeeId] ?? 0.0
    }

    // MARK: - Sorted employees by sales (highest first)
    func employeesSortedBySales() -> [Employee] {
        return employees.sorted {
            totalSales(for: $0.id) > totalSales(for: $1.id)
        }
    }

    func addEmployee(_ employee: Employee, boutiqueId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            try await sync.createEmployee(employee)
            await fetchEmployees(boutiqueId: boutiqueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func updateEmployee(_ employee: Employee, boutiqueId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            try await sync.updateEmployee(employee)
            await fetchEmployees(boutiqueId: boutiqueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func toggleEmployeeStatus(_ employee: Employee, boutiqueId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            let newStatus = !(employee.isActive ?? true)
            try await sync.toggleEmployeeStatus(id: employee.id, isActive: newStatus)
            await fetchEmployees(boutiqueId: boutiqueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func deleteEmployee(_ employee: Employee, boutiqueId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            // Ensure related payout records are deleted to satisfy foreign key constraints
            let payouts = try? await sync.fetchPayouts(for: employee.id)
            for payout in payouts ?? [] {
                try? await sync.deletePayout(id: payout.id)
            }
            
            // Ensure related commission rate records are deleted
            let rates = try? await sync.fetchCommissionRates(boutiqueId: boutiqueId)
            let employeeRates = (rates ?? []).filter { $0.employeeId == employee.id }
            for rate in employeeRates {
                try? await sync.deleteCommissionRate(id: rate.id)
            }

            // Finally delete the employee record
            try await sync.deleteEmployee(id: employee.id)
            await fetchEmployees(boutiqueId: boutiqueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
