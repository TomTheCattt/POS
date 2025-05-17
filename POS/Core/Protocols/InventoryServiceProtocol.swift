import Foundation
import Combine

// MARK: - Supporting Types

enum InventoryCategory: String, Codable, CaseIterable {
    case ingredients
    case packaging
    case equipment
    case supplies
    case other
}

//struct InventoryReport: Codable {
//    let totalItems: Int
//    let totalValue: Double
//    let lowStockItems: [InventoryItem]
//    let categoryBreakdown: [InventoryCategory: Int]
//    let valueByCategory: [InventoryCategory: Double]
//    let generatedAt: Date
//} 
