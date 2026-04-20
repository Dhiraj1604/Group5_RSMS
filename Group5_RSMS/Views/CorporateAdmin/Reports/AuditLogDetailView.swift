// AuditLogDetailView.swift
// Group5_RSMS — Detail screen for a single audit log (inside Reports)

import SwiftUI

struct AuditLogDetailView: View {
    let log: AuditLog

    private let noiseKeys: Set<String> = ["id", "created_at", "updated_at"]

    /// Computes the list of changes by diffing before and after data
    private var changes: [(field: String, oldValue: String?, newValue: String?)] {
        let before = log.beforeData ?? [:]
        let after  = log.afterData ?? [:]

        let allKeys = Set(before.keys).union(after.keys).subtracting(noiseKeys)
        var result: [(field: String, oldValue: String?, newValue: String?)] = []

        for key in allKeys.sorted() {
            let oldVal = before[key]
            let newVal = after[key]
            if oldVal != newVal {
                result.append((field: key, oldValue: oldVal, newValue: newVal))
            }
        }
        return result
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    heroHeader
                    sectionLabel("Activity Info")
                    activityInfoCard

                    if !changes.isEmpty {
                        sectionLabel("What Changed")
                        changesCard
                    } else if log.beforeData == nil && log.afterData != nil {
                        sectionLabel("Created With")
                        simpleDataCard(data: log.afterData ?? [:], accent: RSMSTheme.Colors.success)
                    } else if log.beforeData != nil && log.afterData == nil {
                        sectionLabel("Deleted Record")
                        simpleDataCard(data: log.beforeData ?? [:], accent: RSMSTheme.Colors.error)
                    }

                    Spacer(minLength: 40)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
            }
        }
        .navigationTitle("Log Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }

    // MARK: - Hero
    private var heroHeader: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.12))
                    .frame(width: 60, height: 60)
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(RSMSTheme.Colors.accentGold.opacity(0.25), lineWidth: 0.5)
                    )
                Image(systemName: log.eventType.iconName)
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(RSMSTheme.Colors.goldGradient)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(log.action)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                Text(log.entity)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .lineLimit(1)
            }
            Spacer()
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.accentGold.opacity(0.12), lineWidth: 0.5)
        )
    }

    // MARK: - Section Label
    private func sectionLabel(_ text: String) -> some View {
        HStack(spacing: 8) {
            Rectangle()
                .fill(RSMSTheme.Colors.goldGradient)
                .frame(width: 3, height: 16)
                .cornerRadius(2)
            Text(text.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(1.5)
                .foregroundColor(RSMSTheme.Colors.accentGold)
        }
    }

    // MARK: - Activity Info Card
    private var activityInfoCard: some View {
        VStack(spacing: 0) {
            infoRow(label: "Action",    value: log.action,             isLast: false)
            infoRow(label: "User",      value: log.userName,           isLast: false)
            infoRow(label: "Entity",    value: log.entity,             isLast: false)
            infoRow(label: "Timestamp", value: log.formattedTimestamp, isLast: true)
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
    }

    private func infoRow(label: String, value: String, isLast: Bool) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .top, spacing: 16) {
                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .frame(width: 90, alignment: .leading)
                Text(value)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            if !isLast {
                Divider().background(Color.white.opacity(0.05)).padding(.leading, 16)
            }
        }
    }

    // MARK: - Changes Card
    private var changesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(changes.enumerated()), id: \.offset) { index, change in
                VStack(alignment: .leading, spacing: 0) {
                    HStack(alignment: .center, spacing: 12) {
                        Text(humanReadable(change.field))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                            .frame(width: 90, alignment: .leading)

                        changeSummaryView(change)

                        Spacer()
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if index < changes.count - 1 {
                        Divider().background(Color.white.opacity(0.06)).padding(.leading, 16)
                    }
                }
            }
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
    }

    /// Renders a single-line summary for each change.
    /// Image fields → "Image added" / "Image removed" / "Image updated"
    /// Other fields with removal → "Removed"
    /// Normal changes → "old → new"
    @ViewBuilder
    private func changeSummaryView(_ change: (field: String, oldValue: String?, newValue: String?)) -> some View {
        let isImageField = change.field == "image_url"
        let oldIsUrl = change.oldValue?.hasPrefix("http") == true
        let newIsUrl = change.newValue?.hasPrefix("http") == true
        let wasRemoved = change.newValue == "(removed)" || (change.newValue == nil && change.oldValue != nil)
        let wasAdded = (change.oldValue == nil || change.oldValue == "(none)") && change.newValue != nil && !wasRemoved

        if isImageField || (oldIsUrl && wasRemoved) || (newIsUrl && wasAdded) {
            // Image field — single simple label
            if wasRemoved {
                Text("Image removed")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.error)
            } else if wasAdded || change.oldValue == "(none)" {
                Text("Image added")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.success)
            } else {
                Text("Image updated")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.accentGoldLight)
            }
        } else if wasRemoved {
            // Non-image field removed
            Text("\(displayValue(change.oldValue ?? "", for: change.field)) removed")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(RSMSTheme.Colors.error)
        } else if wasAdded {
            // Field added
            Text(displayValue(change.newValue ?? "", for: change.field))
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(RSMSTheme.Colors.success)
        } else {
            // Normal change — old → new
            HStack(spacing: 6) {
                Text(displayValue(change.oldValue ?? "", for: change.field))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .strikethrough(true, color: RSMSTheme.Colors.textTertiary)
                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                Text(displayValue(change.newValue ?? "", for: change.field))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.success)
            }
        }
    }

    // MARK: - Simple Data Card (create/delete)
    private func simpleDataCard(data: [String: String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let filtered = data.filter { !noiseKeys.contains($0.key) }.sorted(by: { $0.key < $1.key })
            ForEach(Array(filtered.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        Text(humanReadable(item.key))
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                            .frame(width: 100, alignment: .leading)
                        Spacer()
                        Text(displayValue(item.value, for: item.key))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.trailing)
                            .lineLimit(2)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)

                    if index < filtered.count - 1 {
                        Divider().background(Color.white.opacity(0.05)).padding(.leading, 16)
                    }
                }
            }
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(accent.opacity(0.2), lineWidth: 0.75)
        )
    }

    // MARK: - Display Helpers

    private func humanReadable(_ key: String) -> String {
        let mapping: [String: String] = [
            "base_price": "Price",
            "image_url": "Image",
            "is_active": "Status",
            "is_globally_listed": "Listing",
            "origin_country": "Country",
            "craftsmanship_level": "Craft Level",
            "craftsmanship_notes": "Craft Notes",
            "collection_name": "Collection",
            "artisan_studio": "Studio",
            "in_repair": "In Repair",
            "stock_quantity": "Stock",
            "from_store": "From Store",
            "to_store": "To Store",
            "source_stock_before": "Source Before",
            "source_stock_after": "Source After",
            "dest_stock_before": "Dest Before",
            "dest_stock_after": "Dest After",
            "quantity_transferred": "Qty Moved",
        ]
        return mapping[key] ?? key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    private func displayValue(_ value: String, for key: String) -> String {
        if key == "is_active" || key == "is_globally_listed" || key == "in_repair" {
            return value == "1" || value.lowercased() == "true" ? "Yes" : "No"
        }
        if key == "base_price" || key == "price" {
            if let num = Double(value) { return "₹\(String(format: "%.0f", num))" }
        }
        if value == "(none)" { return "—" }
        if value == "(removed)" { return "Removed" }
        // Don't show raw URLs — handled by changeSummaryView for image fields
        if value.hasPrefix("http") { return "Image" }
        return value
    }
}
