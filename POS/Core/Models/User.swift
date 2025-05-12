//
//  User.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation

struct SessionUser {
    let id: String
    let email: String?
}

struct AppUser: Codable, Identifiable {
    var id: String
    var email: String
    
    var ownerPassword: String?
}

