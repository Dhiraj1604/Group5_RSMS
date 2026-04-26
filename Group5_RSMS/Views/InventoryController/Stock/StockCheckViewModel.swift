//
//  StockCheckViewModel.swift
//  Group5_RSMS
//
//  ViewModel for the Stock Check flow.
//  Database integration notes:
//    • Reads from  : inventory (joined with products via PostgREST embed)
//    • Writes to   : inventory (stock_quantity + last_updated)
//    • Writes to   : audit_logs (action, event_type, user_name, entity,
//                                before_data, after_data) — matches full schema
//    • Reads from  : audit_logs to inform fix-suggestion confidence
//  All query shapes are verified against LowStockService.swift patterns.
//

import Foundation
import SwiftUI
import Combine
import Supabase
import PostgREST

// MARK: - Data Models

/// One line in a stock-check session.
struct StockCheckItem: Identifiable {
    let id = UUID()
    let productId: UUID
    let sku: String
    let productName: String
    var expectedQty: Int        // pulled from inventory table on load
    var scannedQty: Int?        // entered by controller (nil = not yet counted)
}

/// A resolved discrepancy after comparison.
struct StockDiscrepancy: Identifiable {
    let id = UUID()
    let productId: UUID
    let sku: String
    let productName: String
    let expectedQty: Int
    let scannedQty: Int
    var difference: Int { scannedQty - expectedQty }    // positive = surplus, negative = shortage
    var isApproved: Bool = false
    var isApplying: Bool = false
    /// Primary key of the corresponding `inventory_discrepancies` row in Supabase.
    var dbDiscrepancyId: UUID? = nil
}

/// A suggested fix built from discrepancy + recent audit context.
struct SuggestedFix {
    let discrepancyId: UUID
    var reasonCode: String              // human-readable explanation
    let recommendedAdjustment: Int      // absolute target quantity
    let recentAuditCount: Int           // # recent audit events found for this SKU
    let confidence: FixConfidence
    /// Primary key of the corresponding `inventory_adjustments` row in Supabase (nil until persisted).
    var dbAdjustmentId: UUID? = nil

    // AI State
    var isAIDiagnosis: Bool = false
    var isAnalyzing: Bool = false
    var aiError: String? = nil

    enum FixConfidence {
        case high, medium, low
        var label: String {
            switch self { case .high: "High"; case .medium: "Medium"; case .low: "Low" }
        }
        var color: Color {
            switch self {
            case .high:   return RSMSTheme.Colors.success
            case .medium: return RSMSTheme.Colors.warning
            case .low:    return RSMSTheme.Colors.error
            }
        }
        var icon: String {
            switch self {
            case .high:   return "checkmark.seal.fill"
            case .medium: return "exclamationmark.triangle.fill"
            case .low:    return "questionmark.circle.fill"
            }
        }
    }
}

// MARK: - ViewModel

@MainActor
final class StockCheckViewModel: ObservableObject {

    // MARK: Published

    @Published private(set) var items: [StockCheckItem] = []
    @Published private(set) var discrepancies: [StockDiscrepancy] = []
    @Published private(set) var fixes: [UUID: SuggestedFix] = [:]   // keyed by discrepancy id

    @Published private(set) var isLoading: Bool = false
    @Published private(set) var isRunningCheck: Bool = false
    @Published var errorMessage: String? = nil

    @Published private(set) var checkCompletedAt: Date? = nil
    @Published var toastMessage: String? = nil
    @Published var showSuccessToast: Bool = false

    // MARK: Private state
    private var storeId: UUID?
    private var userId: UUID?
    private let aiService = AIForecastService()

    // MARK: - Load Inventory
    // -----------------------------------------------------------------------
    // Uses the same PostgREST embed pattern as LowStockService:
    //   inventory?select=product_id,store_id,stock_quantity,products(sku,name)
    // The decoder handles both array-wrapped and object-wrapped product rows
    // (PostgREST may return either depending on FK cardinality config).
    // -----------------------------------------------------------------------

