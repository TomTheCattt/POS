//
//  User.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable {
    @DocumentID var id: String?
    let email: String
    let displayName: String
    var emailVerified: Bool
    let photoURL: URL?
    let createdAt: Date
    let updatedAt: Date
    
    var dictionary: [String: Any] {
        [
            "email": email,
            "displayName": displayName,
            "emailVerified": emailVerified,
            "photoURL": photoURL?.absoluteString as Any,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

