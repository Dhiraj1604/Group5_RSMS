//
//  DiscrepancyReportView.swift
//  Group5_RSMS
//
//  Inventory Controller — Discrepancy Report & Fix Approval Screen
//
//  Shown after a stock check is run. Lists every discrepancy with:
//    • Quantity difference (shortage / surplus)
//    • AI-generated suggested fix with confidence badge
//    • One-tap "Approve" to commit the adjustment to Supabase
//

import SwiftUI

// MARK: - Discrepancy Report

struct DiscrepancyReportView: View {
    @ObservedObject var vm: StockCheckViewModel
    @Environment(\.dismiss) private var dismiss

    // segment: 0 = pending, 1 = resolved
    @State private var segment = 0

    private var pending:  [StockDiscrepancy] { vm.discrepancies.filter { !$0.isApproved } }
    private var resolved: [StockDiscrepancy] { vm.discrepancies.filter {  $0.isApproved } }
    private var displayed: [StockDiscrepancy] { segment == 0 ? pending : resolved }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Segment picker
                segmentPicker
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.vertical, RSMSTheme.Spacing.md)

                // Summary bar
                summaryBar
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.bottom, RSMSTheme.Spacing.md)

                // List
                if displayed.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: RSMSTheme.Spacing.md) {
                            ForEach(displayed) { d in
                                DiscrepancyCard(
                                    discrepancy: d,
                                    fix: vm.fixes[d.id],
                                    onApprove: {
                                        Task { await vm.approveFix(discrepancyId: d.id) }
                                    },
                                    onDismiss: {
                                        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                                            vm.dismissDiscrepancy(id: d.id)
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                        .padding(.bottom, RSMSTheme.Spacing.xxxl)
                    }
                }
            }
        }
        .navigationTitle("Discrepancy Report")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if pending.isEmpty {
                    Label("All Clear", systemImage: "checkmark.seal.fill")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.success)
                }
            }
        }
    }

    // MARK: - Segment Picker

    private var segmentPicker: some View {
        HStack(spacing: 0) {
            segmentButton(label: "Pending (\(pending.count))",  tag: 0)
            segmentButton(label: "Resolved (\(resolved.count))", tag: 1)
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }

    private func segmentButton(label: String, tag: Int) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { segment = tag }
        } label: {
            Text(label)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(segment == tag ? .black : RSMSTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 40)
                .background(
                    segment == tag
                        ? RSMSTheme.Colors.goldGradient
                        : LinearGradient(colors: [.clear], startPoint: .leading, endPoint: .trailing)
                )
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md - 1))
        }
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        HStack(spacing: RSMSTheme.Spacing.sm) {
            summaryPill(label: "Total", value: "\(vm.discrepancies.count)", color: RSMSTheme.Colors.accentGold)
            summaryPill(label: "Pending", value: "\(pending.count)", color: RSMSTheme.Colors.error)
            summaryPill(label: "Approved", value: "\(resolved.count)", color: RSMSTheme.Colors.success)
        }
    }

    private func summaryPill(label: String, value: String, color: Color) -> some View {
        HStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .padding(.horizontal, RSMSTheme.Spacing.md)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(color.opacity(0.1))
                .overlay(Capsule().stroke(color.opacity(0.3), lineWidth: 1))
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.success.opacity(0.1))
                    .frame(width: 80, height: 80)
                Image(systemName: segment == 0 ? "checkmark.seal.fill" : "tray.fill")
                    .font(.system(size: 34))
                    .foregroundStyle(segment == 0 ? RSMSTheme.Colors.success : RSMSTheme.Colors.textTertiary)
            }
            Text(segment == 0
                 ? "All discrepancies resolved!"
                 : "No resolved items yet")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Spacer()
        }
    }
}

// MARK: - Discrepancy Card

struct DiscrepancyCard: View {
    let discrepancy: StockDiscrepancy
    let fix: SuggestedFix?
    let onApprove: () -> Void
    let onDismiss: () -> Void

    @State private var isExpanded = true

    private var diffLabel: String {
        let d = discrepancy.difference
        return d > 0 ? "+\(d) surplus" : "\(d) shortage"
    }
    private var diffColor: Color {
        discrepancy.difference > 0 ? RSMSTheme.Colors.warning : RSMSTheme.Colors.error
    }
    private var diffIcon: String {
        discrepancy.difference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }

