//
//  Customer.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/4/25.
//

import Foundation
import FirebaseFirestore

enum Gender: String, Codable {
    case male = "male"
    case female = "female"
    
    var prefix: String {
        switch self {
        case .male: return "Mr"
        case .female: return "Ms"
        }
    }
}

struct Customer: Codable, Identifiable, Equatable, Hashable {
    @DocumentID var id: String?
    var name: String
    var phoneNumber: String
    var point: Double
    var gender: Gender
    
    var displayName: String {
        "\(gender.prefix). \(name)"
    }
    
//    var dictionary: [String: Any] {
//        [
//            "name": name,
//            "phoneNumber": phoneNumber,
//            "point": point,
//            "gender": gender.rawValue
//        ]
//    }
//    
//    init(id: String? = nil, name: String, phoneNumber: String, point: Double, gender: Gender) {
//        self.id = id
//        self.name = name
//        self.phoneNumber = phoneNumber
//        self.point = point
//        self.gender = gender
//    }
//    
//    init?(dictionary: [String: Any]) {
//        guard let customerId = dictionary["id"] as? String,
//              let customerName = dictionary["name"] as? String,
//              let customerPhoneNumber = dictionary["phoneNumber"] as? String,
//              let customerPoint = dictionary["point"] as? Double,
//              let genderRaw = dictionary["gender"] as? String,
//              let gender = Gender(rawValue: genderRaw) else {
//            return nil
//        }
//        
//        self.init(
//            id: customerId,
//            name: customerName,
//            phoneNumber: customerPhoneNumber,
//            point: customerPoint,
//            gender: gender
//        )
//    }
}

