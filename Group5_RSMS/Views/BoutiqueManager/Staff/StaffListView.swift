//
//  StaffListView.swift
//  Group5_RSMS
//
//  Premium Staff Directory with alphabetical sections and rich cards.
//

import SwiftUI

struct StaffListView: View {
    let boutiqueId: UUID
    @ObservedObject var staffVM: StaffViewModel
    @Binding var searchText: String
    @Binding var showAddEmployee: Bool

    @State private var employeeToDelete: Employee?
    @State private var showingDeleteAlert = false

    // Group filtered employees alphabetically
    private var groupedEmployees: [(String, [Employee])] {
        let employees = filteredEmployees
        let grouped = Dictionary(grouping: employees) { emp -> String in
            String(emp.name.prefix(1).uppercased())
        }
        return grouped.keys.sorted().map { key in
            (key, grouped[key]!.sorted { $0.name < $1.name })
        }
    }

    var filteredEmployees: [Employee] {
        if searchText.isEmpty {
            return staffVM.employees.sorted { $0.name < $1.name }
        } else {
            return staffVM.employees.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.role.localizedCaseInsensitiveContains(searchText)
            }.sorted { $0.name < $1.name }
        }
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if staffVM.isLoading {
                ProgressView()
                    .tint(RSMSTheme.Colors.accentGold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if staffVM.employees.isEmpty {
                emptyState
            } else if filteredEmployees.isEmpty && !searchText.isEmpty {
                noResultsState
            } else {
                List {
                    // Stats header when not searching
                    if searchText.isEmpty {
                        staffStatsHeader
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                            .listRowSeparator(.hidden)
                    }

                    ForEach(groupedEmployees, id: \.0) { letter, employees in
                        Section(header:
                            Text(letter)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.accentGold)
                                .textCase(nil)
                        ) {
                            ForEach(employees) { employee in
                                ZStack {
                                    NavigationLink(destination:
                                        EmployeeSalesDetailView(employee: employee, boutiqueId: boutiqueId)
                                    ) { EmptyView() }.opacity(0)
                                    StaffDirectoryCard(employee: employee)
                                }
                                .listRowBackground(RSMSTheme.Colors.backgroundElevated)
                                .listRowSeparator(.visible)
                                .listRowSeparatorTint(RSMSTheme.Colors.borderLight.opacity(0.5))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button(role: .destructive) {
                                        employeeToDelete = employee
                                        showingDeleteAlert = true
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
                .scrollContentBackground(.hidden)
                .background(RSMSTheme.Colors.backgroundPrimary)
                .alert("Delete Staff Member", isPresented: $showingDeleteAlert, presenting: employeeToDelete) { emp in
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        Task {
                            await staffVM.deleteEmployee(emp, boutiqueId: boutiqueId)
                            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
                        }
                    }
                } message: { emp in
                    Text("Are you sure you want to permanently delete \(emp.name)? This cannot be undone.")
                }
            }
        }
    }

    // MARK: - Stats Header
    private var staffStatsHeader: some View {
        HStack(spacing: 10) {
            staffStatPill(
                icon: "person.fill.checkmark",
                value: "\(staffVM.employees.filter { $0.isActive ?? true }.count)",
                label: "Active",
                color: RSMSTheme.Colors.success
            )
            staffStatPill(
                icon: "person.fill.xmark",
                value: "\(staffVM.employees.filter { !($0.isActive ?? true) }.count)",
                label: "Inactive",
                color: RSMSTheme.Colors.error
            )
            staffStatPill(
                icon: "person.3.fill",
                value: "\(staffVM.employees.count)",
                label: "Total",
                color: RSMSTheme.Colors.accentGold
            )
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private func staffStatPill(icon: String, value: String, label: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(color)
            Text(value)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
            Text(label)
                .font(.system(size: 11))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RSMSTheme.Colors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }

    // MARK: - Empty States
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.08))
                    .frame(width: 100, height: 100)
                Image(systemName: "person.2.slash.fill")
                    .font(.system(size: 44))
                    .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.5))
            }
            VStack(spacing: 6) {
                Text("No Staff Members")
                    .font(.title3.weight(.bold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text("Add your first team member to get started")
                    .font(.subheadline)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            Button {
                showAddEmployee = true
            } label: {
                Label("Add First Staff Member", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    .background(RSMSTheme.Colors.goldGradient)
                    .cornerRadius(12)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 32)
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 44))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text("No results for \"\(searchText)\"")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Text("Try searching by name or role")
                .font(.caption)
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Staff Directory Card (Premium)
struct StaffDirectoryCard: View {
    let employee: Employee

    private var roleColor: Color {
        switch employee.role {
        case "Store Manager", "Manager": return Color(red: 0.8, green: 0.5, blue: 0.2)
        case "Sales Associate", "Senior Sales": return RSMSTheme.Colors.accentGold
        case "Cashier": return Color.cyan.opacity(0.8)
        case "Visual Merchandiser": return Color.purple.opacity(0.8)
        default: return RSMSTheme.Colors.textSecondary
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            // Avatar with active indicator
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                        .frame(width: 48, height: 48)
                    Text(employee.name.prefix(1).uppercased())
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                }
                // Active dot
                Circle()
                    .fill(employee.isActive ?? true ? RSMSTheme.Colors.success : RSMSTheme.Colors.error)
                    .frame(width: 12, height: 12)
                    .overlay(Circle().stroke(RSMSTheme.Colors.backgroundElevated, lineWidth: 2))
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)

                // Role badge
                Text(employee.role)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(roleColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(roleColor.opacity(0.12))
                    .clipShape(Capsule())
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.4))
                .font(.system(size: 12, weight: .semibold))
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }
}
