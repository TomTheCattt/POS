//
//  ShopService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 13/5/25.
//

import Foundation

final class ShopService: ShopServiceProtocol {
    func getShopDetails() async throws -> Shop {
        return Shop(id: "", shopName: "", createdAt: Date())
    }
    
    func updateShop(shop: Shop) async throws -> Shop {
        return Shop(id: "", shopName: "", createdAt: Date())
    }
}
