//
//  ReportsTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Reports tab with Audit Logs.
//

import SwiftUI

struct ReportsTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {

                        // MARK: Audit Logs Entry Card
                        NavigationLink(destination: AuditLogsView()) {
                            HStack(spacing: 14) {
                                // Icon
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                                        .frame(width: 48, height: 48)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(RSMSTheme.Colors.accentGold.opacity(0.2), lineWidth: 0.5)
                                        )
                                    Image(systemName: "shield.lefthalf.filled")
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(RSMSTheme.Colors.goldGradient)
                                }

                                // Text
                                VStack(alignment: .leading, spacing: 3) {
                                    Text("Audit Logs")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.white)
                                    Text("Track all admin actions and changes")
                                        .font(.system(size: 12))
                                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                                }

                                Spacer()

                                Image(systemName: "chevron.right")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(RSMSTheme.Colors.accentGold.opacity(0.6))
                            }
                            .padding(16)
                            .background(RSMSTheme.Colors.backgroundDeep)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(RSMSTheme.Colors.accentGold.opacity(0.12), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                        }
                        .buttonStyle(.plain)

                        // MARK: Coming Soon Placeholder
                        ComingSoonView(
                            title: "More Reports",
                            icon: "chart.bar.fill",
                            description: "Basket trends, category performance, transaction history, and cross-store comparisons — coming soon."
                        )
                        .frame(minHeight: 300)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

#Preview { ReportsTab() }
