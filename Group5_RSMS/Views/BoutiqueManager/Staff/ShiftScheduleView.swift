//
//  ShiftScheduleView.swift
//  Group5_RSMS
//

import SwiftUI

struct ShiftScheduleView: View {
    @StateObject private var shiftVM = ShiftViewModel()
    @StateObject private var staffVM = StaffViewModel()

    let boutiqueId: UUID

    @State private var selectedDate = Date()
    @State private var weekOffset = 0          // which week we're viewing
    @State private var showingAddShift = false
    @State private var shiftToEdit: Shift?

    private let calendar = Calendar.current

    // MARK: - Week computation
    private var weekDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        // Start of current ISO week + offset
        let startOfWeek = calendar.date(
            byAdding: .weekOfYear,
            value: weekOffset,
            to: today.startOfWeek(using: calendar)
        ) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private var weekRangeLabel: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let fmt = DateFormatter()
        fmt.dateFormat = "d MMM"
        let yearFmt = DateFormatter()
        yearFmt.dateFormat = "d MMM yyyy"
        return "\(fmt.string(from: first)) – \(yearFmt.string(from: last))"
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // ── Week Strip ──────────────────────────────────────
                VStack(spacing: 0) {
                    // Month navigation row
                    HStack {
                        Button { weekOffset -= 1 } label: {
                            Image(systemName: "chevron.left")
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                                .padding(8)
                        }
                        .disabled(weekOffset == 0)
                        .opacity(weekOffset == 0 ? 0.3 : 1)

                        Spacer()
                        Text(weekRangeLabel)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                        Spacer()

                        Button { weekOffset += 1 } label: {
                            Image(systemName: "chevron.right")
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                                .padding(8)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.top, 12)

                    // Day bubbles
                    HStack(spacing: 6) {
                        ForEach(weekDays, id: \.self) { day in
                            let isSelected = calendar.isDate(day, inSameDayAs: selectedDate)
                            let isToday   = calendar.isDateInToday(day)
                            let isPast    = day < calendar.startOfDay(for: Date())
                            let hasShifts = !shiftVM.shiftsForDay(day).isEmpty

                            VStack(spacing: 4) {
                                Text(dayLetter(day))
                                    .font(.caption2.weight(.medium))
                                    .foregroundColor(isSelected ? .black : RSMSTheme.Colors.textSecondary)

                                ZStack {
                                    Circle()
                                        .fill(
                                            isSelected
                                            ? RSMSTheme.Colors.accentGold
                                            : isToday
                                                ? RSMSTheme.Colors.accentGold.opacity(0.25)
                                                : Color.clear
                                        )
                                        .frame(width: 36, height: 36)

                                    Text("\(calendar.component(.day, from: day))")
                                        .font(.subheadline.weight(isSelected || isToday ? .bold : .regular))
                                        .foregroundColor(
                                            isSelected ? .black :
                                            isPast ? RSMSTheme.Colors.textSecondary.opacity(0.4) :
                                            RSMSTheme.Colors.textPrimary
                                        )
                                }

                                // Dot indicator
                                Circle()
                                    .fill(hasShifts ? RSMSTheme.Colors.accentGold : Color.clear)
                                    .frame(width: 5, height: 5)
                            }
                            .frame(maxWidth: .infinity)
                            .onTapGesture {
                                guard !isPast else { return }
                                selectedDate = day
                            }
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                }
                .background(RSMSTheme.Colors.backgroundDeep)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 4)

                // ── Daily Header ─────────────────────────────────────
                let dailyShifts = shiftVM.shiftsForDay(selectedDate)

                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formattedFullDate(selectedDate))
                            .font(.title3.weight(.bold))
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                        Text(dailyShifts.isEmpty ? "No shifts scheduled" : "\(dailyShifts.count) shift\(dailyShifts.count == 1 ? "" : "s") scheduled")
                            .font(.caption)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)

                Divider()
                    .background(RSMSTheme.Colors.textSecondary.opacity(0.2))
                    .padding(.horizontal, 16)

