import Foundation

struct IngredientAlert: Identifiable {
    let id: String
    let ingredientName: String
    let currentQuantity: Measurement
    let minQuantity: Measurement
    let percentage: Double
    
    init(ingredient: IngredientUsage) {
        self.id = ingredient.id ?? UUID().uuidString
        self.ingredientName = ingredient.name
        self.currentQuantity = Measurement(value: ingredient.quantity, unit: ingredient.measurementPerUnit.unit)
        self.minQuantity = Measurement(value: ingredient.minQuantity, unit: ingredient.measurementPerUnit.unit)
        
        // Tính phần trăm còn lại
        self.percentage = (ingredient.quantity / ingredient.minQuantity) * 100
    }
    
    var message: String {
        return "\(ingredientName) sắp hết hàng (còn \(String(format: "%.1f", percentage))%)"
    }
    
    var isUrgent: Bool {
        return percentage <= 120 // Cảnh báo khẩn cấp khi còn 120% của minQuantity
    }
} 