    func load(storeId: UUID?, userId: UUID? = nil) async {
        self.storeId = storeId
        self.userId = userId
        isLoading = true
        errorMessage = nil
        discrepancies = []
        fixes = [:]
        checkCompletedAt = nil

        do {
            // Nested decodable — mirrors LowStockAlert.EmbeddedProduct pattern
            struct InventoryRow: Decodable {
                let product_id: UUID
                let stock_quantity: Int
                let products: ProductEmbed

                struct ProductEmbed: Decodable {
                    let sku: String
                    let name: String
                }

                // Resilient decoder: PostgREST may return product as object or [object]
                enum CodingKeys: String, CodingKey {
                    case product_id, stock_quantity, products
                }

                init(from decoder: Decoder) throws {
                    let c = try decoder.container(keyedBy: CodingKeys.self)
                    self.product_id     = try c.decode(UUID.self, forKey: .product_id)
                    self.stock_quantity = try c.decode(Int.self,  forKey: .stock_quantity)

                    if let arr = try? c.decode([ProductEmbed].self, forKey: .products),
                       let first = arr.first {
                        self.products = first
                    } else {
                        self.products = try c.decode(ProductEmbed.self, forKey: .products)
                    }
                }
            }

            var query = SupabaseManager.shared.client
                .from("inventory")
                .select("product_id, stock_quantity, products(sku, name)")

            if let sid = storeId {
                query = query.eq("store_id", value: sid)
            }

            let rows: [InventoryRow] = try await query.execute().value

            self.items = rows.map {
                StockCheckItem(
                    productId: $0.product_id,
                    sku: $0.products.sku,
                    productName: $0.products.name,
                    expectedQty: $0.stock_quantity,
                    scannedQty: nil
                )
            }

            print("✅ [StockCheck] Loaded \(rows.count) inventory rows for store: \(storeId?.uuidString ?? "all")")
        } catch {
            print("❌ [StockCheck] Load failed: \(error)")
            errorMessage = "Failed to load inventory: \(error.localizedDescription)"
        }

        // Resume any pending adjustments from a previous session
        await loadPendingAdjustments()

        isLoading = false
    }

    // MARK: - Resume Pending Session
    // -----------------------------------------------------------------------
    // Queries inventory_adjustments for status='pending' rows belonging to this
    // store. Reconstructs StockDiscrepancy + SuggestedFix in memory and
    // pre-populates scannedQty on items so the IC sees the exact state they
    // left the last session in.
    // -----------------------------------------------------------------------

    private func loadPendingAdjustments() async {
        guard let sid = storeId else { return }
        guard discrepancies.isEmpty else { return }  // don't overwrite a fresh check

        do {
            struct PendingRow: Decodable {
                let id: UUID
                let product_id: UUID
                let discrepancy_id: UUID?
                let expected_quantity: Int
                let actual_quantity: Int
                let suggested_change: Int
                let products: ProductEmbed

                struct ProductEmbed: Decodable {
                    let sku: String
                    let name: String
                }

                // Resilient decoder (PostgREST may wrap embed in array)
                enum CodingKeys: String, CodingKey {
                    case id, product_id, discrepancy_id
                    case expected_quantity, actual_quantity, suggested_change
                    case products
                }

                init(from decoder: Decoder) throws {
                    let c = try decoder.container(keyedBy: CodingKeys.self)
                    self.id                = try c.decode(UUID.self, forKey: .id)
                    self.product_id        = try c.decode(UUID.self, forKey: .product_id)
                    self.discrepancy_id    = try? c.decode(UUID.self, forKey: .discrepancy_id)
                    self.expected_quantity = try c.decode(Int.self,  forKey: .expected_quantity)
                    self.actual_quantity   = try c.decode(Int.self,  forKey: .actual_quantity)
                    self.suggested_change  = try c.decode(Int.self,  forKey: .suggested_change)

                    if let arr = try? c.decode([ProductEmbed].self, forKey: .products),
                       let first = arr.first {
                        self.products = first
                    } else {
                        self.products = try c.decode(ProductEmbed.self, forKey: .products)
                    }
                }
            }

            let rows: [PendingRow] = try await SupabaseManager.shared.client
                .from("inventory_adjustments")
                .select("id, product_id, discrepancy_id, expected_quantity, actual_quantity, suggested_change, products(sku, name)")
                .eq("store_id", value: sid)
                .eq("status", value: "pending")
                .execute()
                .value

            guard !rows.isEmpty else {
                print("ℹ️ [StockCheck] No pending session to resume for store: \(sid)")
                return
            }

            print("✅ [StockCheck] Resuming session — \(rows.count) pending adjustment(s) found")

            var restoredDiscrepancies: [StockDiscrepancy] = []
            var restoredFixes: [UUID: SuggestedFix] = [:]

            for row in rows {
                // Build the local discrepancy
                var disc = StockDiscrepancy(
                    productId:   row.product_id,
                    sku:         row.products.sku,
                    productName: row.products.name,
                    expectedQty: row.expected_quantity,
                    scannedQty:  row.actual_quantity
                )
                disc.dbDiscrepancyId = row.discrepancy_id

                // Re-generate AI fix from the stored quantities (no audit re-fetch needed)
                var fix = generateFix(for: disc, recentAuditCount: 0)
                fix.dbAdjustmentId = row.id

                restoredDiscrepancies.append(disc)
                restoredFixes[disc.id] = fix

                // Pre-populate the row's scanned qty so the count sheet shows previous entry
                if let idx = items.firstIndex(where: { $0.productId == row.product_id }) {
                    items[idx].scannedQty = row.actual_quantity
                }
            }

            self.discrepancies   = restoredDiscrepancies
            self.fixes           = restoredFixes
            self.checkCompletedAt = Date()  // signal UI that a check is already in progress

        } catch {
            print("⚠️ [StockCheck] Could not resume pending session: \(error)")
        }
    }

