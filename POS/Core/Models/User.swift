//
//  User.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation

struct AppUser: Codable, Identifiable {
    let id: String
    let email: String
    
    var ownerPassword: String?
    var displayName: String
    var shopOwned: [Shop]
}

