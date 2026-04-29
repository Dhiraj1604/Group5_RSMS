//
//  ReportsTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Reports hub with premium card-based navigation.
//  Optimized for iPad with a responsive 2-column grid layout.
//

import SwiftUI

struct ReportsTab: View {

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var columns: [GridItem] {
        horizontalSizeClass == .regular
            ? [GridItem(.flexible(), spacing: 16), GridItem(.flexible(), spacing: 16)]
            : [GridItem(.flexible(), spacing: 16)]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xl) {


                        // Report cards grid
                        LazyVGrid(columns: columns, spacing: 16) {

                            // Revenue Trends
                            NavigationLink(destination: RevenueTrendsView()) {
                                reportCard(
                                    icon: "chart.bar.xaxis.ascending",
                                    title: "Revenue Trends",
                                    subtitle: "Track daily, weekly & monthly revenue with period comparison and export.",
                                    tag: "Financial"
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())

                            // Basket Size Trends
                            NavigationLink(destination: BasketTrendsView()) {
                                reportCard(
                                    icon: "basket.fill",
                                    title: "Basket Trends",
                                    subtitle: "Analyze average items per transaction across stores and categories.",
                                    tag: "Transactions"
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())

                            // Sales Transactions
                            NavigationLink(destination: SalesTransactionsView()) {
                                reportCard(
                                    icon: "receipt.fill",
                                    title: "Sales Transactions",
                                    subtitle: "Browse individual transactions with store, items, amount and full breakdown.",
                                    tag: "Sales"
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())

                            // Audit Logs
                            NavigationLink(destination: AuditLogsView()) {
                                reportCard(
                                    icon: "shield.lefthalf.filled",
                                    title: "Audit Logs",
                                    subtitle: "Complete trail of admin actions — products, tax, offers, stores & users.",
                                    tag: "Compliance"
                                )
                            }
                            .buttonStyle(ScaleButtonStyle())
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.lg)
                    .padding(.bottom, 60)
                }
            }
            .navigationTitle("Reports")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }

    // MARK: - Report Card

    private func reportCard(
        icon: String,
        title: String,
        subtitle: String,
        tag: String
    ) -> some View {
        let accent = RSMSTheme.Colors.accentGold
        return ZStack(alignment: .bottomTrailing) {
            VStack(alignment: .center, spacing: 20) {
                ZStack {
                    Circle()
                        .fill(accent.opacity(0.1))
                        .frame(width: 60, height: 60)
                    Image(systemName: icon)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(accent)
                }
                
                VStack(alignment: .center, spacing: 8) {
                    Text(title)
                        .font(.custom("Helvetica-Bold", size: 22))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Text(subtitle)
                        .font(.custom("Helvetica", size: 14))
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(24)
            .frame(maxWidth: .infinity)
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(accent.opacity(0.6))
                .padding(20)
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.3), radius: 10, y: 5)
    }


}

// MARK: - Scale Button Style

private struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

#Preview { ReportsTab().environment(AppState()) }
