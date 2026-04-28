//
//  PricingService.swift
//  Group5_RSMS
//
//  Core/Pricing
//

import Foundation

/// A stateless engine for executing product pricing and tax calculations.
struct PricingService {
    
    /// Calculates the full receipt breakdown for a given product, considering regional tax and additional category tax.
    /// - Parameters:
    ///   - product: The product containing the base price and category.
    ///   - regionalRate: The base tax rate for the boutique's region (e.g. 0.18 for 18%).
    ///   - additionalTaxRule: An optional admin-defined additional tax for the product's category.
    /// - Returns: A calculated `PricingBreakdown`.
    static func calculate(product: Product, regionalRate: Double, additionalTaxRule: TaxRule?) -> PricingBreakdown {
        let base = product.basePrice
        let additionalRate = additionalTaxRule?.rate ?? 0.0
        
        let subtotal: Double
        let regionalTaxAmt: Double
        let additionalTaxAmt: Double
        let taxAmount: Double
        let total: Double
        
        // Logic: 
        // 1. Regional tax is ALWAYS added on top of the subtotal.
        // 2. Additional category tax can be inclusive or exclusive.
        
        if let rule = additionalTaxRule, rule.isInclusive {
            // Base price includes the additional tax
            let subtotalWithAdditional = base
            subtotal = subtotalWithAdditional / (1 + additionalRate)
            
            additionalTaxAmt = subtotalWithAdditional - subtotal
            regionalTaxAmt = subtotal * regionalRate
            
            taxAmount = additionalTaxAmt + regionalTaxAmt
            total = subtotal + taxAmount
        } else {
            // Both taxes are added on top of the base price
            subtotal = base
            regionalTaxAmt = base * regionalRate
            additionalTaxAmt = base * additionalRate
            
            taxAmount = regionalTaxAmt + additionalTaxAmt
            total = subtotal + taxAmount
        }
        
        return PricingBreakdown(
            subtotal: subtotal,
            regionalTaxAmount: regionalTaxAmt,
            additionalTaxAmount: additionalTaxAmt,
            total: total
        )
    }
}
