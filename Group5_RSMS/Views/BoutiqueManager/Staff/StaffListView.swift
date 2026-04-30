//
//  StaffListView.swift
//  Group5_RSMS
//

import SwiftUI

struct StaffListView: View {
    let boutiqueId: UUID
    @ObservedObject var staffVM: StaffViewModel
    @Binding var searchText: String
    @Binding var showAddEmployee: Bool
    
    @State private var employeeToDelete: Employee?
    @State private var showingDeleteAlert = false

    var filteredEmployees: [Employee] {
        if searchText.isEmpty {
            return staffVM.employees
        } else {
            return staffVM.employees.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.role.localizedCaseInsensitiveContains(searchText)
            }
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
                    ForEach(filteredEmployees) { employee in
                        ZStack {
                            NavigationLink(destination:
                                EmployeeSalesDetailView(
                                    employee: employee,
                                    boutiqueId: boutiqueId
                                )
                            ) {
                                EmptyView()
                            }
                            .opacity(0)
                            
                            StaffDirectoryCard(employee: employee)
                        }
                        .listRowBackground(RSMSTheme.Colors.backgroundDeep)
                        .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                        .listRowSeparator(.visible)
                        .listRowSeparatorTint(RSMSTheme.Colors.border.opacity(0.3))
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
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(RSMSTheme.Colors.backgroundDeep)
                .alert("Delete Staff", isPresented: $showingDeleteAlert, presenting: employeeToDelete) { emp in
                    Button("Cancel", role: .cancel) { }
                    Button("Delete", role: .destructive) {
                        Task {
                            await staffVM.deleteEmployee(emp, boutiqueId: boutiqueId)
                            await staffVM.fetchEmployees(boutiqueId: boutiqueId)
                        }
                    }
                } message: { emp in
                    Text("Are you sure you want to delete \(emp.name)? This action cannot be undone.")
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.2.slash.fill")
                .font(.system(size: 60))
                .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.3))
            Text("No staff found in directory")
                .font(.headline)
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Button {
                showAddEmployee = true
            } label: {
                Label("Add Staff Member", systemImage: "plus")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(RSMSTheme.Colors.accentGold)
                    .cornerRadius(12)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var noResultsState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.text.rectangle")
                .font(.system(size: 44))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text("No staff match \"\(searchText)\"")
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Staff Directory Card
struct StaffDirectoryCard: View {
    let employee: Employee

    var body: some View {
        HStack(spacing: 16) {
            // Avatar
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.1))
                Text(employee.name.prefix(1).uppercased())
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }
            .frame(width: 44, height: 44)

            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(employee.name)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                
                HStack(spacing: 4) {
                    Text(employee.role)
                        .font(.system(size: 14))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                    
                    if !(employee.isActive ?? true) {
                        Text("• Inactive")
                            .font(.system(size: 12))
                            .foregroundColor(.red.opacity(0.8))
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.3))
                .font(.system(size: 14, weight: .semibold))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .contentShape(Rectangle())
    }
}
