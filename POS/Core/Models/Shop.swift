//
//  Shop.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import Foundation

struct Shop: Codable, Identifiable, Equatable {
    let id: String
    var shopName: String
    let createdAt: Date
    
    static func == (lhs: Shop, rhs: Shop) -> Bool {
        return lhs.id == rhs.id &&
               lhs.shopName == rhs.shopName &&
               lhs.createdAt == rhs.createdAt
    }
}
