import SwiftUI

struct FloorQuantitySheet: View {
    let product: FastMovingProduct
    let storeId: UUID
    @ObservedObject var viewModel: BMInventoryViewModel
    @Environment(\.dismiss) private var dismiss
    
    @State private var quantity: Int = 1
    @State private var showAlert = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    ScrollView {
                        VStack(spacing: 28) {
                            // Header
                            HStack(spacing: 16) {
                                Group {
                                    if let urlString = product.imageUrl, let url = URL(string: urlString) {
                                        AsyncImage(url: url) { phase in
                                            if let image = phase.image {
                                                image.resizable().aspectRatio(contentMode: .fill)
                                            } else {
                                                Color.gray.opacity(0.1)
                                            }
                                        }
                                    } else {
                                        Color.gray.opacity(0.1)
                                    }
                                }
                                .frame(width: 60, height: 60)
                                .cornerRadius(12)
                                
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(product.name)
                                        .font(.system(size: 18, weight: .bold))
                                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                                    Text(product.sku)
                                        .font(.system(size: 13, weight: .medium, design: .monospaced))
                                        .foregroundColor(RSMSTheme.Colors.accentGold)
                                }
                                Spacer()
                            }
                            .padding(.top, 20)
                            .padding(.horizontal, 20)
                            
                            // Action Context
                            HStack {
                                Text(product.isOnFloor ? "Remove from Floor" : "Place on Floor")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                                Spacer()
                                HStack(spacing: 4) {
                                    Text("Available Stock:")
                                    Text("\(product.currentStock)")
                                        .fontWeight(.bold)
                                        .foregroundColor(product.currentStock == 0 ? RSMSTheme.Colors.error : RSMSTheme.Colors.success)
                                }
                                .font(.system(size: 14))
                                .foregroundColor(RSMSTheme.Colors.textSecondary)
                            }
                            .padding(.horizontal, 20)
                            
                            // Quantity Selector
                            VStack(spacing: 16) {
                                Text("SELECT QUANTITY")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(RSMSTheme.Colors.textTertiary)
                                    .tracking(1.0)
                                
                                HStack(spacing: 30) {
                                    Button {
                                        if quantity > 1 { quantity -= 1 }
                                    } label: {
                                        Image(systemName: "minus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(quantity > 1 ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textTertiary)
                                    }
                                    
                                    Text("\(quantity)")
                                        .font(.system(size: 40, weight: .black, design: .rounded))
                                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                                        .frame(minWidth: 60)
                                    
                                    Button {
                                        quantity += 1
                                    } label: {
                                        Image(systemName: "plus.circle.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(RSMSTheme.Colors.accentGold)
                                    }
                                }
                            }
                            .padding(.vertical, 32)
                            .frame(maxWidth: .infinity)
                            .background(RSMSTheme.Colors.backgroundElevated)
                            .cornerRadius(20)
                            .padding(.horizontal, 20)
                            
                            if quantity > product.currentStock && !product.isOnFloor {
                                HStack(spacing: 8) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(RSMSTheme.Colors.error)
                                    Text("Quantity exceeds available stock (\(product.currentStock))")
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundColor(RSMSTheme.Colors.error)
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    // Confirm button pinned to bottom
                    Button {
                        if !product.isOnFloor && quantity > product.currentStock {
                            showAlert = true
                        } else {
                            confirmAction()
                        }
                    } label: {
                        HStack {
                            if viewModel.isUpdatingFloorDisplay {
                                ProgressView().tint(.black)
                            } else {
                                Text("Confirm Movement")
                                    .fontWeight(.bold)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(RSMSTheme.Colors.goldGradient)
                        .foregroundColor(.black)
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 24)
                    .padding(.top, 12)
                    .disabled(viewModel.isUpdatingFloorDisplay)
                }
            }
            .navigationTitle("Floor Movement")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            }
            .alert("Insufficient Stock", isPresented: $showAlert) {
                Button("Adjust Quantity", role: .cancel) { }
            } message: {
                Text("You cannot move \(quantity) units because only \(product.currentStock) units are available in stock.")
            }
        }
    }
    
    private func confirmAction() {
        Task {
            await viewModel.toggleFloorDisplay(for: product, storeId: storeId, quantity: quantity)
            dismiss()
        }
    }
}
