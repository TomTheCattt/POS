import Foundation
import FirebaseFirestore
import Combine

final class InventoryService: BaseService, InventoryServiceProtocol {

    // MARK: - Singleton
    static let shared = InventoryService()
    
    // MARK: - Properties
    private let inventorySubject = CurrentValueSubject<[InventoryItem]?, Never>([])
    
    // MARK: - Published Properties
    var currentInventory: [InventoryItem]? {
        inventorySubject.value
    }
    
    var inventoryItemsPublisher: AnyPublisher<[InventoryItem]?, Never> {
        inventorySubject.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - CRUD Operations
    func createInventoryItem(_ item: InventoryItem) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        let docRef = db.collection("users").document(userId).collection("shops").document(shopId).collection("inventoryItems").document()
        try await docRef.setData(item.dictionary)
    }
    
    func getItem(id: String) async throws -> InventoryItem {
        let doc = try await db.collection("inventory").document(id).getDocument()
        
        guard let item = InventoryItem(document: doc) else {
            throw AppError.database(.documentNotFound)
        }
        
        return item
    }
    
    func updateInventoryItem(_ item: InventoryItem) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        guard let itemId = item.id else {
            throw AppError.inventory(.notFound)
        }
        
        let docRef = db.collection("users").document(userId).collection("shops").document(shopId).collection("inventoryItems").document(itemId)
        try await docRef.setData(item.dictionary, merge: true)
    }
    
    func deleteInventoryItem(_ item: InventoryItem) async throws {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        guard let itemId = item.id else {
            throw AppError.inventory(.notFound)
        }
        
        try await db.collection("users").document(userId).collection("shops").document(shopId).collection("inventoryItems").document(itemId).delete()
    }
    
    func fetchInventoryItems() async throws -> [InventoryItem] {
        guard let userId = currentUser?.id else {
            throw AppError.auth(.userNotFound)
        }
        guard let shopId = selectedShop?.id else {
            throw AppError.shop(.notFound)
        }
        
        let snapshot = try await db.collection("users").document(userId).collection("shops").document(shopId).collection("inventoryItems").getDocuments()
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
        let lowStockItems = items.filter { $0.isLowStock }
        let outOfStockItems = items.filter { $0.quantity <= 0 }
        
        return InventoryReport(
            date: Date(),
            totalItems: totalItems,
            lowStockItemsCount: lowStockItems.count,
            outOfStockItemsCount: outOfStockItems.count,
            items: items
        )
    }
}

// MARK: - Supporting Types
struct InventoryReport {
    let date: Date
    let totalItems: Int
    let lowStockItemsCount: Int
    let outOfStockItemsCount: Int
    let items: [InventoryItem]
    
    var stockHealth: Double {
        let inStockItems = totalItems - outOfStockItemsCount
        return Double(inStockItems) / Double(totalItems)
    }
    
    var lowStockPercentage: Double {
        Double(lowStockItemsCount) / Double(totalItems)
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