    // MARK: - Update Scanned Count (Local)

    func updateScanned(itemId: UUID, qty: Int) {
        guard let idx = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[idx].scannedQty = max(0, qty)
    }

    func matchUncounted(for itemIds: [UUID]? = nil) {
        let targets = itemIds ?? items.map { $0.id }
        for id in targets {
            if let idx = items.firstIndex(where: { $0.id == id }), items[idx].scannedQty == nil {
                items[idx].scannedQty = items[idx].expectedQty
            }
        }
    }

    func handleScan(sku: String) {
        guard let idx = items.firstIndex(where: { $0.sku.lowercased() == sku.lowercased() }) else {
            showToast("⚠️ Unknown SKU: \(sku)")
            return
        }
        let current = items[idx].scannedQty ?? 0
        let newQty = current + 1
        items[idx].scannedQty = newQty
        showToast("✓ \(items[idx].productName): Total Count is \(newQty)")
    }

    // MARK: - Run Stock Check
    // -----------------------------------------------------------------------
    // 1. Computes discrepancies between expectedQty and scannedQty.
    // 2. Queries audit_logs for each discrepant SKU's recent activity.
    //    This makes the fix-suggestion confidence context-aware (e.g. if
    //    there were 3 recent adjustments the system suggests "likely data
    //    entry error" rather than a generic shortage reason).
    // -----------------------------------------------------------------------

