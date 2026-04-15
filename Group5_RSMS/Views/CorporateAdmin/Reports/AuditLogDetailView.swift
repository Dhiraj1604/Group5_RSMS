// AuditLogDetailView.swift
// Group5_RSMS — Detail screen for a single audit log (inside Reports)

import SwiftUI

struct AuditLogDetailView: View {
    let log: AuditLog

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
                    if !(log.beforeData?.isEmpty ?? true) || !(log.afterData?.isEmpty ?? true) {
                        sectionLabel("Changes")
                        HStack(alignment: .top, spacing: 12) {
                            changeCard(
                                title: "Before",
                                data: log.beforeData ?? [:],
                                accent: RSMSTheme.Colors.error,
                                icon: "arrow.uturn.backward.circle.fill",
                                emptyLabel: "New Record"
                            )
                            changeCard(
                                title: "After",
                                data: log.afterData ?? [:],
                                accent: RSMSTheme.Colors.success,
                                icon: "checkmark.circle.fill",
                                emptyLabel: "Record Deleted"
                            )
                        }
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
            infoRow(label: "User",      value: log.userName,               isLast: false)
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

    // MARK: - Change Card
    private func changeCard(title: String, data: [String: String], accent: Color, icon: String, emptyLabel: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(accent)
                Text(title)
                    .font(.system(size: 12, weight: .bold))
                    .tracking(0.8)
                    .foregroundColor(accent)
            }
            Divider().background(accent.opacity(0.3))

            if data.isEmpty {
                Text(emptyLabel)
                    .font(.system(size: 11))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .italic()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 6)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(data.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(key)
                                .font(.system(size: 10))
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                            Text(value)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.white)
                        }
                    }
                }
            }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(accent.opacity(0.2), lineWidth: 0.75)
        )
    }
}
