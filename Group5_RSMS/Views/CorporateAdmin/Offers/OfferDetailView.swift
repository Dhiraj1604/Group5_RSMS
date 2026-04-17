import SwiftUI
import Charts

struct OfferDetailView: View {
    @Environment(\.dismiss) private var dismiss
    
    let offer: Offer
    @ObservedObject var service: OfferService
    
    @State private var showEditSheet = false
    @State private var isRestarting = false
    @State private var showDeleteConfirm = false
    @State private var isDeleting = false
    @State private var actionError: String? = nil
    @State private var showErrorAlert = false
    
    var currentOffer: Offer {
        service.offers.first(where: { $0.id == offer.id }) ?? offer
    }
    
    let mockTrendData: [DailyRevenue] = [
        .init(day: "Mon", revenue: 12000), .init(day: "Tue", revenue: 18000),
        .init(day: "Wed", revenue: 15000), .init(day: "Thu", revenue: 25000),
        .init(day: "Fri", revenue: 32000), .init(day: "Sat", revenue: 45000),
        .init(day: "Sun", revenue: 41000)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: RSMSTheme.Spacing.xl) {
                headerSection
                statusSection
                metricsSection
                chartSection
                configurationSection
                storesSection
            }
            .padding(.vertical, RSMSTheme.Spacing.lg)
            .padding(.horizontal, RSMSTheme.Spacing.md)
        }
        .background(RSMSTheme.Colors.backgroundPrimary)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    if currentOffer.computedStatus != .expired {
                        Button(action: {
                            isRestarting = false
                            showEditSheet = true
                        }) {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        Button(action: { togglePause() }) {
                            Label(currentOffer.isPaused ? "Resume" : "Pause", systemImage: currentOffer.isPaused ? "play.fill" : "pause.fill")
                        }
                        
                        Button(role: .destructive, action: { endEarly() }) {
                            Label("End Early", systemImage: "stop.fill")
                        }
                    } else {
                        Button(action: {
                            isRestarting = true
                            showEditSheet = true
                        }) {
                            Label("Restart", systemImage: "arrow.clockwise")
                        }
                    }
                    
                    Button(role: .destructive, action: { showDeleteConfirm = true }) {
                        Label("Delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .fontWeight(.semibold)
                        .foregroundStyle(RSMSTheme.Colors.accentGold)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditOfferView(offer: currentOffer, service: service, isRestarting: isRestarting)
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK") { actionError = nil }
        } message: {
            Text(actionError ?? "An unknown error occurred.")
        }
        .confirmationDialog("Delete this promotion?", isPresented: $showDeleteConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { performDelete() }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. The offer will be permanently removed.")
        }
        .overlay {
            if isDeleting {
                ZStack {
                    Color.black.opacity(0.4).ignoresSafeArea()
                    ProgressView("Deleting…")
                        .padding()
                        .background(RSMSTheme.Colors.backgroundElevated)
                        .cornerRadius(12)
                }
            }
        }
    }
    
    // MARK: - Sections
    
    private var headerSection: some View {
        VStack(spacing: RSMSTheme.Spacing.sm) {
            OfferStatusPill(status: currentOffer.computedStatus)
            
            Text(currentOffer.name)
                .font(.custom("Helvetica", size: 28).weight(.bold))
                .multilineTextAlignment(.center)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            Text(currentOffer.discountLabel)
                .font(.custom("Helvetica", size: 40).weight(.heavy))
                .foregroundStyle(RSMSTheme.Colors.goldGradient)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, RSMSTheme.Spacing.md)
    }
    
    private var statusSection: some View {
        HStack {
            VStack(alignment: .center, spacing: 4) {
                Text("APPLICABLE TO")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                Text(currentOffer.applicableTo ?? "All Products")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textPrimary)
            }
            Spacer()
            Divider().background(RSMSTheme.Colors.borderLight).frame(height: 30)
            Spacer()
            VStack(alignment: .center, spacing: 4) {
                Text("REMAINING")
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textTertiary)
                HStack(spacing: 4) {
                    Image(systemName: "clock.fill")
                        .font(.caption)
                    Text("\(daysRemaining(for: currentOffer)) Days")
                        .font(.subheadline)
                }
                .foregroundStyle(RSMSTheme.Colors.warning)
            }
        }
        .padding()
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
    
    private var metricsSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Performance")
                .font(.custom("Helvetica", size: 18).weight(.semibold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            HStack(spacing: RSMSTheme.Spacing.md) {
                DashboardMetricCard(title: "Revenue", value: "₹1.88L")
                DashboardMetricCard(title: "Orders", value: "142")
                DashboardMetricCard(title: "AOV", value: "₹1,323")
            }
        }
    }
    
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Revenue Trend")
                .font(.custom("Helvetica", size: 18).weight(.semibold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            Chart(mockTrendData) { item in
                LineMark(x: .value("Day", item.day), y: .value("Revenue", item.revenue))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                
                AreaMark(x: .value("Day", item.day), y: .value("Revenue", item.revenue))
                    .interpolationMethod(.catmullRom)
                    .foregroundStyle(LinearGradient(colors: [RSMSTheme.Colors.accentGold.opacity(0.3), Color.clear], startPoint: .top, endPoint: .bottom))
            }
            .frame(height: 180)
            .padding()
            .background(RSMSTheme.Colors.backgroundDeep)
            .cornerRadius(RSMSTheme.Radius.lg)
            .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
        }
    }
    
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Configuration")
                .font(.custom("Helvetica", size: 18).weight(.semibold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: RSMSTheme.Spacing.md) {
                DashboardConfigCard(icon: "ticket.fill", title: "Rule", value: currentOffer.discountLabel + " above ₹5000")
                DashboardConfigCard(icon: currentOffer.activationMethod == "coupon" ? "tag.fill" : "wand.and.stars", title: "Activation", value: currentOffer.activationMethod == "coupon" ? "Coupon Code" : "Auto Apply")
                if currentOffer.activationMethod == "coupon", let code = currentOffer.couponCode {
                    DashboardConfigCard(icon: "number", title: "Code", value: code)
                }
                DashboardConfigCard(icon: "square.3.layers.3d.down.left", title: "Stackable", value: currentOffer.isStackable ? "Yes" : "No")
                DashboardConfigCard(icon: "person.2.fill", title: "Usage Limit", value: currentOffer.usageLimit != nil ? "\(currentOffer.usageLimit!) / user" : "Unlimited")
                DashboardConfigCard(icon: "exclamationmark.triangle.fill", title: "Penalty", value: currentOffer.performancePenalty ?? "None")
            }
        }
    }
    
    private var storesSection: some View {
        VStack(alignment: .leading, spacing: RSMSTheme.Spacing.md) {
            Text("Assigned Stores")
                .font(.custom("Helvetica", size: 18).weight(.semibold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
            
            let assignedStores = service.stores.filter { currentOffer.assignedStoreIds.contains($0.id) }
            
            if assignedStores.isEmpty {
                Text("No stores assigned.")
                    .font(.subheadline)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .center)
                    .background(RSMSTheme.Colors.backgroundDeep)
                    .cornerRadius(RSMSTheme.Radius.lg)
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(assignedStores.enumerated()), id: \.element.id) { index, store in
                        DashboardStoreRow(store: store, isLast: index == assignedStores.count - 1)
                    }
                }
                .background(RSMSTheme.Colors.backgroundDeep)
                .cornerRadius(RSMSTheme.Radius.lg)
                .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
            }
        }
    }
    
    // MARK: - Actions
    
    private func togglePause() {
        var updated = currentOffer
        updated.isPaused.toggle()
        service.updateOffer(updated)
    }
    
    private func endEarly() {
        var updated = currentOffer
        updated.endDate = Date()
        updated.isPaused = false // unpause if it was paused
        service.updateOffer(updated)
    }
    
    private func performDelete() {
        isDeleting = true
        service.softDeleteOffer(currentOffer) { success in
            isDeleting = false
            if success {
                dismiss()
            } else {
                actionError = service.errorMessage ?? "Failed to delete offer."
                showErrorAlert = true
            }
        }
    }
    
    private func daysRemaining(for targetOffer: Offer) -> Int {
        let components = Calendar.current.dateComponents([.day], from: Date(), to: targetOffer.endDate)
        return max(0, components.day ?? 0)
    }
}