    func runStockCheck() async {
        guard !isRunningCheck else { return }
        isRunningCheck = true
        errorMessage = nil

        // Step 1: Build discrepancy list (pure local computation)
        let newDiscrepancies: [StockDiscrepancy] = items.compactMap { item in
            guard let scanned = item.scannedQty else { return nil }
            guard scanned != item.expectedQty else { return nil }
            return StockDiscrepancy(
                productId: item.productId,
                sku: item.sku,
                productName: item.productName,
                expectedQty: item.expectedQty,
                scannedQty: scanned
            )
        }
        self.discrepancies = newDiscrepancies
        self.checkCompletedAt = Date()

        // Step 2: Fetch recent audit events per discrepant SKU to inform suggestions
        var auditCountBySKU: [String: Int] = [:]
        do {
            // We fetch audit_logs rows whose action contains the SKU text.
            // The audit_logs table structure (confirmed from LowStockService):
            //   action     TEXT
            //   event_type TEXT
            //   user_name  TEXT
            //   entity     TEXT
            //   before_data JSONB / TEXT
            //   after_data  JSONB / TEXT
            //   created_at TIMESTAMPTZ
            struct AuditRow: Decodable {
                let action: String
            }

            // Single bulk fetch for all discrepant SKUs — filter in memory
            let skus = newDiscrepancies.map { $0.sku }
            if !skus.isEmpty {
                let auditRows: [AuditRow] = try await SupabaseManager.shared.client
                    .from("audit_logs")
                    .select("action")
                    .eq("event_type", value: "inventory_adjustment")
                    .order("created_at", ascending: false)
                    .limit(200)
                    .execute()
                    .value

                for sku in skus {
                    auditCountBySKU[sku] = auditRows.filter { $0.action.contains(sku) }.count
                }
                print("✅ [StockCheck] Fetched \(auditRows.count) recent audit events for context")
            }
        } catch {
            // Non-fatal — suggestions will fall back to rule-of-thumb only
            print("⚠️ [StockCheck] Could not fetch audit context: \(error)")
        }

        // Step 3: Generate fix suggestions with audit context
        var newFixes: [UUID: SuggestedFix] = [:]
        for d in newDiscrepancies {
            let auditCount = auditCountBySKU[d.sku] ?? 0
            newFixes[d.id] = generateFix(for: d, recentAuditCount: auditCount)
        }

        // Step 4: Persist discrepancies → inventory_discrepancies table
        // Then create a pending adjustment → inventory_adjustments table
        // Both operations are best-effort: UI still shows results even if DB write fails.
        do {
            guard let sid = storeId else {
                print("⚠️ [StockCheck] No storeId — skipping DB persistence of discrepancies")
                self.discrepancies = newDiscrepancies
                self.fixes = newFixes
                isRunningCheck = false
                return
            }

            // ── 4a. Insert discrepancy rows ──────────────────────────────
            struct DiscrepancyInsert: Encodable {
                let product_id: UUID
                let store_id: UUID
                let expected_quantity: Int
                let actual_scanned_quantity: Int
                let created_by: UUID?
            }
            struct DiscrepancyRow: Decodable {
                let id: UUID
                let product_id: UUID
            }

            let discInserts = newDiscrepancies.map {
                DiscrepancyInsert(
                    product_id: $0.productId,
                    store_id: sid,
                    expected_quantity: $0.expectedQty,
                    actual_scanned_quantity: $0.scannedQty,
                    created_by: userId
                )
            }

            var updatedDiscrepancies = newDiscrepancies
            if !discInserts.isEmpty {
                let discRows: [DiscrepancyRow] = try await SupabaseManager.shared.client
                    .from("inventory_discrepancies")
                    .insert(discInserts)
                    .select("id, product_id")
                    .execute()
                    .value

                // Map db UUID back to local discrepancy by productId
                let dbIdByProduct = Dictionary(uniqueKeysWithValues: discRows.map { ($0.product_id, $0.id) })
                for i in updatedDiscrepancies.indices {
                    updatedDiscrepancies[i].dbDiscrepancyId = dbIdByProduct[updatedDiscrepancies[i].productId]
                }
                print("✅ [StockCheck] Inserted \(discRows.count) rows into inventory_discrepancies")
            }

            // ── 4b. Insert pending adjustment rows ───────────────────────
            struct AdjustmentInsert: Encodable {
                let product_id: UUID
                let store_id: UUID
                let discrepancy_id: UUID?
                let expected_quantity: Int
                let actual_quantity: Int
                let suggested_change: Int
                let status: String
                let created_by: UUID?
            }
            struct AdjustmentRow: Decodable {
                let id: UUID
                let discrepancy_id: UUID?
            }

            let adjInserts: [AdjustmentInsert] = updatedDiscrepancies.compactMap { d in
                guard let fix = newFixes[d.id] else { return nil }
                return AdjustmentInsert(
                    product_id: d.productId,
                    store_id: sid,
                    discrepancy_id: d.dbDiscrepancyId,
                    expected_quantity: d.expectedQty,
                    actual_quantity: d.scannedQty,
                    suggested_change: fix.recommendedAdjustment - d.expectedQty,
                    status: "pending",
                    created_by: userId
                )
            }

            if !adjInserts.isEmpty {
                let adjRows: [AdjustmentRow] = try await SupabaseManager.shared.client
                    .from("inventory_adjustments")
                    .insert(adjInserts)
                    .select("id, discrepancy_id")
                    .execute()
                    .value

                // Map adjustment db UUID back to fix via discrepancy_id
                let adjIdByDiscrepancyId = Dictionary(
                    uniqueKeysWithValues: adjRows.compactMap { row -> (UUID, UUID)? in
                        guard let discId = row.discrepancy_id else { return nil }
                        return (discId, row.id)
                    }
                )
                for d in updatedDiscrepancies {
                    if let dbDiscId = d.dbDiscrepancyId,
                       let adjDbId  = adjIdByDiscrepancyId[dbDiscId] {
                        newFixes[d.id]?.dbAdjustmentId = adjDbId
                    }
                }
                print("✅ [StockCheck] Inserted \(adjRows.count) rows into inventory_adjustments (status: pending)")
            }

            self.discrepancies = updatedDiscrepancies
            self.fixes = newFixes

        } catch {
            print("⚠️ [StockCheck] DB persistence failed — showing results in-memory only: \(error)")
            self.discrepancies = newDiscrepancies
            self.fixes = newFixes
        }

        isRunningCheck = false
        print("✅ [StockCheck] Check complete — \(newDiscrepancies.count) discrepancies found")
    }

