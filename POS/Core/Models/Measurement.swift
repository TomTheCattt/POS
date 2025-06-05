import Foundation

struct Measurement: Codable, Equatable, Hashable {
    let value: Double
    let unit: MeasurementUnit
    
    init(value: Double, unit: MeasurementUnit) {
        self.value = max(0, value) // Ensure non-negative values
        self.unit = unit
    }
    
    var dictionary: [String: Any] {
        [
            "value": value,
            "unit": unit.rawValue
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let value = dictionary["value"] as? Double,
              let unitString = dictionary["unit"] as? String,
              let unit = MeasurementUnit(rawValue: unitString) else {
            return nil
        }
        
        self.init(value: value, unit: unit)
    }
    
    // MARK: - Display
    var displayString: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        
        let valueString = formatter.string(from: NSNumber(value: value)) ?? "\(value)"
        return "\(valueString) \(unit.shortDisplayName)"
    }
    
    // MARK: - Unit Conversion
    private func conversionFactor(from sourceUnit: MeasurementUnit, to targetUnit: MeasurementUnit) -> Double? {
        guard sourceUnit.isCompatible(with: targetUnit) else { return nil }
        
        switch (sourceUnit, targetUnit) {
        // Weight conversions
        case (.gram, .kilogram): return 1.0 / 1000.0
        case (.kilogram, .gram): return 1000.0
        case (.gram, .gram), (.kilogram, .kilogram): return 1.0
            
        // Volume conversions
        case (.milliliter, .liter): return 1.0 / 1000.0
        case (.liter, .milliliter): return 1000.0
        case (.milliliter, .milliliter), (.liter, .liter): return 1.0
            
        // Same unit
        case (.piece, .piece): return 1.0
            
        default: return nil
        }
    }
    
    func converted(to targetUnit: MeasurementUnit) -> Measurement? {
        guard let factor = conversionFactor(from: unit, to: targetUnit) else {
            return nil
        }
        
        return Measurement(value: value * factor, unit: targetUnit)
    }
    
    // MARK: - Arithmetic Operations
    func multiplied(by multiplier: Double) -> Measurement {
        Measurement(value: value * multiplier, unit: unit)
    }
    
    func adding(_ other: Measurement) -> Measurement? {
        guard let otherConverted = other.converted(to: unit) else { return nil }
        return Measurement(value: value + otherConverted.value, unit: unit)
    }
    
    func subtracting(_ other: Measurement) -> Measurement? {
        guard let otherConverted = other.converted(to: unit) else { return nil }
        return Measurement(value: max(0, value - otherConverted.value), unit: unit)
    }
    
    // MARK: - Comparison
    func isGreaterThan(_ other: Measurement) -> Bool {
        guard let otherConverted = other.converted(to: unit) else { return false }
        return value > otherConverted.value
    }
    
    func isLessThan(_ other: Measurement) -> Bool {
        guard let otherConverted = other.converted(to: unit) else { return false }
        return value < otherConverted.value
    }
}
