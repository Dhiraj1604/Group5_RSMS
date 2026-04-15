//
//  PricingService.swift
//  Group5_RSMS
//
//  Core/Pricing
//

import Foundation

/// A stateless engine for executing product pricing and tax calculations.
public struct PricingService {
    
    /// Calculates the full receipt breakdown for a given product and tax rule.
    /// - Parameters:
    ///   - product: The product containing the base price.
    ///   - taxRule: The tax rule containing rate and inclusiveness settings.
    /// - Returns: A calculated `PricingBreakdown`.
    public static func calculate(product: Product, taxRule: TaxRule) -> PricingBreakdown {
        let base = product.basePrice
        let rate = taxRule.rate
        
        let subtotal: Double
        let taxAmount: Double
        let total: Double
        
        if taxRule.isInclusive {
            // Price already includes the tax
            // Example: $120 total with 20% VAT
            // subtotal = 120 / 1.20 = 100
            // tax = 120 - 100 = 20
            total = base
            subtotal = base / (1 + rate)
            taxAmount = total - subtotal
        } else {
            // Tax is added ON TOP of the base price
            // Example: $100 base with 10% sales tax
            // tax = 10
            // total = 110
            subtotal = base
            taxAmount = base * rate
            total = subtotal + taxAmount
        }
        
        return PricingBreakdown(
            subtotal: subtotal,
            taxAmount: taxAmount,
            total: total
        )
    }
}
