import Foundation
import FirebaseFirestore
import SwiftUI

struct AppMenu: Codable, Identifiable, Hashable {
    @DocumentID var id: String?
    let shopId: String
    var menuName: String
    var description: String?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    
    // MARK: - Initialization
    init(
        id: String? = nil,
        shopId: String,
        menuName: String,
        description: String? = nil,
        isActive: Bool = true,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.shopId = shopId
        self.menuName = menuName
        self.description = description
        self.isActive = isActive
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    // MARK: - Computed Properties
    var displayName: String {
        return menuName
    }
    
    var statusText: String {
        return isActive ? "Đang hoạt động" : "Tạm ngưng"
    }
    
    var statusColor: Color {
        return isActive ? .green : .red
    }
    
    // MARK: - Firestore Dictionary Conversion
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "shopId": shopId,
            "menuName": menuName,
            "isActive": isActive,
            "createdAt": Timestamp(date: createdAt),
            "updatedAt": Timestamp(date: updatedAt)
        ]
        
        if let description = description {
            dict["description"] = description
        }
        
        return dict
    }
    
    init?(dictionary: [String: Any]) {
        guard let shopId = dictionary["shopId"] as? String,
              let menuName = dictionary["menuName"] as? String,
              let isActive = dictionary["isActive"] as? Bool,
              let createdAtTimestamp = dictionary["createdAt"] as? Timestamp,
              let updatedAtTimestamp = dictionary["updatedAt"] as? Timestamp,
              let sortOrder = dictionary["sortOrder"] as? Int else {
            return nil
        }
        
        self.init(
            shopId: shopId,
            menuName: menuName,
            description: dictionary["description"] as? String,
            isActive: isActive,
            createdAt: createdAtTimestamp.dateValue(),
            updatedAt: updatedAtTimestamp.dateValue()
        )
    }
    
    // MARK: - Mutating Methods
    mutating func updateMenuName(_ newMenuName: String) {
        menuName = newMenuName
        updatedAt = Date()
    }
    
    mutating func updateDescription(_ newDescription: String?) {
        description = newDescription
        updatedAt = Date()
    }
    
    mutating func toggleActive() {
        isActive.toggle()
        updatedAt = Date()
    }
    
    // MARK: - Helper Methods
    
    func matchesSearch(_ searchText: String) -> Bool {
        let searchLower = searchText.lowercased()
        return menuName.lowercased().contains(searchLower) ||
               (description?.lowercased().contains(searchLower) ?? false)
    }
}

// MARK: - Comparable
extension AppMenu: Comparable {
    static func < (lhs: AppMenu, rhs: AppMenu) -> Bool {
        return lhs.menuName < rhs.menuName
    }
}

// MARK: - Validation
extension AppMenu {
    enum ValidationError: LocalizedError {
        case invalidMenuName
        case invalidDescription
        case invalidCategory
        case invalidSortOrder
        case duplicateMenuName
        
        var errorDescription: String? {
            switch self {
            case .invalidMenuName:
                return "Tên thực đơn không hợp lệ"
            case .invalidDescription:
                return "Mô tả không hợp lệ"
            case .invalidCategory:
                return "Danh mục không hợp lệ"
            case .invalidSortOrder:
                return "Thứ tự sắp xếp không hợp lệ"
            case .duplicateMenuName:
                return "Tên thực đơn đã tồn tại"
            }
        }
    }
    
    func validate() throws {
        // Validate menu name
        let trimmedMenuName = menuName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMenuName.isEmpty else {
            throw ValidationError.invalidMenuName
        }
        
        guard trimmedMenuName.count >= 2 && trimmedMenuName.count <= 100 else {
            throw ValidationError.invalidMenuName
        }
        
        // Validate description if provided
        if let description = description {
            let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
            guard trimmedDescription.count <= 500 else {
                throw ValidationError.invalidDescription
            }
        }
    }
    
    static func validateMenuName(_ menuName: String, existingMenus: [AppMenu], excludeId: String? = nil) throws {
        let trimmedMenuName = menuName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedMenuName.isEmpty else {
            throw ValidationError.invalidMenuName
        }
        
        guard trimmedMenuName.count >= 2 && trimmedMenuName.count <= 100 else {
            throw ValidationError.invalidMenuName
        }
        
        // Check for duplicate menu names
        let duplicateExists = existingMenus.contains { menu in
            menu.menuName.lowercased() == trimmedMenuName.lowercased() && menu.id != excludeId
        }
        
        if duplicateExists {
            throw ValidationError.duplicateMenuName
        }
    }
}
