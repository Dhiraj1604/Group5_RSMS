//
//  CommissionViewModel.swift
//  Group5_RSMS
//
//  Created by Apple on 19/04/26.
//

import Foundation
import Combine

@MainActor
final class CommissionViewModel: ObservableObject {

    @Published var commissionRates: [CommissionRate] = []
    @Published var payouts: [CommissionPayout] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    @Published var successMessage: String? = nil

    private let sync = SupabaseSyncManager.shared

    // MARK: - Fetch commission rates for boutique
    func fetchCommissionRates(boutiqueId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            commissionRates = try await sync.fetchCommissionRates(boutiqueId: boutiqueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Set commission rate for an employee
    func setCommissionRate(
        boutiqueId: UUID,
        employeeId: UUID,
        rate: Double,
        effectiveFrom: Date,
        createdBy: UUID
    ) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            let newRate = CommissionRate(
                id: UUID(),
                boutiqueId: boutiqueId,
                employeeId: employeeId,
                ratePercentage: rate,
                effectiveFrom: effectiveFrom,
                effectiveTo: nil,
                createdBy: createdBy,
                createdAt: Date()
            )
            try await sync.setCommissionRate(newRate)
            successMessage = "Commission rate set successfully"
            await fetchCommissionRates(boutiqueId: boutiqueId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Fetch payouts for an employee
    func fetchPayouts(employeeId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            payouts = try await sync.fetchPayouts(for: employeeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Create a new payout
    func createPayout(
        boutiqueId: UUID,
        employeeId: UUID,
        periodStart: Date,
        periodEnd: Date,
        totalSales: Double,
        commissionRate: Double
    ) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            let commissionAmount = (totalSales * commissionRate) / 100.0
            let payout = CommissionPayout(
                id: UUID(),
                boutiqueId: boutiqueId,
                employeeId: employeeId,
                periodStart: periodStart,
                periodEnd: periodEnd,
                totalSalesAmount: totalSales,
                commissionRate: commissionRate,
                commissionAmount: commissionAmount,
                status: .pending,
                approvedBy: nil,
                approvedAt: nil,
                payoutDate: nil,
                createdAt: Date()
            )
            try await sync.createPayout(payout)
            successMessage = "Payout created successfully"
            await fetchPayouts(employeeId: employeeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Approve a payout
    func approvePayout(id: UUID, approvedBy: UUID, employeeId: UUID) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        do {
            try await sync.approvePayout(id: id, approvedBy: approvedBy)
            successMessage = "Payout approved successfully"
            await fetchPayouts(employeeId: employeeId)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    // MARK: - Helper
    func currentRate(for employeeId: UUID) -> CommissionRate? {
        return commissionRates
            .filter { $0.employeeId == employeeId && $0.effectiveTo == nil }
            .sorted { $0.effectiveFrom > $1.effectiveFrom }
            .first
    }
}