    // MARK: - Fix Generation (AI-Driven, Multi-Signal)
    // -----------------------------------------------------------------------
    // Signals used (in priority order):
    //   1. Direction      — shortage vs. surplus
    //   2. Severity tier  — minor (1), moderate (2-4), significant (5+)
    //   3. Relative magnitude — diff as % of expectedQty (chronic vs. spike)
    //   4. Audit recency  — recentAuditCount for this SKU
    //   5. Audit pattern  — chronic repeater vs. first-time anomaly
    //
    // Output: product-specific natural-language diagnosis + prescriptive action.
    // -----------------------------------------------------------------------

    private func generateFix(for d: StockDiscrepancy, recentAuditCount: Int) -> SuggestedFix {
        let diff        = d.difference
        let absDiff     = abs(diff)
        let isShortage  = diff < 0
        let product     = d.productName
        let sku         = d.sku
        let expected    = d.expectedQty
        let scanned     = d.scannedQty

        // ── Signal 1 & 2: Direction + Severity tier ──────────────────────
        enum Severity { case minor, moderate, significant }
        let severity: Severity
        switch absDiff {
        case 1:       severity = .minor
        case 2...4:   severity = .moderate
        default:      severity = .significant
        }

        // ── Signal 3: Relative discrepancy magnitude ──────────────────────
        let relPct = expected > 0 ? Double(absDiff) / Double(expected) * 100 : 100.0
        let isHighRelative = relPct >= 30   // ≥30% of expected stock missing/surplus

        // ── Signal 4 & 5: Audit history pattern ──────────────────────────
        let isChronic   = recentAuditCount >= 5
        let isRecurrent = recentAuditCount >= 2

        // ── Build diagnosis sentence ──────────────────────────────────────
        let diagnosis: String

        if isShortage {
            switch severity {
            case .minor:
                if isChronic {
                    diagnosis = "\(product) (SKU: \(sku)) shows a recurring 1-unit shortfall — \(recentAuditCount) prior adjustments on record suggest a persistent POS scan-miss or a systemic rounding fault. Audit the last 5 transactions for this SKU."
                } else if isRecurrent {
                    diagnosis = "\(product) is short by 1 unit. With \(recentAuditCount) recent corrections logged, this may indicate an intermittent scan failure at checkout. Review the last POS session for unregistered sales."
                } else {
                    diagnosis = "\(product) has a single-unit shortage (expected \(expected), counted \(scanned)). Most likely cause: one sale was processed without a successful barcode scan. No prior anomalies on record — a one-off correction is appropriate."
                }

            case .moderate:
                if isChronic {
                    diagnosis = "\(product) (SKU: \(sku)) is \(absDiff) units short with \(recentAuditCount) past adjustments — this is a chronic discrepancy. Possible causes: repeated inter-store transfers not recorded in RSMS, or a supplier consistently under-delivering. Initiate a full transfer-log audit."
                } else if isHighRelative {
                    diagnosis = "\(product) is missing \(absDiff) units (\(Int(relPct))% of expected stock \(expected)). The relative magnitude is high — cross-check recent inbound Goods Received Notes and any open RMAs. A mismatch in receiving records is the primary candidate."
                } else {
                    diagnosis = "\(product) shows a \(absDiff)-unit shortage. Likely cause: unlogged sales or a partial delivery that was not reconciled in inventory. Verify the last receiving note for this SKU and check for any open void transactions."
                }

            case .significant:
                if isChronic {
                    diagnosis = "⚠️ \(product) (SKU: \(sku)) has a critical shortage of \(absDiff) units with \(recentAuditCount) historical adjustments — this pattern strongly indicates a systemic data-integrity issue. Recommended action: freeze stock movements for this SKU, cross-reference physical count with CCTV records, and escalate to the store manager before applying this correction."
                } else if isHighRelative {
                    diagnosis = "⚠️ \(product) is \(absDiff) units short — representing \(Int(relPct))% of the \(expected)-unit expected count. Given no prior audit trail, this is either a bulk theft event, an unreported damage write-off, or an inbound delivery that was never entered. Do not approve until physical stock is independently verified."
                } else {
                    diagnosis = "\(product) (SKU: \(sku)) has a significant \(absDiff)-unit shortage. Possible causes include: bulk inter-store transfer without system update, supplier short-shipment, or goods recorded as received but not physically present. Cross-check the last three GRNs and inbound transfer logs before committing this adjustment."
                }
            }
        } else {
            // Surplus
            switch severity {
            case .minor:
                if isChronic {
                    diagnosis = "\(product) consistently runs 1 unit over-count (\(recentAuditCount) prior corrections). This pattern suggests a systematic duplicate-receiving entry or a return workflow that credits inventory without a matching POS return. Review the returns processing desk for this SKU."
                } else {
                    diagnosis = "\(product) shows a 1-unit surplus (counted \(scanned) vs. expected \(expected)). Most likely cause: a customer return was accepted and restocked without a system receipt, or an over-delivery on the last shipment. No recurring trend — a straightforward correction is appropriate."
                }

            case .moderate:
                if isHighRelative {
                    diagnosis = "\(product) has \(absDiff) extra units (\(Int(relPct))% above expected \(expected)). A discrepancy of this relative size usually points to a Goods Receipt Notes entry error — a delivery batch may have been scanned twice, or a return was logged under the wrong SKU. Verify the last 3 GRN entries."
                } else {
                    diagnosis = "\(product) (SKU: \(sku)) is \(absDiff) units over expected stock. Likely root cause: unprocessed customer returns sitting in the stockroom, or an inbound transfer that incremented inventory before physical confirmation. Reconcile open return tickets for this SKU."
                }

            case .significant:
                if isChronic {
                    diagnosis = "⚠️ \(product) has a large \(absDiff)-unit surplus with \(recentAuditCount) historical corrections — chronic over-count detected. This strongly suggests a systemic duplicate-entry in the receiving workflow or an automated import overriding manual counts. Escalate to stock management before approving; do not apply blindly."
                } else {
                    diagnosis = "⚠️ \(product) (SKU: \(sku)) shows a major \(absDiff)-unit surplus. First-time anomaly of this size typically indicates: a delivery was received twice in RSMS, a transfer-in from another store was double-counted, or a returns batch was applied to the wrong SKU. Validate against the last inbound shipment manifest before committing this adjustment."
                }
            }
        }

        // ── Determine final confidence ────────────────────────────────────
        let baseConfidence: SuggestedFix.FixConfidence
        switch severity {
        case .minor:        baseConfidence = .high
        case .moderate:     baseConfidence = .medium
        case .significant:  baseConfidence = .low
        }

        let finalConfidence: SuggestedFix.FixConfidence
        if isChronic {
            finalConfidence = .low
        } else if isRecurrent || isHighRelative {
            finalConfidence = min(baseConfidence, .medium)
        } else {
            finalConfidence = baseConfidence
        }

        return SuggestedFix(
            discrepancyId: d.id,
            reasonCode: diagnosis,
            recommendedAdjustment: d.scannedQty,
            recentAuditCount: recentAuditCount,
            confidence: finalConfidence
        )
    }

