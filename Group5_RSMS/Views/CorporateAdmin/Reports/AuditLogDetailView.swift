// AuditLogDetailView.swift
// Group5_RSMS — Detail screen for a single audit log (inside Reports)

import SwiftUI

struct AuditLogDetailView: View {
    let log: AuditLog

    // Fields to hide from the UI (noise)
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
            // Only include if something actually changed
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
                VStack(alignment: .leading, spacing: 24) {

                    // MARK: Hero Header
                    heroHeader

                    // MARK: Activity Info
                    sectionLabel("Activity Info")
                    activityInfoCard

                    // MARK: Changes
                    if !changes.isEmpty {
                        sectionLabel("What Changed")
                        changesCard
                    } else if log.beforeData == nil && log.afterData != nil {
                        // Created — show summary
                        sectionLabel("Created With")
                        simpleDataCard(data: log.afterData ?? [:], accent: RSMSTheme.Colors.success)
                    } else if log.beforeData != nil && log.afterData == nil {
                        // Deleted — show what was removed
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
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
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
                .stroke(RSMSTheme.Colors.accentGold.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
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
                Divider()
                    .background(Color.white.opacity(0.05))
                    .padding(.leading, 16)
            }
        }
    }

    // MARK: - Changes Card (Diff View — only changed fields)
    private var changesCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(changes.enumerated()), id: \.offset) { index, change in
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 6) {
                        // Field name
                        Text(humanReadable(change.field))
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(RSMSTheme.Colors.accentGold)
                            .textCase(.uppercase)

                        // Change row
                        HStack(spacing: 8) {
                            // Old value
                            if let old = change.oldValue {
                                HStack(spacing: 4) {
                                    Image(systemName: "minus.circle.fill")
                                        .font(.system(size: 10))
                                        .foregroundColor(RSMSTheme.Colors.error)
                                    Text(displayValue(old, for: change.field))
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(RSMSTheme.Colors.error.opacity(0.9))
                                        .lineLimit(2)
                                }
                            }

                            // Arrow
                            if change.oldValue != nil && change.newValue != nil
                                && change.newValue != "(removed)" {
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                            }

                            // New value
                            if let new = change.newValue {
                                if new == "(removed)" {
                                    HStack(spacing: 4) {
                                        Image(systemName: "xmark.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(RSMSTheme.Colors.error)
                                        Text("Removed")
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(RSMSTheme.Colors.error.opacity(0.9))
                                            .italic()
                                    }
                                } else {
                                    HStack(spacing: 4) {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 10))
                                            .foregroundColor(RSMSTheme.Colors.success)
                                        Text(displayValue(new, for: change.field))
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundColor(RSMSTheme.Colors.success.opacity(0.9))
                                            .lineLimit(2)
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)

                    if index < changes.count - 1 {
                        Divider()
                            .background(Color.white.opacity(0.05))
                            .padding(.leading, 16)
                    }
                }
            }
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.accentGold.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }

    // MARK: - Simple Data Card (for create/delete — shows all fields)
    private func simpleDataCard(data: [String: String], accent: Color) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            let filtered = data.filter { !noiseKeys.contains($0.key) }.sorted(by: { $0.key < $1.key })
            ForEach(Array(filtered.enumerated()), id: \.offset) { index, item in
                VStack(spacing: 0) {
                    HStack(alignment: .top, spacing: 12) {
                        Text(humanReadable(item.key))
                            .font(.system(size: 11, weight: .semibold))
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
        .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
    }

    // MARK: - Display Helpers

    /// Converts snake_case keys to human-readable labels
    private func humanReadable(_ key: String) -> String {
        let mapping: [String: String] = [
            "base_price": "Price",
            "image_url": "Image",
            "is_active": "Active Status",
            "is_globally_listed": "Global Listing",
            "origin_country": "Origin Country",
            "craftsmanship_level": "Craftsmanship",
            "craftsmanship_notes": "Craft. Notes",
            "collection_name": "Collection",
            "artisan_studio": "Artisan Studio",
            "in_repair": "In Repair",
        ]
        return mapping[key] ?? key.replacingOccurrences(of: "_", with: " ").capitalized
    }

    /// Formats values for readability (booleans, prices, URLs)
    private func displayValue(_ value: String, for key: String) -> String {
        // Booleans
        if key == "is_active" || key == "is_globally_listed" || key == "in_repair" {
            return value == "1" || value.lowercased() == "true" ? "Yes" : "No"
        }
        // Prices
        if key == "base_price" || key == "price" {
            if let num = Double(value) {
                return "₹\(String(format: "%.0f", num))"
            }
        }
        // URLs — show shortened
        if value.hasPrefix("http") {
            return "🖼 Image uploaded"
        }
        // Empty / none markers
        if value == "(none)" { return "—" }
        return value
    }
}
