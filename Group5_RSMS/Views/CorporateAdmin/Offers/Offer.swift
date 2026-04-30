//
//  Offer.swift
//  Group5_RSMS
//
//

import Foundation
import Combine

// MARK: - Offer

struct Offer: Identifiable, Codable {
    let id: UUID
    var name: String
    var discountType: DiscountType
    var discountValue: Double
    var applicableTo: String?
    var startDate: Date
    var endDate: Date
    var assignedStoreIds: [UUID]
    var performancePenalty: String?
    var usageLimit: Int?
    var isStackable: Bool
    var activationMethod: String
    var couponCode: String?
    var isPaused: Bool
    var status: OfferStatus

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case discountType       = "discount_type"
        case discountValue      = "discount_value"
        case applicableTo       = "applicable_to"
        case startDate          = "start_date"
        case endDate            = "end_date"
        case assignedStoreIds   = "assigned_store_ids"
        case performancePenalty = "performance_penalty"
        case usageLimit         = "usage_limit"
        case isStackable        = "is_stackable"
        case activationMethod   = "activation_method"
        case couponCode         = "coupon_code"
        case isPaused           = "is_paused"
    }

    init(id: UUID, name: String, discountType: DiscountType, discountValue: Double,
         applicableTo: String? = nil, startDate: Date, endDate: Date,
         assignedStoreIds: [UUID] = [], performancePenalty: String? = nil,
         usageLimit: Int? = nil, isStackable: Bool = false,
         activationMethod: String = "auto", couponCode: String? = nil,
         isPaused: Bool = false, status: OfferStatus = .scheduled) {
        self.id = id; self.name = name; self.discountType = discountType
        self.discountValue = discountValue; self.applicableTo = applicableTo
        self.startDate = startDate; self.endDate = endDate
        self.assignedStoreIds = assignedStoreIds; self.performancePenalty = performancePenalty
        self.usageLimit = usageLimit; self.isStackable = isStackable
        self.activationMethod = activationMethod; self.couponCode = couponCode
        self.isPaused = isPaused; self.status = status
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id            = try c.decode(UUID.self, forKey: .id)
        name          = try c.decode(String.self, forKey: .name)
        discountType  = try c.decode(DiscountType.self, forKey: .discountType)
        discountValue = try c.decode(Double.self, forKey: .discountValue)
        applicableTo  = try c.decodeIfPresent(String.self, forKey: .applicableTo)
        startDate     = try c.decode(Date.self, forKey: .startDate)
        endDate       = try c.decode(Date.self, forKey: .endDate)
        assignedStoreIds    = try c.decodeIfPresent([UUID].self, forKey: .assignedStoreIds) ?? []
        performancePenalty  = try c.decodeIfPresent(String.self, forKey: .performancePenalty)
        usageLimit          = try c.decodeIfPresent(Int.self, forKey: .usageLimit)
        isStackable         = try c.decodeIfPresent(Bool.self, forKey: .isStackable) ?? false
        activationMethod    = try c.decodeIfPresent(String.self, forKey: .activationMethod) ?? "auto"
        couponCode          = try c.decodeIfPresent(String.self, forKey: .couponCode)
        isPaused            = try c.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        status              = try c.decodeIfPresent(OfferStatus.self, forKey: .status) ?? .scheduled
    }

    var computedStatus: OfferStatus {
        let now = Date()
        if now > endDate  { return .expired }
        if isPaused       { return .paused }
        if now < startDate { return .scheduled }
        return .active
    }

    var discountLabel: String {
        switch discountType {
        case .percentage: return "\(Int(discountValue))% OFF"
        case .fixed:      return "₹\(Int(discountValue)) OFF"
        }
    }
}

// MARK: - Supporting enums

enum DiscountType: String, Codable, CaseIterable {
    case percentage, fixed
    var displayName: String {
        switch self {
        case .percentage: return "Percentage (%)"
        case .fixed:      return "Fixed Amount (₹)"
        }
    }
}

enum OfferStatus: String, Codable {
    case active, scheduled, expired, paused
}

// MARK: - OfferStore (lightweight)

struct OfferStore: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let city: String
}

// MARK: - OfferService

final class OfferService: ObservableObject {

    private let supabaseURL     = SupabaseConfig.url
    private let supabaseAnonKey = SupabaseConfig.anonKey

    @Published var offers:       [Offer] = []
    @Published var stores:       [OfferStore] = []
    @Published var isLoading:    Bool    = false
    @Published var errorMessage: String? = nil

    var activeOffers:    [Offer] { offers.filter { $0.computedStatus == .active || $0.computedStatus == .paused } }
    var scheduledOffers: [Offer] { offers.filter { $0.computedStatus == .scheduled } }
    var expiredOffers:   [Offer] { offers.filter { $0.computedStatus == .expired } }

    // MARK: - Shared Decoder

