import Foundation
import FirebaseFirestore

struct AppMenu: Codable, Identifiable {
    @DocumentID var id: String?
    let shopId: String
    var menuName: String
    var description: String?
    var isActive: Bool
    let createdAt: Date
    var updatedAt: Date
}
