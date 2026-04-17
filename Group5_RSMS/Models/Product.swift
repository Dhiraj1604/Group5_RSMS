struct Product: Codable, Identifiable {
    let id: UUID
    let sku: String
    let name: String
    let description: String?
    let basePrice: Double
    let categoryId: UUID
    let imageUrl: String?
    let inRepair: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, sku, name, description, image_url, inRepair
        case basePrice = "base_price"
        case categoryId = "category_id"
    }
}