// MARK: - Subviews

struct DashboardMetricCard: View {
    let title: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(RSMSTheme.Colors.textSecondary)
            Text(value)
                .font(.custom("Helvetica", size: 20).weight(.bold))
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RSMSTheme.Colors.backgroundDeep)
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg).stroke(RSMSTheme.Colors.borderLight, lineWidth: 1))
    }
}

struct DashboardConfigCard: View {
    let icon: String
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .font(.system(size: 16))
                Text(title)
                    .font(.caption)
                    .foregroundStyle(RSMSTheme.Colors.textSecondary)
                Spacer()
            }
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundStyle(RSMSTheme.Colors.textPrimary)
                .lineLimit(2)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .topLeading)
        .background(
            LinearGradient(
                colors: [RSMSTheme.Colors.backgroundDeep, RSMSTheme.Colors.backgroundDeep.opacity(0.5)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(RSMSTheme.Radius.lg)
        .overlay(
            RoundedRectangle(cornerRadius: RSMSTheme.Radius.lg)
                .stroke(RSMSTheme.Colors.borderLight, lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }
}

struct DashboardStoreRow: View {
    let store: OfferStore
    let isLast: Bool
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "mappin.circle.fill")
                    .foregroundStyle(RSMSTheme.Colors.accentGold)
                    .font(.title2)
                VStack(alignment: .leading) {
                    Text(store.name).font(.subheadline).foregroundStyle(RSMSTheme.Colors.textPrimary)
                    Text(store.city).font(.caption).foregroundStyle(RSMSTheme.Colors.textSecondary)
                }
                Spacer()
            }
            .padding()
            if !isLast {
                Divider().background(RSMSTheme.Colors.borderLight).padding(.leading)
            }
        }
    }
}

