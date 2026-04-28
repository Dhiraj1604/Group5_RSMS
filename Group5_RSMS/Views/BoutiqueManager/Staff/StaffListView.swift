//
//  StaffListView.swift
//  Group5_RSMS
//
//  Premium Staff Card Redesign - iOS 26 Liquid Glass & Segmented Cards.
//

import SwiftUI

struct StaffListView: View {
    let boutiqueId: UUID
    @ObservedObject var staffVM: StaffViewModel
    @Binding var showAddEmployee: Bool

    private var sortedStaff: [Employee] {
        staffVM.employeesSortedBySales()
    }

    var body: some View {
        Group {
            if staffVM.isLoading {
                ProgressView()
                    .tint(.accentColor)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if staffVM.employees.isEmpty {
                emptyState
            } else {
                ScrollView(showsIndicators: false) {
                    let columns = [
                        GridItem(.flexible(), spacing: 32),
                        GridItem(.flexible(), spacing: 32)
                    ]
                    
                    LazyVGrid(columns: columns, spacing: 40) {
                        ForEach(Array(sortedStaff.enumerated()), id: \.element.id) { index, employee in
                            NavigationLink(destination:
                                EmployeeSalesDetailView(
                                    employee: employee,
                                    boutiqueId: boutiqueId
                                )
                            ) {
                                PremiumStaffCard(
                                    rank: index + 1,
                                    employee: employee,
                                    sales: staffVM.totalSales(for: employee.id),
                                    transactions: staffVM.transactionCount(for: employee.id),
                                    avgValue: staffVM.averageOrderValue(for: employee.id)
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(32)
                    .padding(.bottom, 60)
                }
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 32) {
            Spacer()
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 140, height: 140)
                Image(systemName: "person.3.fill")
                    .font(.custom("Helvetica", size: 60))
                    .foregroundColor(.secondary.opacity(0.3))
            }
            
            VStack(spacing: 12) {
                Text("No Team Intelligence")
                    .font(.custom("Helvetica", size: 28))
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                Text("Connect your boutique specialists to begin tracking performance analytics.")
                    .font(.custom("Helvetica", size: 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 60)
            }
            
            Button {
                showAddEmployee = true
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "plus")
                        .font(.headline.weight(.bold))
                    Text("Add Specialist")
                        .font(.custom("Helvetica", size: 20))
                        .fontWeight(.bold)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 48)
                .padding(.vertical, 20)
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 24))
                .shadow(color: Color.accentColor.opacity(0.3), radius: 15, x: 0, y: 8)
            }
            Spacer()
        }
    }
}

// MARK: - Premium Staff Card (Segmented)
struct PremiumStaffCard: View {
    let rank: Int
    let employee: Employee
    let sales: Double
    let transactions: Int
    let avgValue: Double

    var body: some View {
        VStack(spacing: 0) {
            // Top Section (Visuals)
            ZStack(alignment: .topTrailing) {
                rankColor.opacity(0.12)
                
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 100, height: 100)
                            .overlay(Circle().stroke(rankColor.opacity(0.3), lineWidth: 1))
                        
                        Text(employee.name.prefix(1).uppercased())
                            .font(.custom("Helvetica", size: 48))
                            .fontWeight(.bold)
                            .foregroundColor(rankColor)
                        
                        if rank <= 3 {
                            Image(systemName: "crown.fill")
                                .font(.custom("Helvetica", size: 18))
                                .foregroundColor(rankColor)
                                .offset(y: -55)
                        }
                    }
                    .padding(.top, 24)
                    
                    VStack(spacing: 6) {
                        Text(employee.name)
                            .font(.custom("Helvetica", size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        
                        Text(employee.role.uppercased())
                            .font(.custom("Helvetica", size: 11))
                            .fontWeight(.black)
                            .tracking(2)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 24)
                
                // Rank Chip
                Text("#\(rank)")
                    .font(.custom("Helvetica", size: 14))
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(rankColor)
                    .clipShape(Capsule())
                    .padding(16)
                    .shadow(color: rankColor.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            
            // Divider with Notch
            ZStack {
                Divider().opacity(0.5)
                HStack {
                    Circle().fill(Color(UIColor.systemGroupedBackground)).frame(width: 20, height: 20).offset(x: -10)
                    Spacer()
                    Circle().fill(Color(UIColor.systemGroupedBackground)).frame(width: 20, height: 20).offset(x: 10)
                }
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))

            // Bottom Section (Data)
            VStack(spacing: 20) {
                HStack(alignment: .center) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("TOTAL REVENUE")
                            .font(.custom("Helvetica", size: 10))
                            .fontWeight(.black)
                            .tracking(1)
                            .foregroundColor(.secondary)
                        Text("₹\(Int(sales).formatted())")
                            .font(.custom("Helvetica", size: 28))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                    
                    ZStack {
                        Circle()
                            .fill(.ultraThinMaterial)
                            .frame(width: 48, height: 48)
                        Image(systemName: "chevron.right")
                            .font(.custom("Helvetica", size: 16))
                            .fontWeight(.bold)
                            .foregroundColor(rankColor)
                    }
                }
                
                HStack(spacing: 20) {
                    MetricMiniLabel(label: "TRANS.", value: "\(transactions)")
                    MetricMiniLabel(label: "AVG. VALUE", value: "₹\(Int(avgValue).formatted())")
                }
            }
            .padding(24)
            .background(Color(UIColor.secondarySystemGroupedBackground))
        }
        .clipShape(RoundedRectangle(cornerRadius: 32))
        .overlay(RoundedRectangle(cornerRadius: 32).stroke(.white.opacity(0.1), lineWidth: 0.5))
        .shadow(color: Color.black.opacity(0.08), radius: 20, x: 0, y: 10)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 0.85, green: 0.65, blue: 0.13) // Gold
        case 2: return Color(red: 0.65, green: 0.65, blue: 0.65) // Silver
        case 3: return Color(red: 0.70, green: 0.45, blue: 0.25) // Bronze
        default: return .accentColor
        }
    }
}

struct MetricMiniLabel: View {
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.custom("Helvetica", size: 8))
                .fontWeight(.black)
                .foregroundColor(.secondary)
            Text(value)
                .font(.custom("Helvetica", size: 14))
                .fontWeight(.bold)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.03))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
