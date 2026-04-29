//
//  ShiftScheduleView.swift
//  Group5_RSMS
//
//  Clean, simple schedule view: pick a day, see the shifts for that day.
//

import SwiftUI

struct ShiftScheduleView: View {
    @ObservedObject var shiftVM: ShiftViewModel
    @ObservedObject var staffVM: StaffViewModel
    @Binding var showingAddShift: Bool
    let boutiqueId: UUID

    @State private var selectedDate = Date()
    @State private var weekOffset = 0
    @State private var shiftToEdit: Shift?
    @State private var shiftToDelete: Shift?
    @State private var showDeleteConfirm = false

    private let calendar = Calendar.current

    // ── Week strip helpers ──────────────────────────────────────────────
    private var weekDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.date(
            byAdding: .weekOfYear, value: weekOffset,
            to: today.startOfWeek(using: calendar)
        ) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private var weekRangeLabel: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let f = DateFormatter(); f.dateFormat = "d MMM"
        let g = DateFormatter(); g.dateFormat = "d MMM yyyy"
        return "\(f.string(from: first)) – \(g.string(from: last))"
    }

    // ── Shifts for the selected day ─────────────────────────────────────
    private var dailyShifts: [Shift] {
        shiftVM.shiftsForDay(selectedDate).sorted { $0.startTime < $1.startTime }
    }

    var body: some View {
        VStack(spacing: 0) {

            // ── Week strip ──────────────────────────────────────────────
            VStack(spacing: 0) {
                HStack {
                    Button { weekOffset -= 1 } label: {
                        Image(systemName: "chevron.left")
                            .foregroundColor(RSMSTheme.Colors.accentGold).padding(8)
                    }
                    Spacer()
                    Text(weekRangeLabel)
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    Spacer()
                    Button { weekOffset += 1 } label: {
                        Image(systemName: "chevron.right")
                            .foregroundColor(RSMSTheme.Colors.accentGold).padding(8)
                    }
                }
                .padding(.horizontal, 8).padding(.top, 12)

                HStack(spacing: 6) {
                    ForEach(weekDays, id: \.self) { day in
                        CalendarDayView(
                            day: day,
                            selectedDate: selectedDate,
                            calendar: calendar,
                            hasShifts: !shiftVM.shiftsForDay(day).isEmpty
                        ) {
                            selectedDate = day
                        }
                    }
                }
                .padding(.horizontal, 12).padding(.vertical, 10)
            }
            .background(RSMSTheme.Colors.backgroundDeep)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal, 16).padding(.top, 8).padding(.bottom, 4)

            // ── Day header ──────────────────────────────────────────────
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(formattedFullDate(selectedDate))
                        .font(.title3.weight(.bold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                    Text(dailyShifts.isEmpty
                         ? "No shifts scheduled"
                         : "\(dailyShifts.count) shift\(dailyShifts.count == 1 ? "" : "s") scheduled")
                        .font(.caption)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                Spacer()
            }
            .padding(.horizontal, 20).padding(.vertical, 12)

            Divider()
                .background(RSMSTheme.Colors.textSecondary.opacity(0.2))
                .padding(.horizontal, 16)

            // ── Shift list ──────────────────────────────────────────────
            if shiftVM.isLoading {
                Spacer()
                ProgressView().tint(RSMSTheme.Colors.accentGold)
                Spacer()
            } else if dailyShifts.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "moon.zzz.fill")
                        .font(.system(size: 48))
                        .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.3))
                    Text("No shifts on this day")
                        .font(.headline)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    Text("Tap + to add a shift")
                        .font(.caption)
                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                }
                Spacer()
            } else {
                List {
                    ForEach(dailyShifts) { shift in
                        SimpleShiftRow(
                            shift: shift,
                            staffName: employeeName(for: shift.employeeId),
                            staffRole: staffRole(for: shift.employeeId)
                        )
                        .listRowBackground(RSMSTheme.Colors.backgroundDeep)
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                        .listRowSeparator(.hidden)
                        .onTapGesture { shiftToEdit = shift }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) { confirmDelete(shift) } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(RSMSTheme.Colors.backgroundPrimary)
            }
        }
        // ── Sheets ──────────────────────────────────────────────────────
        .sheet(isPresented: $showingAddShift) {
            ManageShiftView(
                shiftVM: shiftVM,
                boutiqueId: boutiqueId,
                employees: staffVM.employees,
                existingShift: nil,
                selectedDate: selectedDate
            )
        }
        .sheet(item: $shiftToEdit) { shift in
            ManageShiftView(
                shiftVM: shiftVM,
                boutiqueId: boutiqueId,
                employees: staffVM.employees,
                existingShift: shift,
                selectedDate: selectedDate
            )
        }
        // ── Initial load ────────────────────────────────────────────────
        .task {
            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
            await shiftVM.fetchShifts(boutiqueId: boutiqueId)
        }
        // ── Refresh shifts every time the sheet closes ──────────────────
        .onChange(of: showingAddShift) { _, isShowing in
            if !isShowing {
                Task { await shiftVM.fetchShifts(boutiqueId: boutiqueId) }
            }
        }
        .onChange(of: shiftToEdit?.id) { _, newVal in
            if newVal == nil {
                Task { await shiftVM.fetchShifts(boutiqueId: boutiqueId) }
            }
        }
        .alert("Delete Shift", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { shiftToDelete = nil }
            Button("Delete", role: .destructive, action: executeDelete)
        } message: {
            Text(deleteAlertMessage)
        }
    }

    private func executeDelete() {
        guard let shift = shiftToDelete else { return }
        Task {
            _ = await shiftVM.deleteShift(shift.id, boutiqueId: boutiqueId)
            shiftToDelete = nil
        }
    }

    private var deleteAlertMessage: String {
        guard let shift = shiftToDelete else { return "Are you sure?" }
        let f = DateFormatter(); f.dateFormat = "HH:mm"
        let name = employeeName(for: shift.employeeId)
        return "Remove \(name)'s shift (\(f.string(from: shift.startTime))–\(f.string(from: shift.endTime)))? This cannot be undone."
    }

    private func confirmDelete(_ shift: Shift) {
        shiftToDelete = shift
        showDeleteConfirm = true
    }

    private func dayLetter(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return String(f.string(from: date).prefix(1))
    }

    private func formattedFullDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, d MMMM"
        return f.string(from: date)
    }

    private func employeeName(for id: UUID) -> String {
        staffVM.employees.first(where: { $0.id == id })?.name ?? "Unknown"
    }

    private func staffRole(for id: UUID) -> String {
        staffVM.employees.first(where: { $0.id == id })?.role ?? ""
    }
}

