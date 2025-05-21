import Foundation

protocol DatabaseIdentifiable: Identifiable {
    var id: String? { get set }
}

extension DatabaseIdentifiable {
    var documentId: String {
        return id ?? ""
    }
    
    var isNew: Bool {
        return id == nil
    }
}

// MARK: - Default Implementation
extension DatabaseIdentifiable {
    mutating func setId(_ id: String) {
        self.id = id
    }
    
    mutating func clearId() {
        self.id = nil
    }
} 