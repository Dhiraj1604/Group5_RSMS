//
//  ProductsListView.swift
//  Group5_RSMS
//
//  Displays all products fetched from the Supabase "products" table.
//

import SwiftUI

struct ProductsListView: View {
    @Environment(AppState.self) private var appState
    @State private var searchText = ""
    @State private var productToRepair: ProductNew?
    @State private var productToResolve: ProductNew?
    @State private var showingResolveAlert = false

    var filteredProducts: [ProductNew] {
        if searchText.isEmpty {
            return appState.products
        }
        return appState.products.filter {
            $0.name.localizedCaseInsensitiveContains(searchText) ||
            $0.sku.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary
                .ignoresSafeArea()

            Group {
                if appState.isLoadingProducts {
                    loadingView
                } else if let error = appState.productError {
                    errorView(error)
                } else if filteredProducts.isEmpty {
                    emptyView
                } else {
                    productList
                }
            }
        }
        .navigationTitle("All Products")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $searchText, prompt: "Search by name or SKU")
        .task {
            await appState.fetchProducts()
        }
        .sheet(item: $productToRepair) { product in
            RepairFormSheet(product: product)
        }
        .alert("Confirm Repaired", isPresented: $showingResolveAlert, presenting: productToResolve) { product in
            Button("Cancel", role: .cancel) { }
            Button("Return to Inventory") {
                Task {
                    await appState.resolveRepair(for: product)
                }
            }
        } message: { product in
            Text("Are you sure you want to mark \(product.name) as repaired and return it to general stock?")
        }
    }

    // MARK: - Product List

    private var productList: some View {
        List {
            ForEach(filteredProducts) { product in
                productRow(product)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: RSMSTheme.Spacing.xs,
                        leading: RSMSTheme.Spacing.lg,
                        bottom: RSMSTheme.Spacing.xs,
                        trailing: RSMSTheme.Spacing.lg
                    ))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button {
                            if product.inRepair {
                                productToResolve = product
                                showingResolveAlert = true
                            } else {
                                productToRepair = product
                            }
                        } label: {
                            Label(
                                product.inRepair ? "Return" : "Repair",
                                systemImage: product.inRepair ? "checkmark.circle.fill" : "wrench.fill"
                            )
                        }
                        .tint(product.inRepair ? RSMSTheme.Colors.success : RSMSTheme.Colors.warning)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    private func productRow(_ product: ProductNew) -> some View {
        HStack(spacing: RSMSTheme.Spacing.lg) {
            ZStack {
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                    .fill(product.inRepair
                          ? RSMSTheme.Colors.warning.opacity(0.15)
                          : RSMSTheme.Colors.backgroundElevated)
                    .frame(width: 56, height: 56)
                Image(systemName: product.inRepair ? "wrench.fill" : "shippingbox.fill")
                    .font(.title3)
                    .foregroundStyle(product.inRepair
                                     ? RSMSTheme.Colors.warning
                                     : RSMSTheme.Colors.accentGold)
            }

            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                Text(product.name)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    .lineLimit(1)

                HStack(spacing: RSMSTheme.Spacing.sm) {
                    Text("SKU: \(product.sku)")
                        .font(.caption)
                        .foregroundStyle(RSMSTheme.Colors.textTertiary)

                    if product.inRepair {
                        Text("In Repair")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(RSMSTheme.Colors.warning)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(RSMSTheme.Colors.warning.opacity(0.15))
                            .clipShape(Capsule())
                    }
                }
            }

            Spacer()

            Text("₹\(product.basePrice, specifier: "%.2f")")
                .font(.subheadline)
                .fontWeight(.bold)
                .foregroundStyle(product.inRepair
                                 ? RSMSTheme.Colors.textTertiary
                                 : RSMSTheme.Colors.accentGoldLight)
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .stroke(product.inRepair
                        ? RSMSTheme.Colors.warning.opacity(0.4)
                        : RSMSTheme.Colors.borderLight,
                        lineWidth: 1)
        )
    }

    // MARK: - States

    private var loadingView: some View {
        ScrollView {
            LazyVStack(spacing: RSMSTheme.Spacing.md) {
                ForEach(0..<8, id: \.self) { index in
                    skeletonRow
                        .opacity(shimmerOpacity)
                        .animation(
                            .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true)
                                .delay(Double(index) * 0.08),
                            value: shimmerOpacity
                        )
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.lg)
            .padding(.top, RSMSTheme.Spacing.md)
            .padding(.bottom, RSMSTheme.Spacing.xxl)
        }
        .onAppear { shimmerOpacity = 0.3 }
    }

    @State private var shimmerOpacity: Double = 0.6

    private var skeletonRow: some View {
        HStack(spacing: RSMSTheme.Spacing.lg) {
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .fill(RSMSTheme.Colors.backgroundElevated)
                .frame(width: 56, height: 56)

            VStack(alignment: .leading, spacing: RSMSTheme.Spacing.sm) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(RSMSTheme.Colors.backgroundElevated)
                    .frame(width: 140, height: 14)
                RoundedRectangle(cornerRadius: 4)
                    .fill(RSMSTheme.Colors.backgroundElevated)
                    .frame(width: 90, height: 10)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: RSMSTheme.Spacing.sm) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(RSMSTheme.Colors.backgroundElevated)
                    .frame(width: 60, height: 14)
            }
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.largeTitle)
                .foregroundStyle(RSMSTheme.Colors.error)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, RSMSTheme.Spacing.xl)
            Button("Retry") {
                Task { await appState.fetchProducts() }
            }
            .buttonStyle(GoldButtonStyle())
            .frame(width: 140)
        }
    }

    private var emptyView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            Image(systemName: "shippingbox")
                .font(.system(size: 48))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
            Text("No products found")
                .font(.headline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }
}

