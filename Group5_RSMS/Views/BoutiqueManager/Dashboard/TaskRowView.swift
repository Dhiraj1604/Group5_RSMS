//
//  TaskRowView.swift
//  Group5_RSMS
//

import SwiftUI

struct TaskRowView: View {
    let task: StoreTask
    let onToggle: () -> Void
    var staffName: String?
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Button(action: onToggle) {
                Image(systemName: iconName(for: task.status))
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(iconColor(for: task.status))
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(RSMSTheme.Typography.bodyCopy1)
                    .strikethrough(task.status == .verified)
                    .foregroundColor(task.status == .verified ? RSMSTheme.Colors.textSecondary : RSMSTheme.Colors.textPrimary)
                
                if let desc = task.description, !desc.isEmpty {
                    Text(desc)
                        .font(RSMSTheme.Typography.bodyCopy2)
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                        .lineLimit(2)
                }
                
                HStack(spacing: 12) {
                    if let staff = staffName {
                        Label(staff, systemImage: "person.text.rectangle")
                            .font(.caption)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    } else {
                        Label("Unassigned", systemImage: "person.crop.circle.badge.questionmark")
                            .font(.caption)
                            .foregroundColor(RSMSTheme.Colors.error)
                    }
                    
                    if let due = task.dueDate {
                        Label(DateFormatter.shortDate.string(from: due), systemImage: "calendar")
                            .font(.caption)
                            .foregroundColor(task.isOverdue ? RSMSTheme.Colors.error : RSMSTheme.Colors.textSecondary)
                    }
                }
                .padding(.top, 4)
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(RSMSTheme.Colors.surfacePrimary)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
    }
    
    private func iconName(for status: TaskStatus) -> String {
        switch status {
        case .pending: return "circle"
        case .completedByStaff: return "checkmark.circle"
        case .verified: return "checkmark.circle.fill"
        }
    }
    
    private func iconColor(for status: TaskStatus) -> Color {
        switch status {
        case .pending: return RSMSTheme.Colors.textSecondary
        case .completedByStaff: return RSMSTheme.Colors.accentGold
        case .verified: return RSMSTheme.Colors.success
        }
    }
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
