//
//  AuditLogsView.swift
//  Group5_RSMS
//

import SwiftUI

struct AuditLogsView: View {
    @StateObject private var viewModel = AuditLogsViewModel()
    @State private var animateIn = false

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            VStack(spacing: 0) {
                // Search Bar and Dropdowns side by side on iPad
                ViewThatFits {
                    HStack(alignment: .top, spacing: 12) {
                        searchBar.frame(maxWidth: .infinity)
                        dropdownFilterRow.frame(maxWidth: .infinity)
                    }
                    VStack(spacing: 12) {
                        searchBar
                        dropdownFilterRow
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)
                .frame(maxWidth: 1000)
                .frame(maxWidth: .infinity)

                Divider()
                    .background(Color.white.opacity(0.06))

                // Content
                ZStack {
                    if viewModel.isLoading {
                        ProgressView()
                            .tint(RSMSTheme.Colors.accentGold)
                            .scaleEffect(1.5)
                    } else if viewModel.isEmpty {
                        emptyState
                    } else {
                        logList
                    }
                }
            }
        }
        .navigationTitle("Audit Logs")
        .navigationBarTitleDisplayMode(.large)
        .toolbarBackground(RSMSTheme.Colors.backgroundPrimary, for: .navigationBar)
        
        .task {
            await viewModel.loadLogs()
            withAnimation(.easeOut(duration: 0.5)) { animateIn = true }
        }
        .alert("Database Error", isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { _ in viewModel.errorMessage = nil }
        )) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    // MARK: - Search Bar
    private var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)

            ZStack(alignment: .leading) {
                if viewModel.searchText.isEmpty {
                    Text("Search logs, users, entities…")
                        .font(.system(size: 15))
                        .foregroundColor(RSMSTheme.Colors.textSecondary.opacity(0.6))
                }
                TextField("", text: $viewModel.searchText)
                    .font(.system(size: 15))
                    .foregroundColor(.white)
                    .tint(RSMSTheme.Colors.accentGold)
            }

            if !viewModel.searchText.isEmpty {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) { viewModel.searchText = "" }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 15))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(RSMSTheme.Colors.backgroundElevated)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.Colors.accentGold.opacity(0.15), lineWidth: 0.5)
        )
    }

    // MARK: - Dropdown Filter Row
    private var dropdownFilterRow: some View {
        HStack(spacing: 10) {

            // Category Dropdown
            Menu {
                ForEach(AuditCategoryFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation { viewModel.selectedCategory = filter }
                    } label: {
                        HStack {
                            Text(filter.rawValue)
                            if viewModel.selectedCategory == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                dropdownLabel(
                    prefix: "Category",
                    value: viewModel.selectedCategory.rawValue,
                    isActive: viewModel.selectedCategory != .all
                )
            }
            .frame(maxWidth: .infinity)

            // Operation Dropdown
            Menu {
                ForEach(AuditOperationFilter.allCases, id: \.self) { filter in
                    Button {
                        withAnimation { viewModel.selectedOperation = filter }
                    } label: {
                        HStack {
                            Text(filter.rawValue)
                            if viewModel.selectedOperation == filter {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            } label: {
                dropdownLabel(
                    prefix: "Operation",
                    value: viewModel.selectedOperation.rawValue,
                    isActive: viewModel.selectedOperation != .all
                )
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: - Dropdown Label Button
    private func dropdownLabel(prefix: String, value: String, isActive: Bool) -> some View {
        HStack(spacing: 6) {
            VStack(alignment: .leading, spacing: 1) {
                Text(prefix.uppercased())
                    .font(.system(size: 9, weight: .semibold))
                    .tracking(0.8)
                    .foregroundColor(isActive ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textSecondary.opacity(0.7))

                Text(value)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(isActive ? RSMSTheme.Colors.accentGold : .white)
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.down")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(isActive ? RSMSTheme.Colors.accentGold : RSMSTheme.Colors.textSecondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            isActive
                ? RSMSTheme.Colors.accentGold.opacity(0.10)
                : RSMSTheme.Colors.backgroundElevated
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isActive
                        ? RSMSTheme.Colors.accentGold.opacity(0.4)
                        : RSMSTheme.Colors.accentGold.opacity(0.12),
                    lineWidth: isActive ? 1 : 0.5
                )
        )
    }

    // MARK: - Log List
    private var logList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 12) {
                ForEach(Array(viewModel.filteredLogs.enumerated()), id: \.element.id) { index, log in
                    NavigationLink(destination: AuditLogDetailView(log: log)) {
                        AuditLogCard(log: log)
                    }
                    .buttonStyle(.plain)
                    .opacity(animateIn ? 1 : 0)
                    .offset(y: animateIn ? 0 : 18)
                    .animation(.easeOut(duration: 0.4).delay(Double(index) * 0.07), value: animateIn)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
            .frame(maxWidth: 1000)
            .frame(maxWidth: .infinity)
        }
        .refreshable {
            await viewModel.loadLogs()
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.accentGold.opacity(0.08))
                    .frame(width: 88, height: 88)
                Image(systemName: "doc.text.magnifyingglass")
                    .font(.system(size: 36, weight: .light))
                    .foregroundStyle(RSMSTheme.Colors.goldGradient)
            }
            VStack(spacing: 8) {
                Text("No Logs Found")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("Try adjusting your filters or search\nterm to find what you're looking for.")
                    .font(.system(size: 15))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Button {
                withAnimation {
                    viewModel.selectedCategory  = .all
                    viewModel.selectedOperation = .all
                    viewModel.searchText        = ""
                }
                Task {
                    await viewModel.loadLogs()
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Reset Filters")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(RSMSTheme.Colors.goldGradient)
                .cornerRadius(50)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}