    // MARK: - Deep AI Analysis (Gemini Integration)
    // -----------------------------------------------------------------------
    // This goes beyond the local heuristic engine by sending the full SKU 
    // history to Google Gemini for a multi-variable forensic reasoning.
    // -----------------------------------------------------------------------

    func requestAIDiagnosis(for discrepancyId: UUID) async {
        guard let idx = discrepancies.firstIndex(where: { $0.id == discrepancyId }),
              let fix = fixes[discrepancyId] else { return }
        
        let d = discrepancies[idx]
        
        // Fetch raw history from audit_logs and filter in memory for compatibility
        var historyLogs: [String] = []
        do {
            struct AuditRow: Decodable { let action: String; let created_at: String }
            let rows: [AuditRow] = try await SupabaseManager.shared.client
                .from("audit_logs")
                .select("action, created_at")
                .order("created_at", ascending: false)
                .limit(100) // Fetch a larger batch to find SKU matches
                .execute()
                .value
            
            historyLogs = rows
                .filter { $0.action.contains(d.sku) }
                .prefix(10)
                .map { "[\($0.created_at)]: \($0.action)" }
        } catch {
            print("⚠️ [StockCheck] Failed to fetch SKU history for AI: \(error)")
        }

        do {
            // Update UI to show "AI Analyzing..."
            fixes[discrepancyId]?.isAnalyzing = true
            fixes[discrepancyId]?.reasonCode = "AI is analyzing audit history logs for patterns..."
            fixes[discrepancyId]?.aiError = nil
            
            // Call Gemini
            let diagnosis = try await aiService.fetchAuditDiagnosis(
                sku: d.sku,
                productName: d.productName,
                expected: d.expectedQty,
                actual: d.scannedQty,
                historyLogs: historyLogs
            )
            
            // Finalize with AI reasoning
            fixes[discrepancyId]?.reasonCode = diagnosis
            fixes[discrepancyId]?.isAIDiagnosis = true
            fixes[discrepancyId]?.isAnalyzing = false
            fixes[discrepancyId]?.aiError = nil
            
        } catch {
            print("❌ [StockCheck] AI Diagnosis failed: \(error)")
            
            let errorMsg: String
            if let urlError = error as? URLError, urlError.code == .userAuthenticationRequired {
                errorMsg = "⚠️ Gemini API Key not configured in AIForecastService.swift. Please add your key to enable deep audit."
            } else {
                errorMsg = "⚠️ AI Analysis failed. Please check your connection and try again."
            }
            
            // Revert to a state that doesn't start with ✨ so the button stays visible
            fixes[discrepancyId]?.isAnalyzing = false
            fixes[discrepancyId]?.isAIDiagnosis = false
            fixes[discrepancyId]?.aiError = errorMsg
            fixes[discrepancyId]?.reasonCode = errorMsg
        }
    }

