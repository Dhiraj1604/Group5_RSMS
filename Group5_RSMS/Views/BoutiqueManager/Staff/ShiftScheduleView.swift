//
//  ShiftScheduleView.swift
//  Group5_RSMS
//
//  🔴 LIVE ROSTER: Who's on shift RIGHT NOW — the hero feature.
//  Weekly calendar strip below, then a filtered daily list.
//

import SwiftUI
import Combine

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

    // Live clock for countdown timers
    @State private var now = Date()
    private let timer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()

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

    // ── Shifts for selected day ─────────────────────────────────────────
    private var dailyShifts: [Shift] {
        shiftVM.shiftsForDay(selectedDate).sorted { $0.startTime < $1.startTime }
    }

    // ── LIVE: Who is on shift right now ────────────────────────────────
    private var activeShiftsNow: [Shift] {
        shiftVM.shifts.filter { shift in
            shift.startTime <= now && shift.endTime >= now
        }.sorted { $0.startTime < $1.startTime }
    }

    // Grouped by time slot
    struct ShiftGroup: Identifiable {
        let id = UUID()
        let timeLabel: String
        let shifts: [Shift]
    }

    private var groupedDailyShifts: [ShiftGroup] {
        let grouped = Dictionary(grouping: dailyShifts) { shift in
            let f = DateFormatter(); f.dateFormat = "HH:mm"
            return "\(f.string(from: shift.startTime)) – \(f.string(from: shift.endTime))"
        }
        return grouped.map { ShiftGroup(timeLabel: $0.key, shifts: $0.value) }
            .sorted { $0.timeLabel < $1.timeLabel }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {

                // ── 🔴 LIVE ROSTER PANEL ─────────────────────────────────
                liveRosterPanel
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 8)

                // ── Week strip ──────────────────────────────────────────
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
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal, 16).padding(.bottom, 4)

                // ── Day header ──────────────────────────────────────────
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

                // ── Shift list ──────────────────────────────────────────
                if shiftVM.isLoading {
                    ProgressView().tint(RSMSTheme.Colors.accentGold).padding(40)
                } else if groupedDailyShifts.isEmpty {
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
                    .padding(40)
                } else {
                    LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedDailyShifts) { group in
                            Section {
                                ForEach(group.shifts) { shift in
                                    SimpleShiftRow(
                                        shift: shift,
                                        staffName: employeeName(for: shift.employeeId),
                                        staffRole: staffRole(for: shift.employeeId)
                                    )
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 4)
                                    .onTapGesture { shiftToEdit = shift }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) { confirmDelete(shift) } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                }
                            } header: {
                                HStack {
                                    Image(systemName: "clock.fill")
                                        .font(.caption)
                                    Text(group.timeLabel)
                                        .font(.system(size: 13, weight: .bold))
                                    Spacer()
                                    Text("\(group.shifts.count) staff")
                                        .font(.system(size: 11, weight: .medium))
                                        .padding(.horizontal, 8).padding(.vertical, 3)
                                        .background(RSMSTheme.Colors.accentGold.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                                .padding(.horizontal, 20).padding(.vertical, 10)
                                .background(RSMSTheme.Colors.backgroundPrimary)
                                .textCase(nil)
                            }
                        }
                    }
                    .padding(.bottom, 24)
                }
            }
        }
        .background(RSMSTheme.Colors.backgroundPrimary)
        // ── Sheets ──────────────────────────────────────────────────────
        .sheet(isPresented: $showingAddShift) {
            ManageShiftView(shiftVM: shiftVM, boutiqueId: boutiqueId, employees: staffVM.employees, existingShift: nil, selectedDate: selectedDate)
        }
        .sheet(item: $shiftToEdit) { shift in
            ManageShiftView(shiftVM: shiftVM, boutiqueId: boutiqueId, employees: staffVM.employees, existingShift: shift, selectedDate: selectedDate)
        }
        .task {
            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
            await shiftVM.fetchShifts(boutiqueId: boutiqueId)
        }
        .onChange(of: showingAddShift) { _, isShowing in
            if !isShowing { Task { await shiftVM.fetchShifts(boutiqueId: boutiqueId) } }
        }
        .onChange(of: shiftToEdit?.id) { _, newVal in
            if newVal == nil { Task { await shiftVM.fetchShifts(boutiqueId: boutiqueId) } }
        }
        .onReceive(timer) { t in now = t }
        .alert("Delete Shift", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) { shiftToDelete = nil }
            Button("Delete", role: .destructive, action: executeDelete)
        } message: {
            Text(deleteAlertMessage)
        }
    }

    // MARK: - 🔴 Live Roster Panel
    @ViewBuilder
    private var liveRosterPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header
            HStack(spacing: 8) {
                // Pulsing dot
                ZStack {
                    Circle()
                        .fill(RSMSTheme.Colors.success.opacity(0.3))
                        .frame(width: 16, height: 16)
                    Circle()
                        .fill(RSMSTheme.Colors.success)
                        .frame(width: 9, height: 9)
                }
                Text("On Shift Now")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Spacer()
                Text(now.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 12, weight: .medium, design: .monospaced))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
            }

            if activeShiftsNow.isEmpty {
                // Nobody on shift
                HStack(spacing: 10) {
                    Image(systemName: "moon.stars.fill")
                        .font(.system(size: 22))
                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("No active shifts")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        Text("All staff are off duty right now")
                            .font(.caption)
                            .foregroundColor(RSMSTheme.Colors.textTertiary)
                    }
                }
                .padding(.vertical, 4)
            } else {
                // Scrollable live chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(activeShiftsNow) { shift in
                            LiveStaffChip(
                                name: employeeName(for: shift.employeeId),
                                role: staffRole(for: shift.employeeId),
                                endTime: shift.endTime,
                                now: now
                            )
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            LinearGradient(
                colors: [
                    RSMSTheme.Colors.backgroundDeep,
                    RSMSTheme.Colors.success.opacity(activeShiftsNow.isEmpty ? 0 : 0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(
                    activeShiftsNow.isEmpty
                        ? RSMSTheme.Colors.borderLight
                        : RSMSTheme.Colors.success.opacity(0.35),
                    lineWidth: 1
                )
        )
    }

    // MARK: - Helpers
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

// MARK: - Live Staff Chip (pulsing, shows countdown)
struct LiveStaffChip: View {
    let name: String
    let role: String
    let endTime: Date
    let now: Date

    private var minutesLeft: Int {
        max(0, Int(endTime.timeIntervalSince(now) / 60))
    }

    private var countdownText: String {
        let h = minutesLeft / 60
        let m = minutesLeft % 60
        if h > 0 { return "ends in \(h)h \(m)m" }
        return "ends in \(m)m"
    }

    var body: some View {
        HStack(spacing: 8) {
            // Avatar
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.success.opacity(0.15))
                    .frame(width: 36, height: 36)
                Text(name.prefix(1).uppercased())
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.success)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(name.components(separatedBy: " ").first ?? name)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(countdownText)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(minutesLeft < 60 ? RSMSTheme.Colors.warning : RSMSTheme.Colors.success)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RSMSTheme.Colors.backgroundPrimary)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(RSMSTheme.Colors.success.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Simple Shift Row
struct SimpleShiftRow: View {
    let shift: Shift
    let staffName: String
    let staffRole: String

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 44, height: 44)
                Text(staffName.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }

            // Name + role
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
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(RSMSTheme.Colors.accentGold)
                .cornerRadius(12)
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

    private var durationLabel: String {
        let mins = Int(shift.endTime.timeIntervalSince(shift.startTime) / 60)
        let h = mins / 60; let m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

// MARK: - Calendar Day View
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
                    .foregroundColor(isSelected ? .black : RSMSTheme.Colors.textPrimary)
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

// MARK: - Date Extension
extension Date {
    func startOfWeek(using calendar: Calendar) -> Date {
        calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date ?? self
    }
}
