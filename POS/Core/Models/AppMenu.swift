import Foundation
import FirebaseFirestore

struct AppMenu: Codable, Identifiable {
    @DocumentID var id: String?
    var menuName: String
    var description: String?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
    
    var dictionary: [String: Any] {
        var dict: [String: Any] = [
            "menuName": menuName,
            "isActive": isActive,
            "createdAt": createdAt,
            "updatedAt": updatedAt
        ]
        if let description = description {
            dict["description"] = description
        }
        return dict
    }
}

extension AppMenu {
    init?(document: DocumentSnapshot) {
        guard let data = document.data(),
              let menuName = data["menuName"] as? String,
              let isActive = data["isActive"] as? Bool,
              let description = data["description"] as? String,
              let createdAtTimestamp = data["createdAt"] as? Timestamp,
              let updatedAtTimestamp = data["updatedAt"] as? Timestamp
        else {
            return nil
        }
        
        self.id = document.documentID
        self.menuName = menuName
        self.isActive = isActive
        self.description = description
        self.createdAt = createdAtTimestamp.dateValue()
        self.updatedAt = updatedAtTimestamp.dateValue()
    }
} 
