//
//  User.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import FirebaseFirestore

struct AppUser: Codable, Identifiable, Equatable {
    @DocumentID var id: String?
    let uid: String
    let email: String
    var displayName: String
    var photoURL: URL?
    var ownerPassword: String
    let createdAt: Date
    var updatedAt: Date
    
    var dictionary: [String: Any] {
        [
            "uid": uid,
            "email": email,
            "displayName": displayName,
            "photoURL": photoURL?.absoluteString as Any,
            "ownerPassword": ownerPassword,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
    }
}