    private var jsonDecoder: JSONDecoder {
        let decoder = JSONDecoder()
        let formatters: [ISO8601DateFormatter] = [
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]; return f }(),
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withInternetDateTime]; return f }(),
            { let f = ISO8601DateFormatter(); f.formatOptions = [.withFullDate, .withFullTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]; return f }()
        ]
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            for f in formatters { if let d = f.date(from: dateStr) { return d } }
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let d = df.date(from: dateStr) { return d }
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let d = df.date(from: dateStr) { return d }
            throw DecodingError.dataCorruptedError(in: container,
                debugDescription: "Invalid date format: \(dateStr)")
        }
        return decoder
    }

    // MARK: - Shared Encoder

    private var jsonEncoder: JSONEncoder {
        let encoder = JSONEncoder()
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        encoder.dateEncodingStrategy = .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(formatter.string(from: date))
        }
        return encoder
    }

    // MARK: - Helpers

    private func makeRequest(path: String, method: String) -> URLRequest? {
        guard let url = URL(string: "\(supabaseURL)/rest/v1/\(path)") else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey,              forHTTPHeaderField: "apikey")
        request.setValue("application/json",           forHTTPHeaderField: "Content-Type")
        return request
    }

    // MARK: - Fetch Stores

    func fetchStores() {
        guard let request = makeRequest(path: "stores?select=id,name,city", method: "GET") else { return }
        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            DispatchQueue.main.async {
                guard error == nil, let data = data else { return }
                self?.stores = (try? JSONDecoder().decode([OfferStore].self, from: data)) ?? []
            }
        }.resume()
    }

    // MARK: - Fetch Offers

    func fetchOffers() {
        guard let request = makeRequest(path: "offers?select=*&order=created_at.desc", method: "GET") else { return }
        isLoading = true; errorMessage = nil
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error { self?.errorMessage = error.localizedDescription; return }
                guard let data = data else { return }
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    self?.errorMessage = self?.parseSupabaseError(data: data, fallback: http.statusCode); return
                }
                do {
                    self?.offers = try self?.jsonDecoder.decode([Offer].self, from: data) ?? []
                } catch {
                    if let raw = String(data: data, encoding: .utf8) { print("Raw: \(raw)") }
                    self?.errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    // MARK: - Add Offer

    func addOffer(_ offer: Offer, completion: @escaping (Bool) -> Void = { _ in }) {
        guard var request = makeRequest(path: "offers", method: "POST") else { completion(false); return }
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        do { request.httpBody = try jsonEncoder.encode(offer) } catch {
            errorMessage = "Encoding error: \(error.localizedDescription)"; completion(false); return
        }
        isLoading = true
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error { self?.errorMessage = error.localizedDescription; completion(false); return }
                guard let data = data else { completion(false); return }
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    self?.errorMessage = self?.parseSupabaseError(data: data, fallback: http.statusCode); completion(false); return
                }
                let inserted = (try? self?.jsonDecoder.decode([Offer].self, from: data)) ?? []
                let saved = inserted.first ?? offer
                self?.offers.insert(saved, at: 0)

                ActivityLogService.shared.log(
                    action: .created,
                    entity: .promotion,
                    entityName: saved.name,
                    entityId: saved.id.uuidString,
                    details: "Promotion '\(saved.name)' created — \(saved.discountLabel).",
                    after: ["name": saved.name,
                            "discount": saved.discountLabel,
                            "status": saved.computedStatus.rawValue,
                            "start": saved.startDate.formatted(date: .abbreviated, time: .omitted),
                            "end": saved.endDate.formatted(date: .abbreviated, time: .omitted)]
                )
                completion(true)
            }
        }.resume()
    }

    // MARK: - Update Offer

    func updateOffer(_ updatedOffer: Offer, completion: @escaping (Bool) -> Void = { _ in }) {
        let previousOffer = offers.first(where: { $0.id == updatedOffer.id })
        guard var request = makeRequest(path: "offers?id=eq.\(updatedOffer.id.uuidString)", method: "PATCH") else {
            completion(false); return
        }
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")
        do { request.httpBody = try jsonEncoder.encode(updatedOffer) } catch {
            errorMessage = "Encoding error: \(error.localizedDescription)"; completion(false); return
        }
        isLoading = true
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error { self?.errorMessage = error.localizedDescription; completion(false); return }
                guard let data = data else { completion(false); return }
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    self?.errorMessage = self?.parseSupabaseError(data: data, fallback: http.statusCode); completion(false); return
                }
                if let index = self?.offers.firstIndex(where: { $0.id == updatedOffer.id }) {
                    let updated = (try? self?.jsonDecoder.decode([Offer].self, from: data))?.first ?? updatedOffer
                    self?.offers[index] = updated

                    ActivityLogService.shared.log(
                        action: .updated,
                        entity: .promotion,
                        entityName: updated.name,
                        entityId: updated.id.uuidString,
                        details: "Promotion '\(updated.name)' updated.",
                        before: previousOffer.map { ["name": $0.name, "discount": $0.discountLabel,
                                                     "status": $0.computedStatus.rawValue] },
                        after: ["name": updated.name, "discount": updated.discountLabel,
                                "status": updated.computedStatus.rawValue]
                    )
                }
                completion(true)
            }
        }.resume()
    }

    // MARK: - Delete (soft → hard)

    func softDeleteOffer(_ offer: Offer, completion: @escaping (Bool) -> Void = { _ in }) {
        permanentlyDeleteOffer(offer, completion: completion)
    }

    func permanentlyDeleteOffer(_ offer: Offer, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let request = makeRequest(path: "offers?id=eq.\(offer.id.uuidString)", method: "DELETE") else {
            completion(false); return
        }
        isLoading = true
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                if let error = error { self?.errorMessage = error.localizedDescription; completion(false); return }
                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    self?.errorMessage = self?.parseSupabaseError(data: data, fallback: http.statusCode); completion(false); return
                }
                self?.offers.removeAll(where: { $0.id == offer.id })

                ActivityLogService.shared.log(
                    action: .deleted,
                    entity: .promotion,
                    entityName: offer.name,
                    entityId: offer.id.uuidString,
                    details: "Promotion '\(offer.name)' permanently deleted.",
                    before: ["name": offer.name, "discount": offer.discountLabel,
                             "status": offer.computedStatus.rawValue]
                )
                completion(true)
            }
        }.resume()
    }

    // MARK: - Error parsing

    private func parseSupabaseError(data: Data?, fallback statusCode: Int) -> String {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let msg  = json["message"] as? String
        else { return "Server returned status code \(statusCode)" }
        return "Database error: \(msg)"
    }
}
