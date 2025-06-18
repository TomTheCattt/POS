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
    let shopId: String
    var name: String
    var phoneNumber: String
    var point: Double
    let gender: Gender
    
    var displayName: String {
        "\(gender.prefix). \(name)"
    }
}

