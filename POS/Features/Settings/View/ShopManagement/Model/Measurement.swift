import Foundation
import FirebaseFirestore

struct Measurement: Codable, Equatable, Hashable {
    let value: Double
    let unit: MeasurementUnit
    
    // MARK: - Initialization
    init(value: Double, unit: MeasurementUnit) {
        self.value = max(0, value) // Ensure non-negative values
        self.unit = unit
    }
    
    // MARK: - Firestore Dictionary Conversion
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
    
    var formattedValue: String {
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 2
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
    var fullDisplayString: String {
        return "\(formattedValue) \(unit.displayName)"
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
    
    func isEqualTo(_ other: Measurement) -> Bool {
        guard let otherConverted = other.converted(to: unit) else { return false }
        return abs(value - otherConverted.value) < 0.001 // Small tolerance for floating point comparison
    }
    
    func isGreaterThanOrEqualTo(_ other: Measurement) -> Bool {
        return isGreaterThan(other) || isEqualTo(other)
    }
    
    func isLessThanOrEqualTo(_ other: Measurement) -> Bool {
        return isLessThan(other) || isEqualTo(other)
    }
    
    // MARK: - Helper Methods
    func isZero() -> Bool {
        return value == 0
    }
    
    func isPositive() -> Bool {
        return value > 0
    }
    
    func isNegative() -> Bool {
        return value < 0
    }
    
    func absolute() -> Measurement {
        return Measurement(value: abs(value), unit: unit)
    }
    
    func rounded(to places: Int) -> Measurement {
        let multiplier = pow(10.0, Double(places))
        let roundedValue = (value * multiplier).rounded() / multiplier
        return Measurement(value: roundedValue, unit: unit)
    }
    
    func roundedToNearest(_ increment: Double) -> Measurement {
        let roundedValue = (value / increment).rounded() * increment
        return Measurement(value: roundedValue, unit: unit)
    }
    
    // MARK: - Validation
    func isValid() -> Bool {
        return value >= 0 && !value.isNaN && !value.isInfinite
    }
    
    func isReasonable() -> Bool {
        // Check if the value is within reasonable bounds for the unit
        switch unit {
        case .gram, .kilogram:
            return value >= 0 && value <= 1000000 // Max 1 ton
        case .milliliter, .liter:
            return value >= 0 && value <= 1000000 // Max 1000 liters
        case .piece:
            return value >= 0 && value <= 100000 // Max 100k pieces
        }
    }
}

// MARK: - Comparable
extension Measurement: Comparable {
    static func < (lhs: Measurement, rhs: Measurement) -> Bool {
        guard let rhsConverted = rhs.converted(to: lhs.unit) else { return false }
        return lhs.value < rhsConverted.value
    }
    
    static func <= (lhs: Measurement, rhs: Measurement) -> Bool {
        guard let rhsConverted = rhs.converted(to: lhs.unit) else { return false }
        return lhs.value <= rhsConverted.value
    }
    
    static func > (lhs: Measurement, rhs: Measurement) -> Bool {
        guard let rhsConverted = rhs.converted(to: lhs.unit) else { return false }
        return lhs.value > rhsConverted.value
    }
    
    static func >= (lhs: Measurement, rhs: Measurement) -> Bool {
        guard let rhsConverted = rhs.converted(to: lhs.unit) else { return false }
        return lhs.value >= rhsConverted.value
    }
}

// MARK: - Custom Operators
extension Measurement {
    static func + (lhs: Measurement, rhs: Measurement) -> Measurement? {
        return lhs.adding(rhs)
    }
    
    static func - (lhs: Measurement, rhs: Measurement) -> Measurement? {
        return lhs.subtracting(rhs)
    }
    
    static func * (lhs: Measurement, rhs: Double) -> Measurement {
        return lhs.multiplied(by: rhs)
    }
    
    static func * (lhs: Double, rhs: Measurement) -> Measurement {
        return rhs.multiplied(by: lhs)
    }
}

// MARK: - Measurement Factory Methods
extension Measurement {
    static func zero(unit: MeasurementUnit) -> Measurement {
        return Measurement(value: 0, unit: unit)
    }
    
    static func one(unit: MeasurementUnit) -> Measurement {
        return Measurement(value: 1, unit: unit)
    }
    
    static func fromString(_ string: String, unit: MeasurementUnit) -> Measurement? {
        let cleanedString = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let value = Double(cleanedString) else { return nil }
        return Measurement(value: value, unit: unit)
    }
    
    static func parse(_ string: String) -> Measurement? {
        let components = string.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: .whitespaces)
        guard components.count >= 2 else { return nil }
        
        guard let value = Double(components[0]) else { return nil }
        
        let unitString = components[1].lowercased()
        let unit: MeasurementUnit
        
        switch unitString {
        case "g", "gram", "grams":
            unit = .gram
        case "kg", "kilogram", "kilograms":
            unit = .kilogram
        case "ml", "milliliter", "milliliters":
            unit = .milliliter
        case "l", "liter", "liters":
            unit = .liter
        case "cái", "piece", "pieces":
            unit = .piece
        default:
            return nil
        }
        
        return Measurement(value: value, unit: unit)
    }
}

// MARK: - Measurement Validation
extension Measurement {
    enum ValidationError: LocalizedError {
        case invalidValue
        case invalidUnit
        case valueOutOfRange
        case incompatibleUnits
        
        var errorDescription: String? {
            switch self {
            case .invalidValue:
                return "Giá trị không hợp lệ"
            case .invalidUnit:
                return "Đơn vị không hợp lệ"
            case .valueOutOfRange:
                return "Giá trị nằm ngoài phạm vi cho phép"
            case .incompatibleUnits:
                return "Đơn vị không tương thích"
            }
        }
    }
    
    func validate() throws {
        // Validate value
        guard !value.isNaN && !value.isInfinite else {
            throw ValidationError.invalidValue
        }
        
        guard value >= 0 else {
            throw ValidationError.invalidValue
        }
        
        // Validate unit
        guard MeasurementUnit.allCases.contains(unit) else {
            throw ValidationError.invalidUnit
        }
        
        // Validate range
        guard isReasonable() else {
            throw ValidationError.valueOutOfRange
        }
    }
    
    static func validateConversion(from sourceUnit: MeasurementUnit, to targetUnit: MeasurementUnit) throws {
        guard sourceUnit.isCompatible(with: targetUnit) else {
            throw ValidationError.incompatibleUnits
        }
    }
}