    // MARK: - Approve Fix
    // -----------------------------------------------------------------------
    // 1. UPDATEs inventory row: stock_quantity + last_updated
    // 2. INSERTs audit_logs row with full schema:
    //      action, event_type, user_name, entity, before_data, after_data
    //    This matches the exact shape used by LowStockService.executeTransfer.
    // -----------------------------------------------------------------------

    func approveFix(discrepancyId: UUID) async {
        guard let idx = discrepancies.firstIndex(where: { $0.id == discrepancyId }),
              let fix = fixes[discrepancyId] else { return }

        discrepancies[idx].isApplying = true
        errorMessage = nil

        let d = discrepancies[idx]

        do {
            // ── 1. Mark inventory_adjustments row as approved ────────────
            if let adjDbId = fix.dbAdjustmentId {
                struct AdjApproval: Encodable {
                    let status: String
                    let approved_by: UUID?
                    let approved_at: String
                }
                try await SupabaseManager.shared.client
                    .from("inventory_adjustments")
                    .update(AdjApproval(
                        status: "approved",
                        approved_by: userId,
                        approved_at: Date().ISO8601Format()
                    ))
                    .eq("id", value: adjDbId)
                    .execute()
                print("✅ [StockCheck] inventory_adjustments → approved (id: \(adjDbId))")
            } else {
                print("⚠️ [StockCheck] No dbAdjustmentId — skipping inventory_adjustments update")
            }

            // ── 2. Update inventory stock_quantity ───────────────────────
            struct InventoryUpdate: Encodable {
                let stock_quantity: Int
                let last_updated: String
            }

            var invQuery = try SupabaseManager.shared.client
                .from("inventory")
                .update(InventoryUpdate(
                    stock_quantity: fix.recommendedAdjustment,
                    last_updated: Date().ISO8601Format()
                ))
                .eq("product_id", value: d.productId)

            if let sid = storeId {
                invQuery = invQuery.eq("store_id", value: sid)
            }
            try await invQuery.execute()
            print("✅ [StockCheck] inventory updated — \(d.sku): \(d.expectedQty) → \(fix.recommendedAdjustment)")

            // ── 2.5. Insert Audit Log (Forensic Trail) ──────────────────
            struct AuditPayload: Encodable {
                let action: String
                let event_type: String
                let user_name: String
                let entity: String
                let before_data: [String: String]?
                let after_data: [String: String]?
            }

            let audit = AuditPayload(
                action: "STOCK_CHECK_ADJUSTMENT",
                event_type: "inventory_adjustment",
                user_name: "Inventory Controller",
                entity: "Inventory",
                before_data: [
                    "sku": d.sku,
                    "product": d.productName,
                    "stock_before": "\(d.expectedQty)"
                ],
                after_data: [
                    "sku": d.sku,
                    "product": d.productName,
                    "stock_after": "\(fix.recommendedAdjustment)",
                    "adjustment_reason": fix.reasonCode
                ]
            )

            try? await SupabaseManager.shared.client
                .from("audit_logs")
                .insert(audit)
                .execute()
            
            print("✅ [StockCheck] Audit log inserted for \(d.sku)")

            // ── 3. Update local state ────────────────────────────────────
            discrepancies[idx].isApplying = false
            discrepancies[idx].isApproved = true

            if let itemIdx = items.firstIndex(where: { $0.productId == d.productId }) {
                items[itemIdx].expectedQty = fix.recommendedAdjustment
            }

            showToast("✓ \(d.productName) → \(fix.recommendedAdjustment) units")

        } catch {
            discrepancies[idx].isApplying = false
            print("❌ [StockCheck] approveFix failed: \(error)")
            errorMessage = "Failed to apply fix: \(error.localizedDescription)"
        }
    }

