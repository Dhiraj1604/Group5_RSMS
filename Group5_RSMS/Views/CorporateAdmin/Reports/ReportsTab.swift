//
//  ReportsTab.swift
//  Group5_RSMS
//
//  Corporate Admin — Reports hub with premium card-based navigation.
//  Optimized for iPad with a responsive grid layout.
//

import SwiftUI

struct ReportsTab: View {

    // Adaptive grid: 2 columns on iPad, 1 on iPhone
    private let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xl) {

                        // Header tagline
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Analytics & Insights")
                                .font(.system(size: 14, weight: .semibold))
                                .tracking(1.2)
                                .foregroundStyle(RSMSTheme.Colors.accentGold)
                            Text("Tap a report to dive into detailed analytics")
                                .font(.system(size: 12))
                                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        }

                        // Report cards grid
                        LazyVGrid(columns: columns, spacing: 16) {

                            // Revenue Trends
                            NavigationLink(destination: RevenueTrendsView()) {
                                reportCard(
                                    icon: "chart.bar.xaxis.ascending",
                                    title: "Revenue Trends",
                                    subtitle: "Track daily, weekly & monthly revenue with period comparison and export.",
                                    accentColor: RSMSTheme.Colors.accentGold,
                                    tag: "Financial"
                                )
                            }
                            .buttonStyle(.plain)

                            // Basket Size Trends
                            NavigationLink(destination: BasketTrendsView()) {
                                reportCard(
                                    icon: "basket.fill",
                                    title: "Basket Trends",
                                    subtitle: "Analyze average items per transaction across stores and categories.",
                                    accentColor: Color(red: 0.55, green: 0.78, blue: 0.62),
                                    tag: "Transactions"
                                )
                            }
                            .buttonStyle(.plain)

                            // Audit Logs
                            NavigationLink(destination: AuditLogsView()) {
                                reportCard(
                                    icon: "shield.lefthalf.filled",
                                    title: "Audit Logs",
                                    subtitle: "Complete trail of admin actions — products, tax, offers, stores & users.",
                                    accentColor: Color(red: 0.65, green: 0.72, blue: 0.88),
                                    tag: "Compliance"
                                )
                            }
                            .buttonStyle(.plain)
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

    // MARK: - Premium Report Card

    private func reportCard(
        icon: String,
        title: String,
        subtitle: String,
        accentColor: Color,
        tag: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 0) {

            // Top accent bar
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [accentColor.opacity(0.8), accentColor.opacity(0.2)],
                        startPoint: .leading, endPoint: .trailing
                    )
                )
                .frame(height: 3)

            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                // Icon + Tag row
                HStack {
                    ZStack {
                        RoundedRectangle(cornerRadius: 14)
                            .fill(accentColor.opacity(0.12))
                            .frame(width: 52, height: 52)
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(accentColor.opacity(0.2), lineWidth: 0.5)
                            )
                        Image(systemName: icon)
                            .font(.system(size: 22, weight: .medium))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [accentColor, accentColor.opacity(0.7)],
                                    startPoint: .topLeading, endPoint: .bottomTrailing
                                )
                            )
                    }

                    Spacer()

                    // Tag pill
                    Text(tag.uppercased())
                        .font(.system(size: 8, weight: .bold))
                        .tracking(1)
                        .foregroundStyle(accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(accentColor.opacity(0.1))
                        .cornerRadius(6)
                }

                // Title
                Text(title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)

                // Subtitle
                Text(subtitle)
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)

                // Bottom arrow
                HStack {
                    Spacer()
                    HStack(spacing: 4) {
                        Text("Open")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "arrow.right")
                            .font(.system(size: 10, weight: .bold))
                    }
                    .foregroundStyle(accentColor)
                }
            }
            .padding(RSMSTheme.Spacing.lg)
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .stroke(accentColor.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: accentColor.opacity(0.06), radius: 12, x: 0, y: 6)
    }
}

#Preview { ReportsTab() }
