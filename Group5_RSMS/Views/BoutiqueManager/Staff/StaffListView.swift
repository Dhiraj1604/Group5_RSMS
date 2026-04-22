//
//  StaffListView.swift
//  Group5_RSMS
//
//  Content-only view — no NavigationStack, no toolbar, no secondary filters.
//  BMStaffTab owns navigation and the + button.
//

import SwiftUI

struct StaffListView: View {
    let boutiqueId: UUID
    @ObservedObject var staffVM: StaffViewModel
    @Binding var showAddEmployee: Bool

    var body: some View {
        Group {
            if staffVM.isLoading {
                ProgressView()
                    .tint(RSMSTheme.Colors.accentGold)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if staffVM.employees.isEmpty {
                emptyState
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(staffVM.employees) { employee in
                            NavigationLink(destination:
                                EmployeeSalesDetailView(
                                    employee: employee,
                                    boutiqueId: boutiqueId
                                )
                            ) {
                                StaffDirectoryCard(employee: employee)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "person.3.fill")
                .font(.system(size: 52))
                .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.5))
            Text("No staff found")
                .font(.headline)
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Button {
                showAddEmployee = true
            } label: {
                Label("Add Employee", systemImage: "plus.circle.fill")
                    .font(.headline)
                    .foregroundColor(.black)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(RSMSTheme.Colors.accentGold)
                    .cornerRadius(10)
            }
            Spacer()
        }
    }
}

// MARK: - Staff Directory Card
struct StaffDirectoryCard: View {
    let employee: Employee

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.15))
                    .frame(width: 50, height: 50)
                Text(employee.name.prefix(1).uppercased())
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
            }

            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(.headline)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                Text(employee.role)
                    .font(.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                if let phone = employee.phone, !phone.isEmpty {
                    Text(phone)
                        .font(.caption2)
                        .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.7))
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.4))
                .font(.caption)
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.25), radius: 8, x: 0, y: 4)
    }
}
