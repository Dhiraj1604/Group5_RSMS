//
//  SalesTransactionsView.swift
//  Group5_RSMS
//
//  Corporate Admin — Sales Transactions
//  Shows individual transactions with date, store, items, amount, category.
//  Supports store + date filtering, search, and tap for full detail.
//

import SwiftUI

struct SalesTransactionsView: View {
    @StateObject private var viewModel = SalesTransactionsViewModel()
    @State private var showDatePicker = false
    @State private var showAllTransactions = false

    private static let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.timeStyle = .short
        return df
    }()

    private static let currencyFormatter: NumberFormatter = {
        let nf = NumberFormatter()
        nf.numberStyle = .currency
        nf.currencySymbol = "₹"
        nf.maximumFractionDigits = 0
        return nf
    }()

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if viewModel.isLoading && viewModel.transactions.isEmpty {
                loadingView
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(spacing: RSMSTheme.Spacing.md) {
                        if viewModel.filteredTransactions.isEmpty {
                            filtersSection
                            inlineEmptyState
                        } else {
                            ViewThatFits {
                                HStack(alignment: .top, spacing: RSMSTheme.Spacing.md) {
                                    filtersSection.frame(maxWidth: .infinity)
                                    summaryBar.frame(maxWidth: .infinity)
                                }
                                VStack(spacing: RSMSTheme.Spacing.md) {
                                    filtersSection
                                    summaryBar
                                }
                            }
                            transactionList
                        }
                    }
                    .padding(.horizontal, RSMSTheme.Spacing.horizontalMargin)
                    .padding(.top, RSMSTheme.Spacing.md)
                    .padding(.bottom, 100)
                    .frame(maxWidth: 1000)
                    .frame(maxWidth: .infinity)
                }
                .refreshable { await viewModel.fetchTransactions() }
            }
        }
        .navigationTitle("Sales Transactions")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .searchable(text: $viewModel.searchText, prompt: "Search by store or category…")
        .task {
            await viewModel.fetchStores()
            await viewModel.fetchTransactions()
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: RSMSTheme.Spacing.lg) {
            ProgressView().tint(RSMSTheme.Colors.accentGold).scaleEffect(1.2)
            Text("Loading transactions…")
                .font(.subheadline)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
        }
    }

    // MARK: - Filters

    private var filtersSection: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            // Row 1: Store picker + date range
            HStack(spacing: RSMSTheme.Spacing.md) {
                storeDropdown
                Spacer()
                // Date range button
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { showDatePicker.toggle() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "calendar")
                            .font(.system(size: 12))
                        Text(dateRangeLabel)
                            .font(.system(size: 12, weight: .semibold))
                        Image(systemName: showDatePicker ? "chevron.up" : "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                    }
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(RSMSTheme.Colors.accentGold.opacity(0.1))
                    .cornerRadius(RSMSTheme.Radius.pill)
                }
            }

            // Row 2: Inline date pickers
            if showDatePicker {
                HStack(spacing: RSMSTheme.Spacing.md) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("FROM")
                            .font(.system(size: 9, weight: .bold)).tracking(1)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        DatePicker("", selection: $viewModel.startDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .tint(RSMSTheme.Colors.accentGold).colorScheme(.dark).labelsHidden()
                    }
                    VStack(alignment: .leading, spacing: 4) {
                        let maxEnd = Calendar.current.date(byAdding: .day, value: 30, to: viewModel.startDate) ?? viewModel.startDate
                        Text("TO (max 30 days)")
                            .font(.system(size: 9, weight: .bold)).tracking(1)
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        DatePicker("", selection: $viewModel.endDate, in: viewModel.startDate...maxEnd, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .tint(RSMSTheme.Colors.accentGold).colorScheme(.dark).labelsHidden()
                    }
                    Spacer()
                    Button {
                        withAnimation(.easeInOut(duration: 0.25)) { showDatePicker = false }
                        Task { await viewModel.fetchTransactions() }
                    } label: {
                        Text("Apply")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(.black)
                            .padding(.horizontal, 16).padding(.vertical, 8)
                            .background(RSMSTheme.Colors.accentGold)
                            .cornerRadius(16)
                    }
                }
            }
        }
        .padding(RSMSTheme.Spacing.lg)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    private var storeDropdown: some View {
        let isFiltered = viewModel.selectedStoreId != nil
        let selectedName = viewModel.stores.first(where: { $0.id == viewModel.selectedStoreId })?.name ?? "All Stores"

        return Menu {
            Button { viewModel.selectedStoreId = nil; Task { await viewModel.fetchTransactions() } } label: {
                HStack { Text("All Stores"); if viewModel.selectedStoreId == nil { Image(systemName: "checkmark") } }
            }
            ForEach(viewModel.stores) { store in
                Button {
                    viewModel.selectedStoreId = store.id
                    Task { await viewModel.fetchTransactions() }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(store.name)
                            Text(store.city).font(.caption)
                        }
                        if viewModel.selectedStoreId == store.id { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack(spacing: RSMSTheme.Spacing.sm) {
                Image(systemName: "storefront.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(isFiltered ? Color.black : RSMSTheme.Colors.accentGold)
                VStack(alignment: .leading, spacing: 1) {
                    Text("STORE")
                        .font(.system(size: 9, weight: .semibold)).tracking(0.8)
                        .foregroundStyle(isFiltered ? Color.black.opacity(0.6) : RSMSTheme.Colors.textTertiary)
                    Text(selectedName)
                        .font(.system(size: 13, weight: .semibold)).lineLimit(1)
                        .foregroundStyle(isFiltered ? Color.black : RSMSTheme.Colors.textPrimary)
                }
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(isFiltered ? Color.black.opacity(0.6) : RSMSTheme.Colors.textSecondary)
            }
            .padding(.horizontal, RSMSTheme.Spacing.lg)
            .padding(.vertical, RSMSTheme.Spacing.md)
            .background(isFiltered ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md))
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
                .stroke(isFiltered ? Color.clear : RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }

    private var dateRangeLabel: String {
        let df = DateFormatter()
        df.dateFormat = "d MMM"
        return "\(df.string(from: viewModel.startDate)) – \(df.string(from: viewModel.endDate))"
    }

    // MARK: - Summary Bar

    private var summaryBar: some View {
        let txns = viewModel.filteredTransactions
        let total = txns.reduce(0) { $0 + $1.totalAmount }
        let avgItems = txns.isEmpty ? 0.0 : Double(txns.reduce(0) { $0 + $1.itemCount }) / Double(txns.count)

        return HStack(spacing: 0) {
            summaryCell(label: "Transactions", value: "\(txns.count)")
            Divider().background(RSMSTheme.Colors.borderLight).frame(height: 30)
            summaryCell(label: "Total Revenue", value: formatCurrency(total))
            Divider().background(RSMSTheme.Colors.borderLight).frame(height: 30)
            summaryCell(label: "Avg Items", value: String(format: "%.1f", avgItems))
        }
        .padding(.vertical, RSMSTheme.Spacing.md)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    private func summaryCell(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(RSMSTheme.Colors.accentGold)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(RSMSTheme.Colors.textTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Transaction List

    private var transactionList: some View {
        let txns = viewModel.filteredTransactions
        let visibleTxns = showAllTransactions ? txns : Array(txns.prefix(5))

        return VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Date / Store").frame(maxWidth: .infinity, alignment: .leading)
                Text("Items").frame(width: 40, alignment: .trailing)
                Text("Amount").frame(width: 80, alignment: .trailing)
            }
            .font(.system(size: 12, weight: .bold))
            .foregroundStyle(RSMSTheme.Colors.textSecondary)
            .padding(.horizontal, 14).padding(.vertical, 12)
            .background(RSMSTheme.Colors.backgroundElevated)
            .cornerRadius(RSMSTheme.Radius.md, corners: [.topLeft, .topRight])

            ForEach(Array(visibleTxns.enumerated()), id: \.element.id) { index, txn in
                NavigationLink(destination: SalesTransactionDetailView(transaction: txn)) {
                    transactionRow(txn: txn, index: index, total: txns.count)
                }
                .buttonStyle(.plain)
            }

            if txns.count > 5 {
                Button {
                    withAnimation(.easeInOut(duration: 0.25)) {
                        showAllTransactions.toggle()
                    }
                } label: {
                    HStack {
                        Spacer()
                        Text(showAllTransactions ? "Show Less" : "See More (\(txns.count - 5) more)")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        Image(systemName: showAllTransactions ? "chevron.up" : "chevron.down")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        Spacer()
                    }
                    .padding(.vertical, 16)
                    .background(RSMSTheme.Colors.accentGold.opacity(0.05))
                }
            }
        }
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.md)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.md)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    private func transactionRow(txn: SalesTransaction, index: Int, total: Int) -> some View {
        VStack(spacing: 0) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(Self.dateFormatter.string(from: txn.date))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(RSMSTheme.Colors.textPrimary)
                    HStack(spacing: 4) {
                        Image(systemName: "storefront.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(RSMSTheme.Colors.accentGold)
                        Text(txn.storeName)
                            .font(.system(size: 11))
                            .foregroundStyle(RSMSTheme.Colors.textSecondary)
                        if let cat = txn.category {
                            Text("·")
                                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                            Text(cat)
                                .font(.system(size: 11))
                                .foregroundStyle(RSMSTheme.Colors.textTertiary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Text("\(txn.itemCount)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .frame(width: 40, alignment: .trailing)

                Text(formatCurrency(txn.totalAmount))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .frame(width: 80, alignment: .trailing)

                Image(systemName: "chevron.right")
                    .font(.system(size: 10))
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                    .padding(.leading, 6)
            }
            .padding(.horizontal, 14).padding(.vertical, 12)

            if index < (showAllTransactions ? total : min(total, 5)) - 1 {
                Divider().background(Color.white.opacity(0.05)).padding(.leading, 14)
            }
        }
    }

    // MARK: - Empty State

    private var inlineEmptyState: some View {
        VStack(spacing: RSMSTheme.Spacing.md) {
            Image(systemName: "receipt")
                .font(.system(size: 40))
                .foregroundStyle(RSMSTheme.Colors.accentGold.opacity(0.25))
            Text("No Transactions Found")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            Text("No transactions match the selected store and date range.\nTry adjusting the filters.")
                .font(.system(size: 13))
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RSMSTheme.Spacing.xxxl)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
            .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))
    }

    // MARK: - Helpers

    private func formatCurrency(_ value: Double) -> String {
        if value >= 100000 { return "₹\(String(format: "%.1f", value/100000))L" }
        if value >= 1000   { return "₹\(String(format: "%.1f", value/1000))K" }
        return "₹\(Int(value))"
    }
}

// MARK: - RoundedRectangle corner helper

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

private struct RoundedCorner: Shape {
    var radius: CGFloat
    var corners: UIRectCorner
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

#Preview {
    NavigationStack { SalesTransactionsView().environment(AppState()) }
}
