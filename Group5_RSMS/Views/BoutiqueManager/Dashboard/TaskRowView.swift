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
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .resizable()
                    .frame(width: 24, height: 24)
                    .foregroundColor(task.isCompleted ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textSecondary)
            }
            .buttonStyle(.plain)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .font(RSMSTheme.Typography.bodyCopy1)
                    .strikethrough(task.isCompleted)
                    .foregroundColor(task.isCompleted ? RSMSTheme.Colors.textSecondary : RSMSTheme.Colors.textPrimary)
                
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
}

extension DateFormatter {
    static let shortDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        return formatter
    }()
}
