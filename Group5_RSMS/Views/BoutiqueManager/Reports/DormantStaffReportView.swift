import SwiftUI

struct DormantStaffReportView: View {
    let dormantStaff: [Employee]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                if dormantStaff.isEmpty {
                    VStack(spacing: 16) {
                        Spacer().frame(height: 100)
                        Image(systemName: "person.badge.shield.checkmark.fill")
                            .font(.system(size: 60))
                            .foregroundColor(Color.green)
                        Text("All staff are active")
                            .font(Font.title2)
                            .foregroundColor(Color.primary)
                        Text("Everyone has recorded sales this month.")
                            .font(Font.subheadline)
                            .foregroundColor(Color.secondary)
                    }
                    .padding()
                } else {
                    VStack(alignment: .leading, spacing: 20) {
                        Text("Dormant Staff")
                            .font(Font.title2)
                            .foregroundColor(Color.primary)
                        
                        Text("The following staff members have not recorded any sales during the current performance period.")
                            .font(Font.subheadline)
                            .foregroundColor(Color.secondary)
                        
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
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .frame(width: 50, height: 50)
                .overlay(
                    Text(employee.name.prefix(1))
                        .font(.title3.bold())
                        .foregroundColor(Color.accentColor)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(employee.name)
                    .font(Font.body)
                    .foregroundColor(Color.primary)
                
                Text(employee.role)
                    .font(Font.caption)
                    .foregroundColor(Color.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 1)
        )
    }
}
