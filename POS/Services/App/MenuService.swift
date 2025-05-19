//
//  MenuService.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/5/25.
//

import Combine
import FirebaseCore
import FirebaseFirestore
import FirebaseAuth

final class MenuService: MenuServiceProtocol {
    
    static let shared = MenuService()
    
    @Published private(set) var menuItems: [MenuItem]?
    
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        setupMenuItemsListener()
    }
    
    private func setupMenuItemsListener() {
        
    }
    
    func getMenuItems() async throws -> [MenuItem] {
        return [MenuItem(id: "", name: "", price: 1, category: "", ingredients: [IngredientUsage(inventoryItemID: "", quantity: 1, unit: .gram)], isAvailable: true)]
    }
    
    func searchMenuItem() {
        
    }
    
    func updateMenuItem(with: MenuItem) {
        
    }
}
