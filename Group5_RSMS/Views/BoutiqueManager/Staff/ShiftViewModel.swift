//
//  ShiftViewModel.swift
//  Group5_RSMS
//

import Foundation
import Combine

@MainActor
final class ShiftViewModel: ObservableObject {
    @Published var shifts: [Shift] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil
    
    // For minimum coverage logic
    let minimumCoverageThreshold = 2
    
    private let sync = SupabaseSyncManager.shared
    
    func fetchShifts(boutiqueId: UUID) async {
        isLoading = true
        errorMessage = nil
        do {
            shifts = try await sync.fetchShifts(boutiqueId: boutiqueId)
            shifts.sort { $0.startTime < $1.startTime }
        } catch {
            errorMessage = "Failed to load shifts: \(error.localizedDescription)"
        }
        isLoading = false
    }
    
    func createShift(_ shift: Shift, boutiqueId: UUID) async -> Bool {
        if hasConflict(for: shift.employeeId, start: shift.startTime, end: shift.endTime, excludingShiftId: shift.id) {
            errorMessage = "Schedule conflict: This employee is already assigned to a shift during this time."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        do {
            try await sync.createShift(shift)
            await fetchShifts(boutiqueId: boutiqueId)
            return true
        } catch {
            errorMessage = "Failed to create shift: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func updateShift(_ shift: Shift, boutiqueId: UUID) async -> Bool {
        if hasConflict(for: shift.employeeId, start: shift.startTime, end: shift.endTime, excludingShiftId: shift.id) {
            errorMessage = "Schedule conflict: This employee is already assigned to a shift during this time."
            return false
        }
        
        isLoading = true
        errorMessage = nil
        do {
            try await sync.updateShift(shift)
            await fetchShifts(boutiqueId: boutiqueId)
            return true
        } catch {
            errorMessage = "Failed to update shift: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    func deleteShift(_ id: UUID, boutiqueId: UUID) async -> Bool {
        isLoading = true
        errorMessage = nil
        do {
            try await sync.deleteShift(id: id)
            await fetchShifts(boutiqueId: boutiqueId)
            return true
        } catch {
            errorMessage = "Failed to delete shift: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
    
    // MARK: - Validation Logic
    
    func hasConflict(for employeeId: UUID, start: Date, end: Date, excludingShiftId: UUID? = nil) -> Bool {
        return shifts.contains { existingShift in
            guard existingShift.employeeId == employeeId else { return false }
            if let excludedId = excludingShiftId, existingShift.id == excludedId { return false }
            
            // Check for overlap: start < existing.end AND end > existing.start
            return start < existingShift.endTime && end > existingShift.startTime
        }
    }
    
    func isLowCoverage(for shift: Shift) -> Bool {
        // Count how many shifts overlap with the given shift's time window
        let overlappingShifts = shifts.filter { existingShift in
            // Must have at least some overlap
            return shift.startTime < existingShift.endTime && shift.endTime > existingShift.startTime
        }
        
        // Let's do a simple check: if the total number of unique employees scheduled during this shift's time block is less than threshold
        let uniqueEmployees = Set(overlappingShifts.map { $0.employeeId })
        return uniqueEmployees.count < minimumCoverageThreshold
    }
    
    func shiftsForDay(_ date: Date) -> [Shift] {
        let calendar = Calendar.current
        return shifts.filter { calendar.isDate($0.startTime, inSameDayAs: date) }
    }
}
