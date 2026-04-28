//
//  BMProfileView.swift
//  Group5_RSMS
//
//  Boutique Manager — Profile modal. 
//  Enhanced with symbol-only toolbars and professional intelligence styling.
//

import SwiftUI

struct BMProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    private var currentStore: Store? {
        guard let id = appState.currentStoreID else { return nil }
        return appState.stores.first(where: { $0.id == id })
    }

    private var displayName: String {
        let email = appState.userEmail
        guard !email.isEmpty else { return "Boutique Manager" }
        let local = email.components(separatedBy: "@").first ?? email
        return local
            .components(separatedBy: CharacterSet(charactersIn: "._-"))
            .map { $0.capitalized }
            .joined(separator: " ")
    }

    var body: some View {
        NavigationStack {
            SwiftUI.Form {
                Section("Identity Intelligence") {
                    HStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(.ultraThinMaterial)
                                .frame(width: 80, height: 80)
                                .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 0.5))
                            Text(String(displayName.prefix(1)))
                                .font(.custom("Helvetica", size: 36))
                                .fontWeight(.bold)
                                .foregroundColor(.accentColor)
                        }
                        
                        VStack(alignment: .leading, spacing: 6) {
                            Text(displayName)
                                .font(.custom("Helvetica", size: 24))
                                .fontWeight(.bold)
                                .foregroundColor(.primary)
                            Text(appState.userEmail)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                            
                            HStack(spacing: 6) {
                                Circle().fill(Color.green).frame(width: 8, height: 8)
                                Text("ACTIVE INTELLIGENCE SESSION")
                                    .font(.custom("Helvetica", size: 10))
                                    .fontWeight(.black)
                                    .foregroundColor(.green)
                            }
                            .padding(.top, 4)
                        }
                    }
                    .padding(.vertical, 16)
                }
                
                if let store = currentStore {
                    Section("Boutique Operational Context") {
                        LabeledContent {
                            Text(store.name).foregroundColor(.primary).font(.headline)
                        } label: {
                            Label("Store", systemImage: "storefront.fill")
                        }
                        
                        LabeledContent {
                            Text(store.city).foregroundColor(.primary)
                        } label: {
                            Label("Location", systemImage: "mappin.circle.fill")
                        }
                        
                        LabeledContent {
                            Text(store.country).foregroundColor(.primary)
                        } label: {
                            Label("Jurisdiction", systemImage: "globe.asia.australia.fill")
                        }
                    }
                }
                
                Section("Access Architecture") {
                    LabeledContent {
                        Text("Boutique Manager").foregroundColor(.primary).font(.headline)
                    } label: {
                        Label("Designation", systemImage: "person.badge.key.fill")
                    }
                    
                    LabeledContent {
                        Text("Full Operational Access").foregroundColor(.primary)
                    } label: {
                        Label("Permissions", systemImage: "lock.shield.fill")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
                            appState.signOut()
                        }
                    } label: {
                        HStack {
                            Spacer()
                             Text("TERMINATE SESSION")
                                .font(.custom("Helvetica", size: 14))
                                .fontWeight(.black)
                                .tracking(1)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Manager Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { dismiss() } label: {
                        ZStack {
                             Circle().fill(.ultraThinMaterial).frame(width: 36, height: 36)
                            Image(systemName: "xmark")
                                .font(.custom("Helvetica", size: 14))
                                .fontWeight(.bold)
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
        }
    }
}
