//
//  CreateEventSheet.swift
//  Group5_RSMS
//

import SwiftUI

struct CreateEventSheet: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: VIPEventsViewModel
    
    @State private var title = ""
    @State private var date = Date()
    @State private var capacityString = ""
    @State private var collections = ""
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        
                        inputField(title: "Event Title", text: $title, placeholder: "e.g. Summer Preview")
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Date & Time")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            
                            DatePicker("", selection: $date, displayedComponents: [.date, .hourAndMinute])
                                .labelsHidden()
                                .colorScheme(.dark)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding()
                                .background(RSMSTheme.Colors.surfacePrimary)
                                .cornerRadius(12)
                        }
                        
                        inputField(title: "Guest Capacity", text: $capacityString, placeholder: "e.g. 50")
                            .keyboardType(.numberPad)
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Collection Details (comma separated)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                            
                            TextEditor(text: $collections)
                                .frame(height: 100)
                                .padding(8)
                                .scrollContentBackground(.hidden)
                                .background(RSMSTheme.Colors.surfacePrimary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                                )
                                .foregroundColor(RSMSTheme.Colors.textPrimary)
                        }
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Create VIP Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEvent()
                    }
                    .fontWeight(.bold)
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                    .disabled(title.isEmpty || capacityString.isEmpty)
                }
            }
        }
    }
    
    private func inputField(title: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(RSMSTheme.Colors.textPrimary)
            
            TextField(placeholder, text: text)
                .padding()
                .background(RSMSTheme.Colors.surfacePrimary)
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
                )
                .foregroundColor(RSMSTheme.Colors.textPrimary)
        }
    }
    
    private func saveEvent() {
        let cap = Int(capacityString) ?? 0
        let collectionList = collections.split(separator: ",").map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        
        viewModel.createEvent(title: title, date: date, capacity: cap, collections: collectionList.filter { !$0.isEmpty })
        dismiss()
    }
}