    // MARK: - Dismiss / Reset

    func dismissDiscrepancy(id: UUID) {
        // Mark the corresponding inventory_adjustments row as rejected in the DB
        if let fix = fixes[id], let adjDbId = fix.dbAdjustmentId {
            Task {
                do {
                    try await SupabaseManager.shared.client
                        .from("inventory_adjustments")
                        .update(["status": "rejected"])
                        .eq("id", value: adjDbId)
                        .execute()
                    print("✅ [StockCheck] inventory_adjustments → rejected (id: \(adjDbId))")
                } catch {
                    print("⚠️ [StockCheck] Could not reject adjustment in DB: \(error)")
                }
            }
        }
        discrepancies.removeAll { $0.id == id }
        fixes.removeValue(forKey: id)
    }

    func resetCheck() {
        // Bulk-reject any pending DB adjustments so they don't resurface on next load
        let pendingAdjIds = fixes.values.compactMap { $0.dbAdjustmentId }
        if !pendingAdjIds.isEmpty {
            Task {
                for adjId in pendingAdjIds {
                    try? await SupabaseManager.shared.client
                        .from("inventory_adjustments")
                        .update(["status": "rejected"])
                        .eq("id", value: adjId)
                        .execute()
                }
                print("✅ [StockCheck] Reset — \(pendingAdjIds.count) pending adjustment(s) rejected in DB")
            }
        }
        for idx in items.indices { items[idx].scannedQty = nil }
        discrepancies = []
        fixes = [:]
        checkCompletedAt = nil
        errorMessage = nil
    }

    // MARK: - Computed

    var pendingCount: Int   { discrepancies.filter { !$0.isApproved }.count }
    var approvedCount: Int  { discrepancies.filter {  $0.isApproved }.count }
    var uncountedItems: Int { items.filter { $0.scannedQty == nil }.count }

    // MARK: - Private helpers

    private func showToast(_ msg: String) {
        toastMessage = msg
        withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
            showSuccessToast = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_800_000_000)
            withAnimation { showSuccessToast = false }
        }
    }
}

// MARK: - Confidence helpers

private func min(_ a: SuggestedFix.FixConfidence, _ b: SuggestedFix.FixConfidence) -> SuggestedFix.FixConfidence {
    // Ordering: high > medium > low  →  min returns the "worse" confidence
    let order: [SuggestedFix.FixConfidence] = [.low, .medium, .high]
    let ai = order.firstIndex(of: a) ?? 0
    let bi = order.firstIndex(of: b) ?? 0
    return ai <= bi ? a : b
}