                // ── Shift List ────────────────────────────────────────
                if shiftVM.isLoading {
                    Spacer()
                    ProgressView().tint(RSMSTheme.Colors.accentGold)
                    Spacer()
                } else if dailyShifts.isEmpty {
                    Spacer()
                    VStack(spacing: 16) {
                        Image(systemName: "moon.zzz.fill")
                            .font(.system(size: 52))
                            .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.35))
                        Text("No shifts on this day")
                            .font(.headline)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        Text("Tap + to schedule the first shift")
                            .font(.caption)
                            .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
                    }
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 14) {
                            ForEach(dailyShifts) { shift in
                                ShiftCard(
                                    shift: shift,
                                    staffName: employeeName(for: shift.employeeId),
                                    staffRole: staffRole(for: shift.employeeId),
                                    isLowCoverage: checkLowCoverage(for: shift, dailyShifts: dailyShifts)
                                )
                                .onTapGesture { shiftToEdit = shift }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .padding(.bottom, 100) // space for FAB
                    }
                }
            }

        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingAddShift = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .sheet(isPresented: $showingAddShift) {
            ManageShiftView(shiftVM: shiftVM, boutiqueId: boutiqueId, employees: staffVM.employees, existingShift: nil, selectedDate: selectedDate)
        }
        .sheet(item: $shiftToEdit) { shift in
            ManageShiftView(shiftVM: shiftVM, boutiqueId: boutiqueId, employees: staffVM.employees, existingShift: shift, selectedDate: selectedDate)
        }
        .task {
            await shiftVM.fetchShifts(boutiqueId: boutiqueId)
            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
        }
        .onChange(of: showingAddShift) { _, isShowing in
            if !isShowing { Task { await shiftVM.fetchShifts(boutiqueId: boutiqueId) } }
        }
        .onChange(of: shiftToEdit?.id) { _, newId in
            if newId == nil { Task { await shiftVM.fetchShifts(boutiqueId: boutiqueId) } }
        }
    }

    // MARK: - Helpers
    private func dayLetter(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return String(f.string(from: date).prefix(1))
    }
    private func formattedFullDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, d MMMM"; return f.string(from: date)
    }
    private func employeeName(for id: UUID) -> String {
        staffVM.employees.first(where: { $0.id == id })?.name ?? "Unknown"
    }
    private func staffRole(for id: UUID) -> String {
        staffVM.employees.first(where: { $0.id == id })?.role ?? ""
    }
    private func checkLowCoverage(for shift: Shift, dailyShifts: [Shift]) -> Bool {
        let overlapping = dailyShifts.filter { shift.startTime < $0.endTime && shift.endTime > $0.startTime }
        return Set(overlapping.map { $0.employeeId }).count < shiftVM.minimumCoverageThreshold
    }
}

// MARK: - Date Extension
extension Date {
    func startOfWeek(using calendar: Calendar) -> Date {
        calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date ?? self
    }
}

// MARK: - Shift Card
struct ShiftCard: View {
    let shift: Shift
    let staffName: String
    let staffRole: String
    let isLowCoverage: Bool

    var body: some View {
        HStack(spacing: 16) {
            // Left time bar
            VStack(spacing: 4) {
                Text(timeString(from: shift.startTime))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                Rectangle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.4))
                    .frame(width: 2)
                Text(timeString(from: shift.endTime))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
            .frame(width: 52)

            // Card body
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    // Avatar circle
                    ZStack {
                        Circle()
                            .fill(RSMSTheme.Colors.accentGold.opacity(0.2))
                            .frame(width: 38, height: 38)
                        Text(staffName.prefix(1).uppercased())
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(staffName)
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                        if !staffRole.isEmpty {
                            Text(staffRole)
                                .font(.caption)
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

                if isLowCoverage {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .font(.caption)
                        Text("Low coverage — needs more staff")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(6)
                }
            }
            .padding(.vertical, 14)
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(RSMSTheme.Colors.backgroundDeep)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(isLowCoverage ? Color.orange.opacity(0.5) : RSMSTheme.Colors.accentGold.opacity(0.08), lineWidth: 1)
                    )
            )

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.5))
        }
    }

    private var durationLabel: String {
        let mins = Int(shift.endTime.timeIntervalSince(shift.startTime) / 60)
        let h = mins / 60, m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }

    private func timeString(from date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short; return f.string(from: date)
    }
}