// MARK: - Simple Shift Row
struct SimpleShiftRow: View {
    let shift: Shift
    let staffName: String
    let staffRole: String

    var body: some View {
        HStack(spacing: 14) {
            // Time column
            VStack(alignment: .center, spacing: 2) {
                Text(timeStr(shift.startTime))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                Rectangle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.3))
                    .frame(width: 1.5, height: 12)
                Text(timeStr(shift.endTime))
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
            .frame(width: 60)

            // Avatar
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 40, height: 40)
                Text(staffName.prefix(1).uppercased())
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }

            // Name + role + duration
            VStack(alignment: .leading, spacing: 3) {
                Text(staffName)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                if !staffRole.isEmpty {
                    Text(staffRole)
                        .font(.system(size: 12))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            }

            Spacer()

            // Duration badge
            Text(durationLabel)
                .font(.caption.weight(.semibold))
                .foregroundColor(.black)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(RSMSTheme.Colors.accentGold)
                .cornerRadius(8)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(RSMSTheme.Colors.accentGold.opacity(0.08), lineWidth: 1)
        )
    }

    private func timeStr(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        return f.string(from: date)
    }

    private var durationLabel: String {
        let mins = Int(shift.endTime.timeIntervalSince(shift.startTime) / 60)
        let h = mins / 60; let m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

// MARK: - Calendar Day View (Extracted to fix compiler timeout)
struct CalendarDayView: View {
    let day: Date
    let selectedDate: Date
    let calendar: Calendar
    let hasShifts: Bool
    let action: () -> Void
    
    private var isSelected: Bool { calendar.isDate(day, inSameDayAs: selectedDate) }
    private var isToday: Bool { calendar.isDateInToday(day) }
    
    private var dayLetter: String {
        let f = DateFormatter(); f.dateFormat = "EEE"
        return String(f.string(from: day).prefix(1))
    }
    
    private var circleFill: Color {
        if isSelected { return RSMSTheme.Colors.accentGold }
        if isToday { return RSMSTheme.Colors.accentGold.opacity(0.25) }
        return Color.clear
    }
    
    private var textColor: Color {
        if isSelected { return .black }
        return RSMSTheme.Colors.textPrimary
    }

    var body: some View {
        VStack(spacing: 4) {
            Text(dayLetter)
                .font(.caption2.weight(.medium))
                .foregroundColor(isSelected ? .black : RSMSTheme.Colors.textSecondary)

            ZStack {
                Circle()
                    .fill(circleFill)
                    .frame(width: 36, height: 36)
                Text("\(calendar.component(.day, from: day))")
                    .font(.subheadline.weight(isSelected || isToday ? .bold : .regular))
                    .foregroundColor(textColor)
            }

            Circle()
                .fill(hasShifts ? RSMSTheme.Colors.accentGold : Color.clear)
                .frame(width: 5, height: 5)
        }
        .frame(maxWidth: .infinity)
        .contentShape(Rectangle())
        .onTapGesture(perform: action)
    }
}

// MARK: - Date Extension (keep only once)
extension Date {
    func startOfWeek(using calendar: Calendar) -> Date {
        calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date ?? self
    }
}
