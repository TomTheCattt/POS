import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class BaseService: BaseServiceProtocol {
    // MARK: - Published Properties
    @Published private(set) var currentUser: AppUser?
    @Published private(set) var selectedShop: Shop?
    @Published private(set) var isLoading = false
    @Published private(set) var error: Error?
    @Published private(set) var authState: AuthState = .unauthenticated
    
    // MARK: - Collections
    @Published private(set) var menuItems: [MenuItem]?
    @Published private(set) var inventoryItems: [InventoryItem]?
    @Published private(set) var orders: [Order]?
    
    // MARK: - Private Properties
    let db = Firestore.firestore()
    private var cancellables = Set<AnyCancellable>()
    private var listeners: [ListenerRegistration] = []
    
    // MARK: - Initialization
    init() {
        setupAuthStateListener()
    }
    
    // MARK: - Auth Methods
    private func setupAuthStateListener() {
        Task { @MainActor in
            self.authState = .loading
        }
        
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            guard let self = self else { return }
            
            if let user = user {
                Task {
                    await MainActor.run {
                        self.authState = .loading
                    }
                    
                    try? await user.reload()
                    
                    if user.isEmailVerified {
                        do {
                            await self.fetchUserData(userId: user.uid)
                            await MainActor.run {
                                self.authState = .authenticated
                            }
                        }
                    } else {
                        await MainActor.run {
                            self.authState = .emailNotVerified
                        }
                    }
                }
            } else {
                Task { @MainActor in
                    self.clearAllData()
                    self.authState = .unauthenticated
                }
            }
        }
    }
    
    private func fetchUserData(userId: String) async {
        do {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            
            guard let userData = try? userDoc.data(as: AppUser.self) else {
                throw AppError.auth(.userNotFound)
            }
            
            await MainActor.run {
                self.currentUser = userData
            }
            
            try await fetchUserShops(userId: userId)
            
        } catch {
            await MainActor.run {
                self.error = error
            }
        }
    }
    
    // MARK: - Shop Methods
    private func fetchUserShops(userId: String) async throws {
        let snapshot = try await db.collection("users").document(userId).collection("shops").getDocuments()
        
        let shops = snapshot.documents.compactMap { document -> Shop? in
            return try? document.data(as: Shop.self)
        }
        
        if let firstShop = shops.first {
            await MainActor.run {
                do {
                    try? self.selectShop(firstShop)
                }
            }
        }
    }
    
    func selectShop(_ shop: Shop) throws {
        guard let shopId = shop.id else {
            throw AppError.shop(.notFound)
        }
        selectedShop = shop
        setupShopListeners(shopId: shopId)
    }
    
    // MARK: - Listeners
    private func setupShopListeners(shopId: String) {
        removeAllListeners()
        
        guard let userId = currentUser?.id else {
            return
        }
        
        let menuListener = db.collection("users").document(userId).collection("shops").document(shopId).collection("menuItems")
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    self.error = error
                    return
                }
                
                self.menuItems = snapshot?.documents.compactMap { try? $0.data(as: MenuItem.self) } ?? []
            }
        
        let inventoryListener = db.collection("users").document(userId).collection("shops").document(shopId).collection("inventoryItems")
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    self.error = error
                    return
                }
                
                self.inventoryItems = snapshot?.documents.compactMap { try? $0.data(as: InventoryItem.self) } ?? []
            }
        
        // Orders Listener
        let ordersListener = db.collection("users").document(userId).collection("shops").document(shopId).collection("orders")
            .addSnapshotListener { [weak self] (snapshot, error) in
                guard let self = self else { return }
                if let error = error {
                    self.error = error
                    return
                }
                
                self.orders = snapshot?.documents.compactMap { try? $0.data(as: Order.self) } ?? []
            }
        
        listeners.append(contentsOf: [menuListener, inventoryListener, ordersListener])
    }
    
    private func removeAllListeners() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    private func clearAllData() {
        currentUser = nil
        selectedShop = nil
        menuItems = nil
        inventoryItems = nil
        orders = nil
        removeAllListeners()
    }
    
    // MARK: - Deinit
    deinit {
        removeAllListeners()
    }
}
