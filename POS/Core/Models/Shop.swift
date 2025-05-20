//
//  Shop.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import Foundation
import FirebaseFirestore

struct Shop: Codable, Identifiable {
    @DocumentID var id: String?
    let shopName: String
    let createdAt: Date
    let updatedAt: Date
    
    var dictionary: [String: Any] {
        [
            "shopName": shopName,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}
