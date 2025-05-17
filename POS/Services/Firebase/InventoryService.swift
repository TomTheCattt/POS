import Foundation
import FirebaseFirestore
import Combine

final class InventoryService: InventoryServiceProtocol {
    // MARK: - Singleton
    static let shared = InventoryService()
    
    // MARK: - Properties
    private let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private let inventorySubject = CurrentValueSubject<[InventoryItem], Never>([])
    
    // MARK: - Published Properties
    var currentInventory: [InventoryItem] {
        inventorySubject.value
    }
    
    var inventoryPublisher: AnyPublisher<[InventoryItem], Never> {
        inventorySubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    private init() {
        setupRealtimeUpdates()
    }
    
    // MARK: - Private Methods
    private func setupRealtimeUpdates() {
        db.collection("inventory")
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("Error fetching inventory: \(error?.localizedDescription ?? "Unknown error")")
                    return
                }
                
                let items = documents.compactMap { InventoryItem(document: $0) }
                self?.inventorySubject.send(items)
            }
    }
    
    // MARK: - CRUD Operations
    func createItem(_ item: InventoryItem) async throws -> InventoryItem {
        let docRef = try await db.collection("inventory").addDocument(data: item.dictionary)
        
        // Fetch the created document to return the complete item
        let doc = try await docRef.getDocument()
        guard let newItem = InventoryItem(document: doc) else {
            throw AppError.database(.documentNotFound)
        }
        
        return newItem
    }
    
    func getItem(id: String) async throws -> InventoryItem {
        let doc = try await db.collection("inventory").document(id).getDocument()
        
        guard let item = InventoryItem(document: doc) else {
            throw AppError.database(.documentNotFound)
        }
        
        return item
    }
    
    func updateItem(_ item: InventoryItem) async throws -> InventoryItem {
        
        let docRef = db.collection("inventory").document(item.id)
        try await docRef.setData(item.dictionary, merge: true)
        
        // Fetch the updated document to return the complete item
        let doc = try await docRef.getDocument()
        guard let updatedItem = InventoryItem(document: doc) else {
            throw AppError.database(.documentNotFound)
        }
        
        return updatedItem
    }
    
    func deleteItem(id: String) async throws {
        try await db.collection("inventory").document(id).delete()
    }
    
    func getAllItems() async throws -> [InventoryItem] {
        let snapshot = try await db.collection("inventory").getDocuments()
        return snapshot.documents.compactMap { InventoryItem(document: $0) }
    }
    
    // MARK: - Inventory Management
    func adjustQuantity(itemId: String, adjustment: Double) async throws {
        let docRef = db.collection("inventory").document(itemId)
        
        try await db.runTransaction { transaction, errorPointer in
            let doc: DocumentSnapshot
            do {
                doc = try transaction.getDocument(docRef)
            } catch let fetchError as NSError {
                errorPointer?.pointee = fetchError
                return nil
            }
            
            guard let currentQuantity = doc.data()?["quantity"] as? Double else {
                let error = AppError.database(.invalidData)
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            let newQuantity = currentQuantity + adjustment
            if newQuantity < 0 {
                let error = AppError.inventory(.insufficientStock)
                errorPointer?.pointee = error as NSError
                return nil
            }
            
            transaction.updateData([
                "quantity": newQuantity,
                "updatedAt": Timestamp(date: Date()),
                "lastRestockDate": adjustment > 0 ? Timestamp(date: Date()) : nil
            ], forDocument: docRef)
            
            return nil
        }
    }
    
    func checkStock(itemId: String, requiredQuantity: Double) async throws -> Bool {
        let doc = try await db.collection("inventory").document(itemId).getDocument()
        guard let currentQuantity = doc.data()?["quantity"] as? Double else {
            throw AppError.database(.invalidData)
        }
        return currentQuantity >= requiredQuantity
    }
    
    func getItemsByCategory(_ category: InventoryCategory) async throws -> [InventoryItem] {
        let snapshot = try await db.collection("inventory")
            .whereField("category", isEqualTo: category.rawValue)
            .getDocuments()
        
        return snapshot.documents.compactMap { InventoryItem(document: $0) }
    }
    
    func getLowStockItems(threshold: Double) async throws -> [InventoryItem] {
        let snapshot = try await db.collection("inventory")
            .whereField("quantity", isLessThanOrEqualTo: threshold)
            .getDocuments()
        
        return snapshot.documents.compactMap { InventoryItem(document: $0) }
    }
    
    // MARK: - Batch Operations
    func batchUpdateQuantities(_ updates: [(id: String, quantity: Double)]) async throws {
        let batch = db.batch()
        
        for update in updates {
            let docRef = db.collection("inventory").document(update.id)
            batch.updateData([
                "quantity": update.quantity,
                "updatedAt": Timestamp(date: Date())
            ], forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    func batchCreateItems(_ items: [InventoryItem]) async throws {
        let batch = db.batch()
        
        for item in items {
            let docRef = db.collection("inventory").document()
            batch.setData(item.dictionary, forDocument: docRef)
        }
        
        try await batch.commit()
    }
    
    // MARK: - Reports
    func generateInventoryReport() async throws -> InventoryReport {
        let snapshot = try await db.collection("inventory").getDocuments()
        let items = snapshot.documents.compactMap { InventoryItem(document: $0) }
        
        let totalItems = items.count
        let totalValue = items.reduce(0) { $0 + $1.value }
        let lowStockItems = items.filter { $0.isLowStock }
        let outOfStockItems = items.filter { $0.quantity <= 0 }
        
        var categoryValues: [InventoryCategory: Double] = [:]
        for item in items {
            categoryValues[item.category, default: 0] += item.value
        }
        
        return InventoryReport(
            date: Date(),
            totalItems: totalItems,
            totalValue: totalValue,
            lowStockItemsCount: lowStockItems.count,
            outOfStockItemsCount: outOfStockItems.count,
            categoryValues: categoryValues,
            items: items
        )
    }
}

// MARK: - Supporting Types
struct InventoryReport {
    let date: Date
    let totalItems: Int
    let totalValue: Double
    let lowStockItemsCount: Int
    let outOfStockItemsCount: Int
    let categoryValues: [InventoryCategory: Double]
    let items: [InventoryItem]
    
    var stockHealth: Double {
        let inStockItems = totalItems - outOfStockItemsCount
        return Double(inStockItems) / Double(totalItems)
    }
    
    var lowStockPercentage: Double {
        Double(lowStockItemsCount) / Double(totalItems)
    }
    
    var categoryDistribution: [(InventoryCategory, Double)] {
        categoryValues.map { ($0.key, $0.value) }
            .sorted { $0.1 > $1.1 }
    }
}

// MARK: - Supporting Types
//struct StockMovement {
//    let itemId: String
//    let quantity: Int
//    let type: StockMovementType
//    let note: String?
//    let timestamp: Date
//}

//enum StockMovementType: String {
//    case incoming
//    case outgoing
//}
//
//struct InventoryItem: Codable, Identifiable {
//    var id: String
//    let name: String
//    let category: InventoryCategory
//    var quantity: Int
//    let unit: String
//    let unitPrice: Double
//    let minimumQuantity: Int
//    let supplier: String?
//    let location: String?
//    let notes: String?
//    let lastRestockDate: Date?
//    let createdAt: Date
//    let updatedAt: Date
//    
//    var value: Double {
//        Double(quantity) * unitPrice
//    }
//    
//    var isLowStock: Bool {
//        quantity <= minimumQuantity
//    }
//} 
