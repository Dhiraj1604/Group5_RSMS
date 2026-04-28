//
//  ShiftScheduleView.swift
//  Group5_RSMS
//
//  Premium Shift Schedule View - Native iPadOS style.
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

    private let calendar = Calendar.current

    private var weekDays: [Date] {
        let today = calendar.startOfDay(for: Date())
        let startOfWeek = calendar.date(
            byAdding: .weekOfYear,
            value: weekOffset,
            to: today.startOfWeek(using: calendar)
        ) ?? today
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: $0, to: startOfWeek) }
    }

    private var weekRangeLabel: String {
        guard let first = weekDays.first, let last = weekDays.last else { return "" }
        let fmt = DateFormatter(); fmt.dateFormat = "MMM d"
        let yearFmt = DateFormatter(); yearFmt.dateFormat = "MMM d, yyyy"
        return "\(fmt.string(from: first)) – \(yearFmt.string(from: last))"
    }

    var body: some View {
        VStack(spacing: 0) {
            // MARK: - Custom Week Picker
            CustomWeekPicker(
                selectedDate: $selectedDate,
                weekOffset: $weekOffset,
                weekDays: weekDays,
                weekRangeLabel: weekRangeLabel,
                hasShifts: { day in !shiftVM.shiftsForDay(day).isEmpty }
            )
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 8)

            let dailyShifts = shiftVM.shiftsForDay(selectedDate)

            // MARK: - Daily Header
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(formattedFullDate(selectedDate))
                        .font(.title2.bold())
                        .foregroundColor(.primary)
                    
                    HStack(spacing: 6) {
                        Circle()
                            .fill(dailyShifts.isEmpty ? Color.secondary.opacity(0.3) : Color.accentColor)
                            .frame(width: 8, height: 8)
                        Text(dailyShifts.isEmpty ? "No shifts scheduled" : "\(dailyShifts.count) \(dailyShifts.count == 1 ? "Shift" : "Shifts")")
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.secondary)
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 16)

            // MARK: - Shifts Content
            if shiftVM.isLoading {
                Spacer()
                ProgressView().tint(.accentColor)
                Spacer()
            } else if dailyShifts.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: 16) {
                        ForEach(dailyShifts) { shift in
                            PremiumShiftCard(
                                shift: shift,
                                staffName: employeeName(for: shift.employeeId),
                                staffRole: staffRole(for: shift.employeeId),
                                isLowCoverage: checkLowCoverage(for: shift, dailyShifts: dailyShifts),
                                isAbsent: isAbsent(for: shift.employeeId)
                            )
                            .onTapGesture { shiftToEdit = shift }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground).ignoresSafeArea())
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
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 100, height: 100)
                Image(systemName: "calendar.badge.clock")
                    .font(.custom("Helvetica", size: 40))
                    .foregroundColor(.accentColor.opacity(0.6))
            }
            VStack(spacing: 8) {
                Text("Quiet Day")
                    .font(.headline)
                    .foregroundColor(.primary)
                Text("No shifts have been assigned for this date.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 40)
            
            Button {
                showingAddShift = true
            } label: {
                Text("Assign Shift")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(Color.accentColor)
                    .clipShape(Capsule())
            }
            Spacer()
        }
    }

    private func formattedFullDate(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMMM d"; return f.string(from: date)
    }
    private func employeeName(for id: UUID) -> String {
        staffVM.employees.first(where: { $0.id == id })?.name ?? "Unknown"
    }
    private func staffRole(for id: UUID) -> String {
        staffVM.employees.first(where: { $0.id == id })?.role ?? ""
    }
    private func isAbsent(for id: UUID) -> Bool {
        return staffVM.employees.first(where: { $0.id == id })?.isActive == false
    }
    private func checkLowCoverage(for shift: Shift, dailyShifts: [Shift]) -> Bool {
        let overlapping = dailyShifts.filter { shift.startTime < $0.endTime && shift.endTime > $0.startTime }
        return Set(overlapping.map { $0.employeeId }).count < shiftVM.minimumCoverageThreshold
    }
}

