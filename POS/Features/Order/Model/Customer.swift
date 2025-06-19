//
//  Customer.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/4/25.
//

import Foundation
import FirebaseFirestore

enum Gender: String, Codable, CaseIterable {
    case male = "male"
    case female = "female"
    case other = "other"
    
    var prefix: String {
        switch self {
        case .male: return "Mr"
        case .female: return "Ms"
        case .other: return ""
        }
    }
    
    var displayName: String {
        switch self {
        case .male: return "Nam"
        case .female: return "Nữ"
        case .other: return "Khác"
        }
    }
    
    var icon: String {
        switch self {
        case .male: return "person.fill"
        case .female: return "person.fill"
        case .other: return "person"
        }
    }
}

struct Customer: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    let shopId: String
    var name: String
    var phoneNumber: String
    var point: Double
    let gender: Gender
    
    // MARK: - Computed Properties
    var displayName: String {
        if gender == .other {
            return name
        }
        return "\(gender.prefix). \(name)"
    }
    
    var formattedPhoneNumber: String {
        // Format phone number for display
        let cleaned = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        if cleaned.count == 10 {
            return "\(cleaned.prefix(3)) \(cleaned.dropFirst(3).prefix(3)) \(cleaned.dropFirst(6))"
        } else if cleaned.count == 11 {
            return "\(cleaned.prefix(4)) \(cleaned.dropFirst(4).prefix(3)) \(cleaned.dropFirst(7))"
        }
        return phoneNumber
    }
    
    var formattedPoint: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let formattedNumber = formatter.string(from: NSNumber(value: point)) ?? "0"
        return "\(formattedNumber) điểm"
    }
    
    // MARK: - Initialization
    init(
        id: String? = nil,
        shopId: String,
        name: String,
        phoneNumber: String,
        point: Double = 0.0,
        gender: Gender = .other
    ) {
        self.id = id
        self.shopId = shopId
        self.name = name
        self.phoneNumber = phoneNumber
        self.point = point
        self.gender = gender
    }
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        [
            "shopId": shopId,
            "name": name,
            "phoneNumber": phoneNumber,
            "point": point,
            "gender": gender.rawValue
        ]
    }
    
    init?(dictionary: [String: Any]) {
        guard let shopId = dictionary["shopId"] as? String,
              let name = dictionary["name"] as? String,
              let phoneNumber = dictionary["phoneNumber"] as? String,
              let point = dictionary["point"] as? Double,
              let genderRaw = dictionary["gender"] as? String,
              let gender = Gender(rawValue: genderRaw) else {
            return nil
        }
        
        self.init(
            shopId: shopId,
            name: name,
            phoneNumber: phoneNumber,
            point: point,
            gender: gender
        )
    }
    
    // MARK: - Mutating Methods
    
    // MARK: - Helper Methods
    func canRedeemPoints(_ requiredPoints: Double) -> Bool {
        return point >= requiredPoints
    }
    
    func getDiscountAmount(pointRate: Double) -> Double {
        return (point * pointRate) / 100
    }
}

// MARK: - Validation
extension Customer {
    enum ValidationError: LocalizedError {
        case invalidName
        case invalidPhoneNumber
        case invalidEmail
        case invalidAddress
        case invalidBirthDate
        case duplicatePhoneNumber
        
        var errorDescription: String? {
            switch self {
            case .invalidName:
                return "Tên khách hàng không hợp lệ"
            case .invalidPhoneNumber:
                return "Số điện thoại không hợp lệ"
            case .invalidEmail:
                return "Email không hợp lệ"
            case .invalidAddress:
                return "Địa chỉ không hợp lệ"
            case .invalidBirthDate:
                return "Ngày sinh không hợp lệ"
            case .duplicatePhoneNumber:
                return "Số điện thoại đã tồn tại"
            }
        }
    }
    
    func validate() throws {
        // Validate name
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw ValidationError.invalidName
        }
        
        guard trimmedName.count >= 2 && trimmedName.count <= 100 else {
            throw ValidationError.invalidName
        }
        
        // Validate phone number
        let cleanedPhone = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard cleanedPhone.count >= 10 && cleanedPhone.count <= 11 else {
            throw ValidationError.invalidPhoneNumber
        }
    }
    
    static func validatePhoneNumber(_ phoneNumber: String, existingCustomers: [Customer], excludeId: String? = nil) throws {
        let cleanedPhone = phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
        guard cleanedPhone.count >= 10 && cleanedPhone.count <= 11 else {
            throw ValidationError.invalidPhoneNumber
        }
        
        // Check for duplicate phone numbers
        let duplicateExists = existingCustomers.contains { customer in
            let customerCleanedPhone = customer.phoneNumber.replacingOccurrences(of: "[^0-9]", with: "", options: .regularExpression)
            return customerCleanedPhone == cleanedPhone && customer.id != excludeId
        }
        
        if duplicateExists {
            throw ValidationError.duplicatePhoneNumber
        }
    }
}

