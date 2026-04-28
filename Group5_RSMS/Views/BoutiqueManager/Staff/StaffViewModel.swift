//
//  StaffViewModel.swift
//  Group5_RSMS
//

import Foundation
import Combine

@MainActor
final class StaffViewModel: ObservableObject {

    @Published var employees: [Employee] = []
    @Published var employeeSales: [UUID: Double] = [:]       // employeeId → total sales
    @Published var employeeTransactions: [UUID: Int] = [:]    // employeeId → total transaction count
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    private let sync = SupabaseSyncManager.shared

    // MARK: - Fetch all employees for a boutique
    func fetchEmployees(boutiqueId: UUID) async {
        if employees.isEmpty { isLoading = true }
        errorMessage = nil
        do {
            employees = try await sync.fetchEmployees(boutiqueId: boutiqueId)
            // Automatically fetch sales for ranking
            await fetchSalesPerEmployee(boutiqueId: boutiqueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Fetch sales total per employee (all time)
    func fetchSalesPerEmployee(boutiqueId: UUID) async {
        do {
            let sales = try await sync.fetchSalesPerEmployee(boutiqueId: boutiqueId)
            var salesMap: [UUID: Double] = [:]
            var transMap: [UUID: Int] = [:]
            for sale in sales { 
                salesMap[sale.employeeId] = sale.totalSales 
                transMap[sale.employeeId] = sale.transactionCount
            }
            employeeSales = salesMap
            employeeTransactions = transMap
        } catch {
            employeeSales = [:]
            employeeTransactions = [:]
        }
    }

    // MARK: - Fetch sales for a specific date range
    func fetchSalesPerEmployee(boutiqueId: UUID, from: Date, to: Date) async {
        do {
            let sales = try await sync.fetchSalesPerEmployee(boutiqueId: boutiqueId, from: from, to: to)
            var salesMap: [UUID: Double] = [:]
            var transMap: [UUID: Int] = [:]
            for sale in sales { 
                salesMap[sale.employeeId] = sale.totalSales 
                transMap[sale.employeeId] = sale.transactionCount
            }
            employeeSales = salesMap
            employeeTransactions = transMap
        } catch {
            // Silently ignore — sales data may not be set up yet in the DB
            employeeSales = [:]
        }
    }

    // MARK: - Helper: total sales for one employee
    func totalSales(for employeeId: UUID) -> Double {
        return employeeSales[employeeId] ?? 0.0
    }

    func transactionCount(for employeeId: UUID) -> Int {
        return employeeTransactions[employeeId] ?? 0
    }

    func averageOrderValue(for employeeId: UUID) -> Double {
        let count = transactionCount(for: employeeId)
        return count > 0 ? totalSales(for: employeeId) / Double(count) : 0.0
    }

    // MARK: - Sorted employees by sales (highest first)
    func employeesSortedBySales() -> [Employee] {
        return employees.sorted {
            totalSales(for: $0.id) > totalSales(for: $1.id)
        }
    }

    // MARK: - Add employee
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
