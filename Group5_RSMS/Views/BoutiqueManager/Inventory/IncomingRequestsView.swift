//
//  IncomingRequestsView.swift
//  Group5_RSMS
//
//  Boutique Manager — Lists pending transfer requests requiring fulfillment.
//

import SwiftUI

struct IncomingRequestsView: View {
    let currentStoreName: String
    @ObservedObject var viewModel: BMInventoryViewModel
    @State private var selectedRequest: TransferRequest? = nil

    var body: some View {
        ZStack {
            if viewModel.isLoadingRequests {
                loadingState
            } else if viewModel.incomingRequests.isEmpty {
                emptyState
            } else {
                requestsList
            }
        }
        .sheet(item: $selectedRequest) { request in
            FulfillRequestSheet(
                request: request,
                currentStoreName: currentStoreName,
                viewModel: viewModel
            )
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Requests List

    private var requestsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.incomingRequests) { request in
                    requestCard(request)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    private func requestCard(_ request: TransferRequest) -> some View {
        VStack(spacing: 0) {
            // Top Section (Store & Product)
            HStack(alignment: .top, spacing: 14) {
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
                .frame(width: 50, height: 50)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.productName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(Color.primary)
                        .lineLimit(1)
                    
                    Text("Requested by: \(request.requestingStoreName)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(Color.secondary)

                    Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(Color.secondary)
                }

                Spacer()

                // Quantity requested
                VStack(spacing: 2) {
                    Text("\(request.quantity)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(Color.accentColor)
                    Text("Qty")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(Color.accentColor)
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
            }

            Divider()
                .background(Color(UIColor.separator).opacity(0.5))
                .padding(.vertical, 12)

            // Fulfill Button
            Button {
                selectedRequest = request
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "box.truck.badge.clock.fill")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Review Fulfillment")
                        .font(.system(size: 13, weight: .bold))
                    Spacer()
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(Color.primary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.accentColor)
                )
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(UIColor.separator).opacity(0.5), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private var productPlaceholder: some View {
        ZStack {
            Color(UIColor.secondarySystemGroupedBackground)
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(Color.accentColor.opacity(0.4))
        }
    }

    // MARK: - Loading State
    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().tint(Color.accentColor).scaleEffect(1.5)
            Text("Checking for requests…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(Color.secondary)
            Spacer()
        }
    }

    // MARK: - Empty State
    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(Color(UIColor.separator).opacity(0.5))
                    .frame(width: 88, height: 88)
                Image(systemName: "tray.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(Color.secondary)
            }
            VStack(spacing: 8) {
                Text("No Incoming Requests")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("There are no pending stock requests\nfrom other boutiques at this time.")
                    .font(.system(size: 15))
                    .foregroundColor(Color.secondary)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
            Spacer()
        }
        .padding(.horizontal, 28)
    }
}
