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
}

/// A suggested fix built from discrepancy + recent audit context.
struct SuggestedFix {
    let discrepancyId: UUID
    let reasonCode: String              // human-readable explanation
    let recommendedAdjustment: Int      // absolute target quantity
    let recentAuditCount: Int           // # recent audit events found for this SKU
    let confidence: FixConfidence

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

    // MARK: - Load Inventory
    // -----------------------------------------------------------------------
    // Uses the same PostgREST embed pattern as LowStockService:
    //   inventory?select=product_id,store_id,stock_quantity,products(sku,name)
    // The decoder handles both array-wrapped and object-wrapped product rows
    // (PostgREST may return either depending on FK cardinality config).
    // -----------------------------------------------------------------------

    func load(storeId: UUID?) async {
        self.storeId = storeId
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

        isLoading = false
    }

    // MARK: - Update Scanned Count (Local)

    func updateScanned(itemId: UUID, qty: Int) {
        guard let idx = items.firstIndex(where: { $0.id == itemId }) else { return }
        items[idx].scannedQty = max(0, qty)
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
        self.fixes = newFixes

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
        let delta = fix.recommendedAdjustment - d.expectedQty
        let deltaStr = delta >= 0 ? "+\(delta)" : "\(delta)"

        do {
            // ── 1. Update inventory ──────────────────────────────────────
            struct InventoryUpdate: Encodable {
                let stock_quantity: Int
                let last_updated: String
            }
            let updatePayload = InventoryUpdate(
                stock_quantity: fix.recommendedAdjustment,
                last_updated: Date().ISO8601Format()
            )

            var invQuery = try SupabaseManager.shared.client
                .from("inventory")
                .update(updatePayload)
                .eq("product_id", value: d.productId)

            if let sid = storeId {
                invQuery = invQuery.eq("store_id", value: sid)
            }
            try await invQuery.execute()

            print("✅ [StockCheck] inventory updated — \(d.sku): \(d.expectedQty) → \(fix.recommendedAdjustment)")

            // ── 2. Write audit log (full schema) ─────────────────────────
            // before_data / after_data match the JSONB columns used by
            // LowStockService (String-keyed dictionaries serialised as JSON).
            struct AuditPayload: Encodable {
                let action: String
                let event_type: String
                let user_name: String
                let entity: String
                let before_data: [String: String]?
                let after_data: [String: String]?
            }

            let auditEntry = AuditPayload(
                action: "Stock-Check Adjustment (\(deltaStr)) — SKU: \(d.sku)",
                event_type: "stock_check_adjustment",
                user_name: "Inventory Controller",
                entity: "Inventory",
                before_data: [
                    "sku": d.sku,
                    "product": d.productName,
                    "stock_quantity": "\(d.expectedQty)"
                ],
                after_data: [
                    "sku": d.sku,
                    "product": d.productName,
                    "stock_quantity": "\(fix.recommendedAdjustment)",
                    "delta": deltaStr,
                    "reason": fix.reasonCode
                ]
            )

            try await SupabaseManager.shared.client
                .from("audit_logs")
                .insert(auditEntry)
                .execute()

            print("✅ [StockCheck] audit_log inserted for SKU: \(d.sku)")

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
        discrepancies.removeAll { $0.id == id }
        fixes.removeValue(forKey: id)
    }

    func resetCheck() {
        for idx in items.indices {
            items[idx].scannedQty = nil
        }
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
