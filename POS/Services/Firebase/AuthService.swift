import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCrashlytics
import Combine
import SwiftUI

// MARK: - Supporting Types
enum AuthState {
    case authenticated
    case unauthenticated
    case loading
}

final class AuthService: AuthServiceProtocol, ObservableObject {
    // MARK: - Properties
    static let shared = AuthService()
    
    @Published private(set) var currentUser: AppUser?
    @Published private(set) var authState: AuthState = .unauthenticated
    @AppStorage("userUID") private var userUID: String = ""
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    
    var currentUserPublisher: AnyPublisher<AppUser?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
    
    var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    private init() {
        setupAuthStateListener()
    }
    
    func setupAuthStateListener() {
        print("🔵 Setting up auth state listener")
        self.authState = .loading
        auth.addStateDidChangeListener { [weak self] _, user in
            print("🔵 Auth state changed - User: \(user?.uid ?? "nil")")
            if let user = user {
                print("🔵 User is logged in, fetching user data...")
                // Fetch user data from Firestore
                self?.fetchUserData(uid: user.uid) { result in
                    switch result {
                    case .success(let appUser):
                        print("✅ Successfully fetched user data: \(appUser)")
                        self?.currentUser = appUser
                        self?.authState = .authenticated
                    case .failure(let error):
                        print("❌ Error fetching user data: \(error)")
                        self?.currentUser = nil
                        self?.authState = .unauthenticated
                    }
                }
            } else {
                print("🔵 No user logged in")
                self?.currentUser = nil
                self?.authState = .unauthenticated
            }
        }
    }
    
    // MARK: - Private Methods
    private func fetchUserData(uid: String, completion: @escaping (Result<AppUser, Error>) -> Void) {
        
        firestore.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            
            if let error = error {
                completion(.failure(error))
                return
            }
            
            guard let data = snapshot?.data() else {
                completion(.failure(AppError.database(.documentNotFound)))
                return
            }
            
            do {
                var shops: [Shop] = []
                if let shopsData = data["shopOwned"] as? [[String: Any]] {
                    shops = shopsData.compactMap { shopData in
                        guard let id = shopData["id"] as? String,
                              let name = shopData["shopName"] as? String,
                              let createdAt = (shopData["createdAt"] as? Timestamp)?.dateValue() ?? (shopData["createdAt"] as? Date)
                        else {
                            return nil
                        }
                        
                        return Shop(id: id, shopName: name, createdAt: createdAt)
                    }
                }
                
                let appUser = try AppUser(
                    id: uid,
                    email: data["email"] as? String ?? "",
                    displayName: data["displayName"] as? String ?? "",
                    shopOwned: shops
                )
                
                DispatchQueue.main.async {
                    self?.currentUser = appUser
                    self?.authState = .authenticated
                    completion(.success(appUser))
                }
            } catch {
                completion(.failure(AppError.database(.decodingError)))
            }
        }
    }
    
    // MARK: - Authentication Methods
    func login(email: String, password: String) async throws -> AppUser {
        do {
            let result = try await auth.signIn(withEmail: email, password: password)
            
            // Fetch user data from Firestore
            return try await withCheckedThrowingContinuation { continuation in
                fetchUserData(uid: result.user.uid) { result in
                    switch result {
                    case .success(let user):
                        continuation.resume(returning: user)
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            throw AppError.auth(.invalidCredentials)
        }
    }
    
    func registerAccount(email: String, password: String, displayName: String, shopName: String) async throws {
        do {
            // 1. Tạo tài khoản Firebase Auth
            let result = try await auth.createUser(withEmail: email, password: password)
            
            // 2. Cập nhật displayName
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            // 3. Tạo shop mới
            let shop = Shop(
                id: UUID().uuidString,
                shopName: shopName,
                createdAt: Date()
            )
            
            // 4. Tạo document user trong Firestore
            try await firestore.collection("users").document(result.user.uid).setData([
                "email": email,
                "displayName": displayName,
                "ownerPassword": "",
                "shopOwned": [shop],
                "createdAt": FieldValue.serverTimestamp()
            ])
            
            // 5. Tạo document shop
            try await firestore.collection("shops").document(shop.id).setData([
                "name": shopName,
                "ownerId": result.user.uid,
                "createdAt": FieldValue.serverTimestamp()
            ])
            
            // 6. Gửi email xác thực
            try await result.user.sendEmailVerification()
            
        } catch {
            throw AppError.auth(.registrationFailed)
        }
    }
    
    func logout() async throws {
        do {
            try auth.signOut()
            
            await MainActor.run {
                self.userUID = ""
                self.currentUser = nil
                self.authState = .unauthenticated
            }
            
        } catch {
            throw AppError.auth(.signOutFailed)
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await auth.sendPasswordReset(withEmail: email)
        } catch {
            throw AppError.auth(.resetPasswordFailed)
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard let email = auth.currentUser?.email else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            // Xác thực lại với mật khẩu hiện tại
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await auth.currentUser?.reauthenticate(with: credential)
            
            // Cập nhật mật khẩu mới
            try await auth.currentUser?.updatePassword(to: newPassword)
        } catch {
            throw AppError.auth(.updatePasswordFailed)
        }
    }
    
    func deleteAccount(password: String) async throws {
        guard let email = auth.currentUser?.email else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            // Xác thực lại trước khi xóa
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await auth.currentUser?.reauthenticate(with: credential)
            
            // Xóa dữ liệu user từ Firestore
            if let uid = auth.currentUser?.uid {
                try await firestore.collection("users").document(uid).delete()
            }
            
            // Xóa tài khoản
            try await auth.currentUser?.delete()
        } catch {
            throw AppError.auth(.deleteAccountFailed)
        }
    }
    
    func updateProfile(displayName: String?, photoURL: URL?) async throws {
        guard let user = auth.currentUser else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            let changeRequest = user.createProfileChangeRequest()
            if let displayName = displayName {
                changeRequest.displayName = displayName
            }
            if let photoURL = photoURL {
                changeRequest.photoURL = photoURL
            }
            try await changeRequest.commitChanges()
            
            // Cập nhật thông tin trong Firestore
            if let displayName = displayName {
                try await firestore.collection("users").document(user.uid).updateData([
                    "displayName": displayName
                ])
            }
        } catch {
            throw AppError.auth(.updateProfileFailed)
        }
    }
    
    func checkEmailVerification() async throws {
        try await auth.currentUser?.reload()
        guard let isVerified = auth.currentUser?.isEmailVerified else {
            throw AppError.auth(.userNotFound)
        }
        if !isVerified {
            throw AppError.auth(.emailNotVerified)
        }
    }
    
    func sendEmailVerification() async throws {
        guard let user = auth.currentUser else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            try await user.sendEmailVerification()
        } catch {
            throw AppError.auth(.sendEmailVerificationFailed)
        }
    }
}
