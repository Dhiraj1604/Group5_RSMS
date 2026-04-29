//
//  ICReportPDFGenerator.swift
//  Group5_RSMS
//

import SwiftUI
import PDFKit
import UniformTypeIdentifiers

struct PDFReportDocument: Transferable, Sendable {
    let data: Data
    let filename: String
    
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .pdf) { doc in
            doc.data
        }
        .suggestedFileName { doc in
            doc.filename
        }
    }
}

@MainActor
class ICReportPDFGenerator {
    
    static func generateVariancePDF(data: [VarianceReportItem], storeName: String) -> Data {
        let view = VarianceReportPDFView(data: data, storeName: storeName)
        let renderer = ImageRenderer(content: view)
        
        let pdfData = NSMutableData()
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: pdfData),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else { return }
            
            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        return pdfData as Data
    }
    
    static func generateHeatMapPDF(heatmapData: [InventoryItem], storeName: String) -> Data {
        let view = HeatMapPDFView(heatmapData: heatmapData, storeName: storeName)
        let renderer = ImageRenderer(content: view)
        
        let pdfData = NSMutableData()
        renderer.render { size, context in
            var box = CGRect(origin: .zero, size: size)
            guard let consumer = CGDataConsumer(data: pdfData),
                  let pdfContext = CGContext(consumer: consumer, mediaBox: &box, nil) else { return }
            
            pdfContext.beginPDFPage(nil)
            context(pdfContext)
            pdfContext.endPDFPage()
            pdfContext.closePDF()
        }
        return pdfData as Data
    }
}

// MARK: - PDF Views

struct VarianceReportPDFView: View {
    let data: [VarianceReportItem]
    let storeName: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventory Variance Report")
                        .font(.system(size: 24, weight: .bold))
                    Text("Store: \(storeName)")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            VStack(spacing: 0) {
                // Table Header
                HStack {
                    Text("Product")
                        .font(.system(size: 12, weight: .bold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text("Status")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 80, alignment: .leading)
                    Text("Exp")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 40, alignment: .center)
                    Text("Act")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 40, alignment: .center)
                    Text("Var")
                        .font(.system(size: 12, weight: .bold))
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.vertical, 10)
                .background(Color(white: 0.95))
                
                Divider()
                
                ForEach(data) { item in
                    HStack {
                        Text(item.product?.name ?? "Unknown Product")
                            .font(.system(size: 11))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(item.status.capitalized)
                            .font(.system(size: 10, weight: .medium))
                            .frame(width: 80, alignment: .leading)
                        
                        Text("\(item.expectedQuantity)")
                            .font(.system(size: 11))
                            .frame(width: 40, alignment: .center)
                        
                        Text("\(item.actualScannedQuantity)")
                            .font(.system(size: 11))
                            .frame(width: 40, alignment: .center)
                        
                        Text("\(item.variance > 0 ? "+" : "")\(item.variance)")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(item.variance < 0 ? .red : (item.variance > 0 ? .green : .black))
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    Divider()
                }
            }
        }
        .padding(40)
        .frame(width: 600) // Standard A4-ish width for renderer
        .background(Color.white)
    }
}

struct HeatMapPDFView: View {
    let heatmapData: [InventoryItem]
    let storeName: String
    
    var body: some View {
        let categories = Array(Set(heatmapData.compactMap { $0.product?.category ?? "Other" })).sorted()
        let statuses = ["Critical", "Low", "Healthy", "In-Stock", "Floor", "Backroom"]
        
        var matrix: [String: [String: Int]] = [:]
        for item in heatmapData {
            let cat = item.product?.category ?? "Other"
            let minStock = item.minStockLevel ?? 5
            let maxStock = item.maxStockLevel ?? 50
            
            let status: String
            if item.stockQuantity <= 2 { status = "Critical" }
            else if item.stockQuantity < minStock { status = "Low" }
            else if item.stockQuantity > maxStock { status = "In-Stock" }
            else { status = "Healthy" }
            
            matrix[cat, default: [:]][status] = (matrix[cat]?[status] ?? 0) + 1
            let locStatus = (item.isOnFloor == true) ? "Floor" : "Backroom"
            matrix[cat, default: [:]][locStatus] = (matrix[cat]?[locStatus] ?? 0) + 1
        }
        
        return VStack(alignment: .leading, spacing: 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Inventory Heat Map")
                        .font(.system(size: 24, weight: .bold))
                    Text("Store: \(storeName)")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                }
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .shortened))
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
            }
            
            Divider()
            
            VStack(alignment: .leading, spacing: 10) {
                // Header row
                HStack(spacing: 5) {
                    Text("Category")
                        .font(.system(size: 10, weight: .bold))
                        .frame(width: 100, alignment: .leading)
                    
                    ForEach(statuses, id: \.self) { status in
                        Text(status)
                            .font(.system(size: 9, weight: .bold))
                            .frame(width: 60, height: 30)
                            .multilineTextAlignment(.center)
                    }
                }
                
                ForEach(categories, id: \.self) { category in
                    HStack(spacing: 5) {
                        Text(category)
                            .font(.system(size: 10))
                            .frame(width: 100, alignment: .leading)
                        
                        ForEach(statuses, id: \.self) { status in
                            let val = matrix[category]?[status] ?? 0
                            ZStack {
                                Rectangle()
                                    .fill(val > 0 ? Color.orange.opacity(0.2) : Color.gray.opacity(0.05))
                                Text("\(val)")
                                    .font(.system(size: 10))
                            }
                            .frame(width: 60, height: 30)
                        }
                    }
                }
            }
        }
        .padding(40)
        .frame(width: 600)
        .background(Color.white)
    }
}
