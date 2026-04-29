//
//  PricingService.swift
//  Group5_RSMS
//
//  Core/Pricing
//

import Foundation

/// A stateless engine for executing product pricing and tax calculations.
struct PricingService {
    
    /// Calculates the receipt breakdown for a given product considering additional category tax.
    /// - Parameters:
    ///   - product: The product containing the base price and category.
    ///   - additionalTaxRule: An optional admin-defined additional tax for the product's category.
    /// - Returns: A calculated `PricingBreakdown`.
    static func calculate(product: Product, additionalTaxRule: TaxRule?) -> PricingBreakdown {
        let base = product.basePrice
        let additionalRate = additionalTaxRule?.rate ?? 0.0
        
        let subtotal: Double
        let additionalTaxAmt: Double
        let total: Double
        
        // Logic: 
        // Tax is always added on top of the base price per recent requirement.
        
        subtotal = base
        additionalTaxAmt = base * additionalRate
        total = subtotal + additionalTaxAmt
        
        return PricingBreakdown(
            subtotal: subtotal,
            additionalTaxAmount: additionalTaxAmt,
            total: total
        )
    }
}