#Preview {
    NavigationStack {
        ProductsListView()
            .environment(AppState())
    }
}

// MARK: - Repair Form Sheet

struct RepairFormSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppState.self) private var appState

    let product: ProductNew  // ← updated type

    @State private var issueDescription: String = ""
    @State private var repairCostString: String = ""
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String? = nil
    @State private var showErrorAlert: Bool = false

    var body: some View {
        NavigationStack {
            ZStack {
                RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xl) {
                        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.xs) {
                            Text("Product")
                                .font(.caption)
                                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                            Text(product.name)
                                .font(.headline)
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                            Text("SKU: \(product.sku)")
                                .font(.subheadline)
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        }
                        .padding(.bottom, RSMSTheme.Spacing.sm)

                        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                            Text("Issue Description")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)

                            TextField("Describe the damage/issue", text: $issueDescription, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(RSMSTheme.Spacing.md)
                                .background(RSMSTheme.Colors.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        }

                        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
                            Text("Estimated Repair Cost (₹)")
                                .font(.subheadline).fontWeight(.medium)
                                .foregroundStyle(RSMSTheme.Colors.textSecondary)

                            TextField("0.00", text: $repairCostString)
                                .keyboardType(.decimalPad)
                                .padding(RSMSTheme.Spacing.md)
                                .background(RSMSTheme.Colors.backgroundElevated)
                                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                                    .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
                                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                        }

                        Spacer(minLength: RSMSTheme.Spacing.xxl)

                        Button {
                            submit()
                        } label: {
                            if isSubmitting {
                                ProgressView()
                                    .tint(.black)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 52)
                                    .background(RSMSTheme.Colors.goldGradient)
                                    .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
                            } else {
                                Text("Submit to Repair")
                            }
                        }
                        .buttonStyle(GoldButtonStyle())
                        .disabled(issueDescription.isEmpty || repairCostString.isEmpty || isSubmitting)
                        .opacity((issueDescription.isEmpty || repairCostString.isEmpty || isSubmitting) ? 0.5 : 1.0)
                    }
                    .padding(RSMSTheme.Spacing.lg)
                }
            }
            .navigationTitle("Log Repair")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
            }
            .alert("Submit Failed", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred while submitting.")
            }
        }
    }

    private func submit() {
        guard let cost = Double(repairCostString), !issueDescription.isEmpty else { return }
        isSubmitting = true
        errorMessage = nil

        Task {
            let success = await appState.submitRepair(
                for: product,
                issueDescription: issueDescription,
                repairCost: cost
            )
            isSubmitting = false
            if success {
                dismiss()
            } else {
                errorMessage = "Could not apply repair. Verify database connection or requirements."
                showErrorAlert = true
            }
        }
    }
}
