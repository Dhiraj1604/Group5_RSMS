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

                // Adaptive grid of report cards for both iPhone & iPad
                let columns = [
                    GridItem(.adaptive(minimum: 150), spacing: 16)
                ]
                ScrollView(showsIndicators: false) {
                    LazyVGrid(columns: columns, spacing: 16) {
                        // MARK: Revenue Trends
                        NavigationLink(destination: RevenueTrendsView()) {
                            reportCard(
                                icon: "chart.bar.xaxis.ascending",
                                title: "Revenue Trends"
                            )
                        }
                        .buttonStyle(.plain)

                        // MARK: Basket Trends
                        NavigationLink(destination: BasketTrendsView()) {
                            reportCard(
                                icon: "chart.line.uptrend.xyaxis",
                                title: "Basket Size Trends"
                            )
                        }
                        .buttonStyle(.plain)

                        // MARK: Audit Logs
                        NavigationLink(destination: AuditLogsView()) {
                            reportCard(
                                icon: "shield.lefthalf.filled",
                                title: "Audit Logs"
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
    private func reportCard(icon: String, title: String) -> some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 64, height: 64)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(RSMSTheme.Colors.accentGold.opacity(0.2), lineWidth: 0.5)
                    )
                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.goldGradient)
            }

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding(16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .aspectRatio(1, contentMode: .fill) // Enforces perfectly equal height and width squares
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.accentGold.opacity(0.12), lineWidth: 0.5)
        )
    }
}

#Preview { ReportsTab() }
