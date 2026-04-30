import SwiftUI

struct DormantStaffReportView: View {
    let dormantStaff: [Employee]
    
    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
            
            ScrollView {
                if dormantStaff.isEmpty {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 100)
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 60))
                            .foregroundColor(RSMSTheme.Colors.success)
                        Text("All staff are active")
                            .font(RSMSTheme.Typography.heading3)
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                        Text("Everyone has recorded sales this month.")
                            .font(RSMSTheme.Typography.bodyCopy2)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Dormant Staff")
                            .font(RSMSTheme.Typography.heading3)
                            .foregroundColor(RSMSTheme.Colors.textPrimary)
                        
                        Text("The following staff members have not recorded any sales during the current performance period.")
                            .font(RSMSTheme.Typography.bodyCopy2)
                            .foregroundColor(RSMSTheme.Colors.textSecondary)
                        
                        LazyVStack(spacing: 12) {
                            ForEach(dormantStaff) { employee in
                                DormantEmployeeCard(employee: employee)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle("Dormant Staff")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct DormantEmployeeCard: View {
    let employee: Employee
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(RSMSTheme.Colors.surfacePrimary)
                .frame(width: 50, height: 50)
                .overlay(
                    Text(employee.name.prefix(1))
                        .font(.title3.bold())
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(RSMSTheme.Typography.bodyCopy1)
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                
                Text(employee.role)
                    .font(RSMSTheme.Typography.caption)
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
            }
            
            Spacer()
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }
}