struct DailyRevenue: Identifiable {
    let id = UUID()
    let day: String
    let revenue: Double
}

// MARK: - EditOfferView Sheet

struct EditOfferView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var draftOffer: Offer
    let service: OfferService
    let isRestarting: Bool
    @State private var isSaving = false
    @State private var showErrorAlert = false
    @State private var actionError: String? = nil
    @State private var draftUsageLimitStr: String
    @State private var storeSearchText = ""
    @State private var draftActivationMethod: String
    @State private var draftCouponCode: String
    
    init(offer: Offer, service: OfferService, isRestarting: Bool = false) {
        var initialOffer = offer
        if isRestarting {
            initialOffer.startDate = Date()
            initialOffer.endDate = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            initialOffer.isPaused = false
        }
        self._draftOffer = State(initialValue: initialOffer)
        self.service = service
        self.isRestarting = isRestarting
        self._draftUsageLimitStr = State(initialValue: offer.usageLimit != nil ? "\(offer.usageLimit!)" : "")
        self._draftActivationMethod = State(initialValue: offer.activationMethod)
        self._draftCouponCode = State(initialValue: offer.couponCode ?? "")
    }

    private let scopeOptions = ["All Products", "Handbags", "Footwear", "Accessories", "Fragrances", "Ready-to-wear"]
    
    private var filteredStores: [OfferStore] {
        if storeSearchText.isEmpty {
            return service.stores
        } else {
            return service.stores.filter { $0.name.localizedCaseInsensitiveContains(storeSearchText) || $0.city.localizedCaseInsensitiveContains(storeSearchText) }
        }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Promotion Details")) {
                    TextField("Promotion Name", text: $draftOffer.name)
                    Picker("Discount Type", selection: $draftOffer.discountType) {
                        ForEach(DiscountType.allCases, id: \.self) { dt in Text(dt.displayName).tag(dt) }
                    }
                    HStack {
                        Text(draftOffer.discountType == .percentage ? "Discount (%)" : "Amount (₹)")
                        Spacer()
                        TextField("Value", value: $draftOffer.discountValue, format: .number)
                            .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                    }
                    Picker("Applicable To", selection: Binding(
                        get: { draftOffer.applicableTo ?? "All Products" },
                        set: { draftOffer.applicableTo = $0 == "All Products" ? nil : $0 }
                    )) {
                        ForEach(scopeOptions, id: \.self) { opt in Text(opt).tag(opt) }
                    }
                }

                Section(header: Text("Offer Period")) {
                    DatePicker("Start Date", selection: $draftOffer.startDate, displayedComponents: [.date, .hourAndMinute])
                    DatePicker("End Date", selection: $draftOffer.endDate, in: draftOffer.startDate..., displayedComponents: [.date, .hourAndMinute])
                }
                
                Section(header: Text("Configuration")) {
                    Picker("Activation Method", selection: $draftActivationMethod) {
                        Text("Auto Apply").tag("auto")
                        Text("Coupon Code").tag("coupon")
                    }
                    if draftActivationMethod == "coupon" {
                        HStack {
                            Text("Coupon Code")
                            Spacer()
                            TextField("e.g. DIWALI25", text: $draftCouponCode)
                                .textInputAutocapitalization(.characters)
                                .multilineTextAlignment(.trailing)
                        }
                    }
                    Toggle("Stackable", isOn: $draftOffer.isStackable)
                    HStack {
                        Text("Usage Limit")
                        Spacer()
                        TextField("Unlimited", text: $draftUsageLimitStr)
                            .keyboardType(.numberPad).multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Assign to Stores")) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundColor(RSMSTheme.Colors.textTertiary)
                        TextField("Search stores...", text: $storeSearchText)
                    }
                    ForEach(filteredStores) { store in
                        let isOn = draftOffer.assignedStoreIds.contains(store.id)
                        Button {
                            withAnimation {
                                if isOn { draftOffer.assignedStoreIds.removeAll(where: { $0 == store.id }) }
                                else { draftOffer.assignedStoreIds.append(store.id) }
                            }
                        } label: {
                            HStack {
                                Text(store.name).foregroundColor(RSMSTheme.Colors.textPrimary)
                                Spacer()
                                if isOn { Image(systemName: "checkmark").foregroundColor(RSMSTheme.Colors.accentGold) }
                            }
                        }
                    }
                }

                Section(header: Text("Conditions (Optional)")) {
                    TextField("Penalty / Condition", text: Binding(
                        get: { draftOffer.performancePenalty ?? "" },
                        set: { draftOffer.performancePenalty = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            .navigationTitle(isRestarting ? "Restart Promotion" : "Edit Promotion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }.disabled(isSaving)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isSaving {
                        ProgressView()
                    } else {
                        Button("Save") {
                            draftOffer.usageLimit = Int(draftUsageLimitStr)
                            draftOffer.activationMethod = draftActivationMethod
                            draftOffer.couponCode = draftActivationMethod == "coupon" ? (draftCouponCode.isEmpty ? nil : draftCouponCode) : nil
                            isSaving = true
                            service.updateOffer(draftOffer) { success in
                                isSaving = false
                                if success { dismiss() }
                                else {
                                    actionError = service.errorMessage ?? "Failed to save."
                                    showErrorAlert = true
                                }
                            }
                        }
                        .fontWeight(.bold)
                    }
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK") { actionError = nil }
            } message: {
                Text(actionError ?? "Unknown error")
            }
        }
        .colorScheme(.dark)
    }
}