    var body: some View {
        VStack(spacing: 0) {

            // MARK: Card Header
            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) { isExpanded.toggle() }
            } label: {
                HStack(spacing: RSMSTheme.Spacing.md) {

                    // Status circle
                    ZStack {
                        Circle()
                            .fill(discrepancy.isApproved
                                  ? RSMSTheme.Colors.success.opacity(0.15)
                                  : diffColor.opacity(0.15))
                            .frame(width: 44, height: 44)
                        Image(systemName: discrepancy.isApproved ? "checkmark.circle.fill" : diffIcon)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(discrepancy.isApproved ? RSMSTheme.Colors.success : diffColor)
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(discrepancy.productName)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                            .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            .lineLimit(1)
                        Text("SKU: \(discrepancy.sku)")
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    }

                    Spacer()

                    // Diff badge
                    Text(discrepancy.isApproved ? "Fixed" : diffLabel)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(discrepancy.isApproved ? RSMSTheme.Colors.success : diffColor)
                        .padding(.horizontal, RSMSTheme.Spacing.sm)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill((discrepancy.isApproved
                                       ? RSMSTheme.Colors.success
                                       : diffColor).opacity(0.15))
                        )

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)
                }
                .padding(RSMSTheme.Spacing.lg)
            }
            .buttonStyle(.plain)

            // MARK: Expanded Detail
            if isExpanded {
                VStack(spacing: RSMSTheme.Spacing.md) {
                    Divider().background(RSMSTheme.Colors.borderLight)

                    // Quantity comparison grid
                    quantityComparison

                    // Suggested Fix panel
                    if let fix = fix {
                        fixPanel(fix)
                    }

                    // Action buttons
                    if !discrepancy.isApproved {
                        actionButtons
                    } else {
                        approvedBadge
                    }
                }
                .padding(.horizontal, RSMSTheme.Spacing.lg)
                .padding(.bottom, RSMSTheme.Spacing.lg)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .fill(RSMSTheme.Colors.backgroundDeep)
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                        .stroke(
                            discrepancy.isApproved
                                ? RSMSTheme.Colors.success.opacity(0.3)
                                : diffColor.opacity(0.25),
                            lineWidth: 1
                        )
                )
                .shadow(color: Color.black.opacity(0.35), radius: 8, y: 4)
        )
    }

    // MARK: Quantity Comparison Grid

    private var quantityComparison: some View {
        HStack(spacing: 0) {
            qtyBox(label: "Expected", value: discrepancy.expectedQty, color: RSMSTheme.Colors.accentGold)

            // Arrow with diff
            VStack(spacing: 2) {
                Image(systemName: discrepancy.difference >= 0 ? "arrow.up" : "arrow.down")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(diffColor)
                Text(diffLabel)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundStyle(diffColor)
            }
            .frame(maxWidth: .infinity)

            qtyBox(label: "Actual", value: discrepancy.scannedQty, color: diffColor)
        }
        .padding(RSMSTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .fill(RSMSTheme.Colors.backgroundElevated)
        )
    }

    private func qtyBox(label: String, value: Int, color: Color) -> some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 32, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: Fix Panel

    private func fixPanel(_ fix: SuggestedFix) -> some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
            HStack {
                Image(systemName: "wand.and.stars")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                Text("Suggested Fix")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                Spacer()

                // Confidence badge
                HStack(spacing: 4) {
                    Image(systemName: fix.confidence.icon)
                        .font(.system(size: 10, weight: .bold))
                    Text(fix.confidence.label)
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                }
                .foregroundStyle(fix.confidence.color)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(fix.confidence.color.opacity(0.12))
                        .overlay(Capsule().stroke(fix.confidence.color.opacity(0.3), lineWidth: 1))
                )
            }

            Divider().background(RSMSTheme.Colors.accentGoldDark.opacity(0.3))

            // Reason
            HStack(alignment: .top, spacing: RSMSTheme.Spacing.sm) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 11))
                    .foregroundStyle(RSMSTheme.Colors.warning)
                    .padding(.top, 1)
                Text(fix.reasonCode)
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            // Recommended target
            HStack {
                Text("Recommended adjustment:")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                Spacer()
                Text("Set to \(fix.recommendedAdjustment) units")
                    .font(.system(size: 13, weight: .bold, design: .monospaced))
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
            }
        }
        .padding(RSMSTheme.Spacing.md)
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .fill(RSMSTheme.Colors.accentGold.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .stroke(RSMSTheme.Colors.accentGoldDark.opacity(0.3), lineWidth: 1)
                )
        )
    }

    // MARK: Action Buttons

    private var actionButtons: some View {
        HStack(spacing: RSMSTheme.Spacing.md) {
            // Dismiss
            Button {
                onDismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                    Text("Dismiss")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                }
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .fill(RSMSTheme.Colors.backgroundElevated)
                        .overlay(
                            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                        )
                )
            }

            // Approve
            Button {
                onApprove()
            } label: {
                ZStack {
                    if discrepancy.isApplying {
                        ProgressView()
                            .tint(.black)
                    } else {
                        HStack(spacing: 5) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                            Text("Approve Fix")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                        }
                        .foregroundStyle(.black)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 42)
                .background(RSMSTheme.Colors.goldGradient)
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                .shadow(color: RSMSTheme.Colors.accentGold.opacity(0.3), radius: 6, y: 3)
            }
            .disabled(discrepancy.isApplying)
        }
    }

    // MARK: Approved Badge

    private var approvedBadge: some View {
        HStack(spacing: RSMSTheme.Spacing.sm) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RSMSTheme.Colors.success)
            Text("Adjustment applied & logged")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundStyle(RSMSTheme.Colors.success)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RSMSTheme.Spacing.sm)
        .background(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .fill(RSMSTheme.Colors.success.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                        .stroke(RSMSTheme.Colors.success.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        DiscrepancyReportView(vm: {
            let vm = StockCheckViewModel()
            return vm
        }())
    }
    .environment(AppState())
}
