//
//  Offer.swift
//  Group5_RSMS
//
//  Created by Apple on 15/04/26.
//

import Foundation
import Combine

// MARK: - Offer

struct Offer: Identifiable, Codable {
    let id: UUID
    var name: String
    var discountType: DiscountType
    var discountValue: Double
    var applicableTo: String?       // category scope, nil = all products
    var startDate: Date
    var endDate: Date
    var assignedStoreIds: [UUID]
    var performancePenalty: String?
    var usageLimit: Int?            // e.g. 1 per customer
    var isStackable: Bool           // Can be combined with other offers?
    var activationMethod: String    // "auto" or "coupon"
    var couponCode: String?         // only if activationMethod == "coupon"
    var isPaused: Bool              // if true, offer is temporarily paused
    var status: OfferStatus         // computed on fetch, or stored

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case discountType      = "discount_type"
        case discountValue     = "discount_value"
        case applicableTo      = "applicable_to"
        case startDate         = "start_date"
        case endDate           = "end_date"
        case assignedStoreIds  = "assigned_store_ids"
        case performancePenalty = "performance_penalty"
        case usageLimit        = "usage_limit"
        case isStackable       = "is_stackable"
        case activationMethod  = "activation_method"
        case couponCode        = "coupon_code"
        case isPaused          = "is_paused"
    }

    init(id: UUID, name: String, discountType: DiscountType, discountValue: Double, applicableTo: String? = nil, startDate: Date, endDate: Date, assignedStoreIds: [UUID] = [], performancePenalty: String? = nil, usageLimit: Int? = nil, isStackable: Bool = false, activationMethod: String = "auto", couponCode: String? = nil, isPaused: Bool = false, status: OfferStatus = .scheduled) {
        self.id = id
        self.name = name
        self.discountType = discountType
        self.discountValue = discountValue
        self.applicableTo = applicableTo
        self.startDate = startDate
        self.endDate = endDate
        self.assignedStoreIds = assignedStoreIds
        self.performancePenalty = performancePenalty
        self.usageLimit = usageLimit
        self.isStackable = isStackable
        self.activationMethod = activationMethod
        self.couponCode = couponCode
        self.isPaused = isPaused
        self.status = status
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        discountType = try container.decode(DiscountType.self, forKey: .discountType)
        discountValue = try container.decode(Double.self, forKey: .discountValue)
        applicableTo = try container.decodeIfPresent(String.self, forKey: .applicableTo)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        
        assignedStoreIds = try container.decodeIfPresent([UUID].self, forKey: .assignedStoreIds) ?? []
        performancePenalty = try container.decodeIfPresent(String.self, forKey: .performancePenalty)
        usageLimit = try container.decodeIfPresent(Int.self, forKey: .usageLimit)
        
        isStackable = try container.decodeIfPresent(Bool.self, forKey: .isStackable) ?? false
        activationMethod = try container.decodeIfPresent(String.self, forKey: .activationMethod) ?? "auto"
        couponCode = try container.decodeIfPresent(String.self, forKey: .couponCode)
        isPaused = try container.decodeIfPresent(Bool.self, forKey: .isPaused) ?? false
        status = try container.decodeIfPresent(OfferStatus.self, forKey: .status) ?? .scheduled
    }

    // Computed helper
    var computedStatus: OfferStatus {
        let now = Date()
        if now > endDate { return .expired }
        if isPaused { return .paused }
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
            {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                return f
            }(),
            {
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withInternetDateTime]
                return f
            }(),
            {
                // Handles "2026-04-20T07:39:03.946+00:00" style
                let f = ISO8601DateFormatter()
                f.formatOptions = [.withFullDate, .withFullTime, .withFractionalSeconds, .withColonSeparatorInTimeZone]
                return f
            }()
        ]
        
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let dateStr = try container.decode(String.self)
            
            for formatter in formatters {
                if let date = formatter.date(from: dateStr) {
                    return date
                }
            }
            
            // Last resort — DateFormatter with explicit format
            let df = DateFormatter()
            df.locale = Locale(identifier: "en_US_POSIX")
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSXXXXX"
            if let date = df.date(from: dateStr) { return date }
            
            df.dateFormat = "yyyy-MM-dd'T'HH:mm:ssXXXXX"
            if let date = df.date(from: dateStr) { return date }
            
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Invalid date format: \(dateStr)"
            )
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
        var request          = URLRequest(url: url)
        request.httpMethod   = method
        request.setValue("Bearer \(supabaseAnonKey)", forHTTPHeaderField: "Authorization")
        request.setValue(supabaseAnonKey,              forHTTPHeaderField: "apikey")
        request.setValue("application/json",           forHTTPHeaderField: "Content-Type")
        return request
    }

    // MARK: - FETCH (GET)

    func fetchStores() {
        guard let request = makeRequest(path: "stores?select=id,name,city", method: "GET") else { return }
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error fetching stores: \(error)")
                    return
                }
                guard let data = data else { return }
                do {
                    // Using standard decoder since dates aren't strictly needed for the store list here, 
                    // or we can use JSONDecoder() 
                    let decoder = JSONDecoder()
                    self?.stores = try decoder.decode([OfferStore].self, from: data)
                } catch {
                    print("Error decoding stores: \(error)")
                }
            }
        }.resume()
    }

    
    func fetchOffers() {
        guard let request = makeRequest(path: "offers?select=*&order=created_at.desc", method: "GET") else { return }

        isLoading    = true
        errorMessage = nil

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    return
                }

                guard let data = data else { return }

                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    self?.errorMessage = self?.parseSupabaseError(data: data, fallback: http.statusCode)
                    return
                }

                do {
                    self?.offers = try self?.jsonDecoder.decode([Offer].self, from: data) ?? []
                } catch {
                    // ✅ ADD THESE LINES HERE — inside the closure where data exists
                    if let raw = String(data: data, encoding: .utf8) {
                        print("❌ Raw response: \(raw)")
                    }
                    print("❌ Detailed error: \(error)")
                    self?.errorMessage = "Decoding error: \(error.localizedDescription)"
                }
            }
        }.resume()
    }

    // MARK: - ADD (POST)

    func addOffer(_ offer: Offer, completion: @escaping (Bool) -> Void = { _ in }) {
        guard var request = makeRequest(path: "offers", method: "POST") else {
            completion(false)
            return
        }
        // Ask Supabase to return the inserted row
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        do {
            request.httpBody = try jsonEncoder.encode(offer)
        } catch {
            errorMessage = "Encoding error: \(error.localizedDescription)"
            completion(false)
            return
        }

        isLoading = true

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                guard let data = data else { completion(false); return }

                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    self?.errorMessage = self?.parseSupabaseError(data: data, fallback: http.statusCode)
                    completion(false)
                    return
                }

                // Parse the returned row(s) and insert at front
                do {
                    let inserted = try self?.jsonDecoder.decode([Offer].self, from: data) ?? []
                    if let first = inserted.first {
                        self?.offers.insert(first, at: 0)
                    } else {
                        // Fallback: insert the local copy
                        self?.offers.insert(offer, at: 0)
                    }
                    completion(true)
                } catch {
                    // Insert succeeded but decoding the response failed — add locally
                    self?.offers.insert(offer, at: 0)
                    completion(true)
                }
            }
        }.resume()
    }

    // MARK: - UPDATE (PATCH)

    func updateOffer(_ updatedOffer: Offer, completion: @escaping (Bool) -> Void = { _ in }) {
        guard var request = makeRequest(path: "offers?id=eq.\(updatedOffer.id.uuidString)", method: "PATCH") else {
            completion(false)
            return
        }
        request.setValue("return=representation", forHTTPHeaderField: "Prefer")

        do {
            request.httpBody = try jsonEncoder.encode(updatedOffer)
        } catch {
            errorMessage = "Encoding error: \(error.localizedDescription)"
            completion(false)
            return
        }

        isLoading = true

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                guard let data = data else { completion(false); return }

                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    self?.errorMessage = self?.parseSupabaseError(data: data, fallback: http.statusCode)
                    completion(false)
                    return
                }

                // Update local array
                if let index = self?.offers.firstIndex(where: { $0.id == updatedOffer.id }) {
                    do {
                        let updated = try self?.jsonDecoder.decode([Offer].self, from: data) ?? []
                        self?.offers[index] = updated.first ?? updatedOffer
                    } catch {
                        self?.offers[index] = updatedOffer
                    }
                }
                completion(true)
            }
        }.resume()
    }

    // MARK: - DELETE
    
    func softDeleteOffer(_ offer: Offer, completion: @escaping (Bool) -> Void = { _ in }) {
        // Redirection: Hard delete directly since "Recently Deleted" is removed
        permanentlyDeleteOffer(offer, completion: completion)
    }

    func permanentlyDeleteOffer(_ offer: Offer, completion: @escaping (Bool) -> Void = { _ in }) {
        guard let request = makeRequest(path: "offers?id=eq.\(offer.id.uuidString)", method: "DELETE") else {
            completion(false)
            return
        }

        isLoading = true

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false

                if let error = error {
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                    return
                }

                if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                    self?.errorMessage = self?.parseSupabaseError(data: data, fallback: http.statusCode)
                    completion(false)
                    return
                }

                self?.offers.removeAll(where: { $0.id == offer.id })
                completion(true)
            }
        }.resume()
    }

    // MARK: - Error parsing

    private func parseSupabaseError(data: Data?, fallback statusCode: Int) -> String {
        guard let data = data,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let msg  = json["message"] as? String
        else {
            return "Server returned status code \(statusCode)"
        }
        return "Database error: \(msg)"
    }
}
