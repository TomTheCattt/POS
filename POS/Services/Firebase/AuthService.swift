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
    case emailNotVerified
    case loading
}

final class AuthService: BaseService, AuthServiceProtocol {
    
    // MARK: - Properties
    static let shared = AuthService()
    
    // Publishers from BaseService
    var currentUserPublisher: AnyPublisher<AppUser?, Never> {
        $currentUser.eraseToAnyPublisher()
    }
    
    var authStatePublisher: AnyPublisher<AuthState, Never> {
        $authState.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    private override init() {
        super.init()
    }
    
    // MARK: - Authentication Methods
    func login(email: String, password: String) async throws -> AppUser {
        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
            
            try await Task.sleep(nanoseconds: 500_000_000)
            
            guard let user = currentUser else {
                throw AppError.auth(.userNotFound)
            }
            
            return user
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    func registerAccount(email: String, password: String, displayName: String, shopName: String) async throws {
        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            
            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = displayName
            try await changeRequest.commitChanges()
            
            let shopId = UUID().uuidString
            
            let user = AppUser(email: email, displayName: displayName, emailVerified: false, photoURL: nil, createdAt: Date(), updatedAt: Date())
            
            let shop = Shop(id: shopId, shopName: shopName, createdAt: Date(), updatedAt: Date())
            
            let userRef = db.collection("users").document(result.user.uid)
            
            try await userRef.setData(user.dictionary)
            
            try await userRef.collection("shops").document(shopId).setData(shop.dictionary)
            
            try await result.user.sendEmailVerification()
            
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    func logout() async throws {
        do {
            try Auth.auth().signOut()
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    func resetPassword(email: String) async throws {
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard let email = Auth.auth().currentUser?.email else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
            
            try await Auth.auth().currentUser?.updatePassword(to: newPassword)
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    func deleteAccount(password: String) async throws {
        guard let email = Auth.auth().currentUser?.email else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: password)
            try await Auth.auth().currentUser?.reauthenticate(with: credential)
            
            if let uid = Auth.auth().currentUser?.uid {
                try await db.collection("users").document(uid).delete()
            }
            
            try await Auth.auth().currentUser?.delete()
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    func updateProfile(displayName: String?, photoURL: URL?) async throws {
        guard let user = Auth.auth().currentUser else {
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
            
            if let displayName = displayName {
                try await db.collection("users").document(user.uid).updateData([
                    "displayName": displayName
                ])
            }
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    func checkEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AppError.auth(.userNotFound)
        }

        do {
            try await user.reload()
            if !user.isEmailVerified {
                throw AppError.auth(.unverifiedEmail)
            }
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    func sendEmailVerification() async throws {
        guard let user = Auth.auth().currentUser else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            try await user.sendEmailVerification()
        } catch {
            throw AppError.auth(.map(error))
        }
    }
}
