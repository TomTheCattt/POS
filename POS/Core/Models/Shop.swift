//
//  Shop.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import Foundation

struct Shop: Codable, Identifiable {
    let id: String
    var shopName: String
    let createdAt: Date
    var menuItems: [MenuItem]?
    var inventoryItems: [InventoryItem]?
}