// MARK: - Custom Week Picker
struct CustomWeekPicker: View {
    @Binding var selectedDate: Date
    @Binding var weekOffset: Int
    let weekDays: [Date]
    let weekRangeLabel: String
    let hasShifts: (Date) -> Bool
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text(weekRangeLabel)
                    .font(.custom("Helvetica", size: 18))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Spacer()
                HStack(spacing: 12) {
                    Button { weekOffset -= 1 } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .disabled(weekOffset == 0)
                    .opacity(weekOffset == 0 ? 0.3 : 1)
                    
                    Button { weekOffset += 1 } label: {
                        Image(systemName: "chevron.right.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                    }
                }
                .foregroundColor(.accentColor)
            }
            .padding(.horizontal, 4)
            
            HStack(spacing: 0) {
                ForEach(weekDays, id: \.self) { day in
                    let isSelected = Calendar.current.isDate(day, inSameDayAs: selectedDate)
                    let isToday = Calendar.current.isDateInToday(day)
                    let isPast = day < Calendar.current.startOfDay(for: Date())
                    
                    Button {
                        if !isPast {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedDate = day
                            }
                        }
                    } label: {
                        VStack(spacing: 8) {
                            Text(dayLetter(day))
                                .font(.custom("Helvetica", size: 10))
                                .fontWeight(.bold)
                                .foregroundColor(isSelected ? .accentColor : .secondary)
                            
                            ZStack {
                                if isSelected {
                                    Circle()
                                        .fill(Color.accentColor)
                                        .frame(width: 40, height: 40)
                                        .shadow(color: Color.accentColor.opacity(0.3), radius: 6, x: 0, y: 3)
                                } else if isToday {
                                    Circle()
                                        .stroke(Color.accentColor, lineWidth: 2)
                                        .frame(width: 40, height: 40)
                                }
                                
                                Text("\(Calendar.current.component(.day, from: day))")
                                    .font(.custom("Helvetica", size: 16))
                                    .fontWeight(.bold)
                                    .foregroundColor(isSelected ? .white : (isPast ? .secondary.opacity(0.3) : .primary))
                            }
                            
                            Circle()
                                .fill(hasShifts(day) ? (isSelected ? .white : Color.accentColor) : Color.clear)
                                .frame(width: 4, height: 4)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.plain)
                    .disabled(isPast)
                }
            }
        }
        .padding(20)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 6)
    }
    
    private func dayLetter(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE"; return f.string(from: date).uppercased().prefix(1).description
    }
}

// MARK: - Premium Shift Card
struct PremiumShiftCard: View {
    let shift: Shift
    let staffName: String
    let staffRole: String
    let isLowCoverage: Bool
    let isAbsent: Bool

    var body: some View {
        HStack(spacing: 0) {
            // Timeline Bar
            VStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                Rectangle()
                    .fill(statusColor.opacity(0.2))
                    .frame(width: 2)
                Circle()
                    .stroke(statusColor, lineWidth: 2)
                    .frame(width: 8, height: 8)
            }
            .frame(width: 32)
            .padding(.leading, 12)

            // Main Card
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(staffName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(staffRole)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(timeRangeString)
                            .font(.custom("Helvetica", size: 14))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        Text(durationLabel)
                            .font(.caption2.weight(.bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(statusColor)
                            .clipShape(Capsule())
                    }
                }

                if isAbsent || isLowCoverage {
                    HStack(spacing: 8) {
                        if isAbsent {
                            Label("Absent", systemImage: "person.slash.fill")
                                .font(.caption.bold())
                                .foregroundColor(.red)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.red.opacity(0.1))
                                .clipShape(Capsule())
                        }
                        
                        if isLowCoverage {
                            Label("Low Coverage", systemImage: "exclamationmark.triangle.fill")
                                .font(.caption.bold())
                                .foregroundColor(.orange)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Color.orange.opacity(0.1))
                                .clipShape(Capsule())
                        }
                    }
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .clipShape(ShiftCardShape())
            .overlay(
                ShiftCardShape()
                    .stroke(statusColor.opacity(0.15), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 4)
            .padding(.trailing, 4)
        }
    }

    private var statusColor: Color {
        if isAbsent { return .red }
        if isLowCoverage { return .orange }
        return .accentColor
    }

    private var timeRangeString: String {
        let f = DateFormatter(); f.timeStyle = .short
        return "\(f.string(from: shift.startTime)) - \(f.string(from: shift.endTime))"
    }

    private var durationLabel: String {
        let mins = Int(shift.endTime.timeIntervalSince(shift.startTime) / 60)
        let h = mins / 60, m = mins % 60
        return m == 0 ? "\(h)h" : "\(h)h \(m)m"
    }
}

// MARK: - Shift Card Shape
struct ShiftCardShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let r: CGFloat = 16
        let notch: CGFloat = 10
        
        path.move(to: CGPoint(x: r, y: 0))
        path.addLine(to: CGPoint(x: rect.width - r, y: 0))
        path.addArc(center: CGPoint(x: rect.width - r, y: r), radius: r, startAngle: .degrees(270), endAngle: .degrees(0), clockwise: false)
        
        path.addLine(to: CGPoint(x: rect.width, y: rect.height - r))
        path.addArc(center: CGPoint(x: rect.width - r, y: rect.height - r), radius: r, startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false)
        
        path.addLine(to: CGPoint(x: r, y: rect.height))
        path.addArc(center: CGPoint(x: r, y: rect.height - r), radius: r, startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false)
        
        // Notch on the left for the timeline connection
        path.addLine(to: CGPoint(x: 0, y: rect.height * 0.5 + notch))
        path.addArc(center: CGPoint(x: 0, y: rect.height * 0.5), radius: notch, startAngle: .degrees(90), endAngle: .degrees(-90), clockwise: true)
        
        path.addLine(to: CGPoint(x: 0, y: r))
        path.addArc(center: CGPoint(x: r, y: r), radius: r, startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false)
        
        return path
    }
}

// MARK: - Date Extension
extension Date {
    func startOfWeek(using calendar: Calendar) -> Date {
        calendar.dateComponents([.calendar, .yearForWeekOfYear, .weekOfYear], from: self).date ?? self
    }
}
