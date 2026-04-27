//
//  ReportsTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Reports tab with Revenue Trends, Audit Logs, and Basket Trends.
//

import SwiftUI

struct ReportsTab: View {
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {

                        // MARK: Revenue Trends
                        NavigationLink(destination: RevenueTrendsView()) {
                            reportCard(
                                icon: "chart.bar.xaxis.ascending",
                                title: "Revenue Trends",
                                subtitle: "Track daily, weekly & monthly revenue with period comparison"
                            )
                        }
                        .buttonStyle(.plain)

                        // MARK: Basket Trends
                        NavigationLink(destination: BasketTrendsView()) {
                            reportCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Basket Size Trends",
                                subtitle: "Avg items per transaction by week & month"
                            )
                        }
                        .buttonStyle(.plain)

                        // MARK: Audit Logs
                        NavigationLink(destination: AuditLogsView()) {
                            reportCard(
                                icon: "shield.lefthalf.filled",
                                title: "Audit Logs",
                                subtitle: "Track all admin actions and changes"
                            )
                        }
                        .buttonStyle(.plain)
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

    // MARK: - Reusable Card
    private func reportCard(icon: String, title: String, subtitle: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 48, height: 48)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(RSMSTheme.Colors.accentGold.opacity(0.2), lineWidth: 0.5)
                    )
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(RSMSTheme.Colors.goldGradient)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                Text(subtitle)
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
    }
}

#Preview { ReportsTab() }
