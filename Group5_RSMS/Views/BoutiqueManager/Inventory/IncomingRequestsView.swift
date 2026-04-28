//
//  IncomingRequestsView.swift
//  Group5_RSMS
//
//  Boutique Manager — Lists pending transfer requests requiring fulfillment.
//  Swipe left on a request to reveal Accept / Reject actions.
//

import SwiftUI

struct IncomingRequestsView: View {
    let currentStoreName: String
    @ObservedObject var viewModel: BMInventoryViewModel
    @Environment(AppState.self) private var appState
    @State private var selectedRequest: TransferRequest? = nil
    @State private var rejectingRequestId: UUID? = nil
    @State private var showRejectConfirm: Bool = false

    var body: some View {
        ZStack {
            RSMSTheme.Colors.backgroundPrimary.ignoresSafeArea()

            if viewModel.isLoadingRequests {
                loadingState
            } else if viewModel.incomingRequests.isEmpty {
                emptyState
            } else {
                requestsList
            }
        }
        .navigationTitle("Incoming Requests")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedRequest) { request in
            FulfillRequestSheet(
                request: request,
                currentStoreName: currentStoreName,
                viewModel: viewModel
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .confirmationDialog(
            "Reject this request?",
            isPresented: $showRejectConfirm,
            titleVisibility: .visible
        ) {
            Button("Reject Request", role: .destructive) {
                guard let reqId = rejectingRequestId,
                      let request = viewModel.incomingRequests.first(where: { $0.id == reqId })
                else { return }
                Task {
                    await viewModel.rejectRequest(request, currentStoreName: currentStoreName)
                }
            }
            Button("Cancel", role: .cancel) { rejectingRequestId = nil }
        } message: {
            Text("The requesting boutique will be notified of the rejection. No inventory changes will be made.")
        }
        .task {
            if let storeId = appState.currentStoreID {
                await viewModel.loadIncomingRequests(forStore: storeId)
            }
        }
    }

    // MARK: - Requests List

    private var requestsList: some View {
        List {
            // Swipe hint
            HStack(spacing: 6) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 11))
                Text("Swipe left to accept or reject")
                    .font(.system(size: 11, weight: .medium))
            }
            .foregroundColor(RSMSTheme.Colors.textTertiary)
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)

            ForEach(viewModel.incomingRequests) { request in
                requestCard(request)
                    .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        // Reject (furthest from edge — appears on the right)
                        Button {
                            rejectingRequestId = request.id
                            showRejectConfirm = true
                        } label: {
                            Label("Reject", systemImage: "xmark.circle.fill")
                        }
                        .tint(RSMSTheme.Colors.error)

                        // Accept (closer to edge — appears on the left)
                        Button {
                            selectedRequest = request
                        } label: {
                            Label("Accept", systemImage: "checkmark.circle.fill")
                        }
                        .tint(RSMSTheme.Colors.success)
                    }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .refreshable {
            if let storeId = appState.currentStoreID {
                await viewModel.loadIncomingRequests(forStore: storeId)
            }
        }
    }

    // MARK: - Request Card (compact horizontal)

    private func requestCard(_ request: TransferRequest) -> some View {
        HStack(spacing: 12) {
            // Product Thumbnail
            Group {
                if let urlString = request.productImageUrl,
                   let url = URL(string: urlString) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().aspectRatio(contentMode: .fill)
                        case .failure, .empty:
                            productPlaceholder
                        @unknown default:
                            productPlaceholder
                        }
                    }
                } else {
                    productPlaceholder
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text(request.productName)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(RSMSTheme.Colors.textPrimary)
                    .lineLimit(1)

                Text("From: \(request.requestingStoreName)")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 4)

            // Quantity badge
            VStack(spacing: 1) {
                Text("\(request.quantity)")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(RSMSTheme.Colors.accentGold)
                Text("QTY")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(RSMSTheme.Colors.accentGoldDark)
                    .tracking(0.4)
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(14)
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.25), radius: 6, x: 0, y: 3)
    }

    private var productPlaceholder: some View {
        ZStack {
            RSMSTheme.Colors.backgroundElevated
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 14, weight: .light))
                .foregroundColor(RSMSTheme.Colors.accentGoldDark.opacity(0.4))
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().tint(RSMSTheme.Colors.accentGold).scaleEffect(1.5)
            Text("Checking for requests…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Spacer()
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.border.opacity(0.5))
                    .frame(width: 88, height: 88)
                Image(systemName: "tray.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
            }
            VStack(spacing: 8) {
                Text("No Incoming Requests")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("There are no pending stock requests\nfrom other boutiques at this time.")
                    .font(.system(size: 15))
                    .foregroundColor(RSMSTheme.Colors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}
