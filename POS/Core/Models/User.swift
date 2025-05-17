//
//  User.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation

struct AppUser: Codable, Identifiable, Equatable {
    let id: String
    let email: String
    
    var ownerPassword: String?
    var displayName: String
    var shopOwned: [Shop]
    
    static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        return lhs.id == rhs.id &&
               lhs.email == rhs.email &&
               lhs.ownerPassword == rhs.ownerPassword &&
               lhs.displayName == rhs.displayName &&
               lhs.shopOwned == rhs.shopOwned
    }
}

