//
//  MyRequestsView.swift
//  Group5_RSMS
//
//  Boutique Manager — Outbound pending/accepted requests.
//

import SwiftUI

struct MyRequestsView: View {
    let currentStoreName: String
    @ObservedObject var viewModel: BMInventoryViewModel

    var body: some View {
        ZStack {
            if viewModel.isLoadingMyRequests {
                loadingState
            } else if viewModel.myRequests.isEmpty {
                emptyState
            } else {
                requestsList
            }
        }
        .navigationTitle("My Requests")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var requestsList: some View {
        ScrollView(showsIndicators: false) {
            LazyVStack(spacing: 14) {
                ForEach(viewModel.myRequests) { request in
                    requestCard(request)
                }
            }
            .padding(.horizontal, RSMSTheme.Spacing.lg)
            .padding(.top, RSMSTheme.Spacing.lg)
            .padding(.bottom, 40)
        }
    }

    private func requestCard(_ request: TransferRequest) -> some View {
        // Map status
        let isAccepted = request.status == .fulfilled
        let statusString = isAccepted ? "Accepted" : "Pending"
        let statusColor = isAccepted ? RSMSTheme.Colors.success : RSMSTheme.Colors.warning

        return VStack(spacing: 0) {
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
                .clipShape(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm))
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm).stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5))

                VStack(alignment: .leading, spacing: 4) {
                    Text(request.productName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.textPrimary)
                        .lineLimit(1)
                    
                    Text("To: \(request.fulfillingStoreName)")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(RSMSTheme.Colors.textSecondary)

                    Text(request.createdAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.system(size: 10, weight: .regular))
                        .foregroundColor(RSMSTheme.Colors.textTertiary)
                }

                Spacer()

                // Quantity requested
                VStack(spacing: 2) {
                    Text("\(request.quantity)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(RSMSTheme.Colors.accentGold)
                    Text("Qty")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(RSMSTheme.Colors.accentGoldDark)
                        .textCase(.uppercase)
                        .tracking(0.4)
                }
            }

            Divider()
                .background(RSMSTheme.Colors.borderLight)
                .padding(.vertical, RSMSTheme.Spacing.md)

            // Status Badge
            HStack(spacing: 6) {
                Image(systemName: isAccepted ? "checkmark.circle.fill" : "clock.fill")
                    .font(.system(size: 12))
                Text(statusString)
                    .font(.system(size: 13, weight: .bold))
                Spacer()
            }
            .foregroundColor(statusColor)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: RSMSTheme.Radius.sm)
                    .fill(statusColor.opacity(0.1))
            )
        }
        .padding(16)
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }

    private var productPlaceholder: some View {
        ZStack {
            RSMSTheme.Colors.backgroundElevated
            Image(systemName: "shippingbox.fill")
                .font(.system(size: 16, weight: .light))
                .foregroundColor(RSMSTheme.Colors.accentGoldDark.opacity(0.4))
        }
    }

    private var loadingState: some View {
        VStack(spacing: 16) {
            Spacer()
            ProgressView().tint(RSMSTheme.Colors.accentGold).scaleEffect(1.5)
            Text("Loading requests…")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(RSMSTheme.Colors.textSecondary)
            Spacer()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(RSMSTheme.Colors.border.opacity(0.5))
                    .frame(width: 88, height: 88)
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 36, weight: .light))
                    .foregroundColor(RSMSTheme.Colors.textTertiary)
            }
            VStack(spacing: 8) {
                Text("No Outbound Requests")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                Text("You haven't requested stock\nfrom any boutiques. ")
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
