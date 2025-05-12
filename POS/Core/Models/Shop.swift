//
//  Shop.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import Foundation

struct Shop: Codable, Identifiable {
    var id: String
    var name: String
    var createdByMasterUID: String
    var createdAt: Date
}
