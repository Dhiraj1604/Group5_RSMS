//
//  Category.swift
//  Group5_RSMS
//

import Foundation

struct Category: Codable, Identifiable, Hashable {
    let id: UUID
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id, name
    }
}
