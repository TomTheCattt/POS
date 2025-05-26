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

final class AuthService: AuthServiceProtocol {
    
    // MARK: - Properties
    static let shared = AuthService()
    let auth = Auth.auth()
    
    // MARK: - Authentication Methods
    func login(email: String, password: String) async throws -> FirebaseAuth.User {
        let authResult = try await auth.signIn(withEmail: email, password: password)
        let user = authResult.user
        
        try await user.reload()
        
        if !user.isEmailVerified {
            try auth.signOut()
            throw AppError.auth(.unverifiedEmail)
        }
        
        return user
    }
    
    func registerAccount(email: String, password: String) async throws -> FirebaseAuth.User {
        let authResult = try await auth.createUser(withEmail: email, password: password)
        let user = authResult.user
        
        try await user.sendEmailVerification()
        
        return user
    }
    
    func logout() async throws {
        try auth.signOut()
    }
    
    func resetPassword(email: String) async throws {
        try await auth.sendPasswordReset(withEmail: email)
    }
    
    func updatePassword(currentPassword: String, newPassword: String) async throws {
        guard let email = auth.currentUser?.email else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            let credential = EmailAuthProvider.credential(withEmail: email, password: currentPassword)
            try await auth.currentUser?.reauthenticate(with: credential)
            try await auth.currentUser?.updatePassword(to: newPassword)
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    func deleteAccount(password: String) async throws {
        guard let email = auth.currentUser?.email else {
            throw AppError.auth(.userNotFound)
        }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        do {
            try await auth.currentUser?.reauthenticate(with: credential)
            try await auth.currentUser?.delete()
        } catch {
            throw AppError.auth(.map(error))
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
            
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    func checkEmailVerification() async throws {
        guard let user = auth.currentUser else {
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
        guard let user = auth.currentUser else {
            throw AppError.auth(.userNotFound)
        }
        
        do {
            try await user.sendEmailVerification()
        } catch {
            throw AppError.auth(.map(error))
        }
    }
    
    // MARK: - Helper Methods
    
    /// Kiểm tra trạng thái xác minh email của user hiện tại
    func getCurrentUserVerificationStatus() async throws -> Bool {
        guard let user = auth.currentUser else {
            throw AppError.auth(.userNotFound)
        }
        
        try await user.reload()
        return user.isEmailVerified
    }
    
    /// Gửi lại email xác minh với thời gian chờ
    func resendEmailVerification() async throws {
        guard let user = auth.currentUser else {
            throw AppError.auth(.userNotFound)
        }
        
        // Kiểm tra xem đã gửi email chưa trong thời gian gần đây
        let lastSentKey = "lastEmailVerificationSent_\(user.uid)"
        let lastSentTime = UserDefaults.standard.double(forKey: lastSentKey)
        let currentTime = Date().timeIntervalSince1970
        
        // Chỉ cho phép gửi lại sau 60 giây
        if currentTime - lastSentTime < 60 {
            throw AppError.auth(.tooManyRequests)
        }
        
        try await user.sendEmailVerification()
        UserDefaults.standard.set(currentTime, forKey: lastSentKey)
    }
}
