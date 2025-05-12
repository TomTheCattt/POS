import Foundation
import FirebaseAuth
import FirebaseDatabase
import FirebaseCrashlytics

final class AuthService: AuthServiceProtocol {
    
    private let auth = Auth.auth()
    private let db = Database.database().reference()
    
    // MARK: - Login
    func login(email: String, password: String, completion: @escaping (Result<String, AppError>) -> Void) {
        auth.signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                let mapped = FirebaseAuthError.map(error)
                Crashlytics.crashlytics().record(error: error)
                completion(.failure(.auth(mapped)))
                return
            }

            guard let user = Auth.auth().currentUser else {
                completion(.failure(.auth(.unknown)))
                return
            }

            user.reload { _ in
                guard user.isEmailVerified else {
                    completion(.failure(.auth(.unverifiedEmail)))
                    return
                }

                user.getIDToken { token, error in
                    if let error = error {
                        Crashlytics.crashlytics().record(error: error)
                        completion(.failure(.auth(.tokenError)))
                        return
                    }

                    if let token = token {
                        // Bạn có thể lưu token vào viewModel hoặc Keychain nếu cần
                        completion(.success(token))
                    } else {
                        completion(.failure(.auth(.tokenError)))
                    }
                }
            }
        }
    }

    
    // MARK: - Current User
    func currentUser() -> SessionUser? {
        guard let user = auth.currentUser else { return nil }
        return SessionUser(id: user.uid, email: user.email)
    }
    
    // MARK: - Register Firebase user + send verification email
    func registerShopAccount(email: String, password: String, shopName: String, completion: @escaping (Result<Void, AppError>) -> Void) {
        auth.createUser(withEmail: email, password: password) { result, error in
            if let error = error {
                let mapped = FirebaseAuthError.map(error)
                Crashlytics.crashlytics().record(error: error)
                completion(.failure(.auth(mapped)))
                return
            }
            
            guard let user = result?.user else {
                completion(.failure(.auth(.unknown)))
                return
            }
            
            let shopID = shopName.lowercased().replacingOccurrences(of: " ", with: "_")
            let createdAt = Date().timeIntervalSince1970
            
            let shopData: [String: Any] = [
                "id": shopID,
                "name": shopName,
                "createdAt": createdAt,
                "ownerUID": user.uid,
                "ownerEmail": user.email ?? ""
            ]
            
            let userData: [String: Any] = [
                "id": user.uid,
                "email": user.email ?? "",
                "shopID": shopID
            ]
            
            let updates: [String: Any] = [
                "shops/\(shopID)": shopData,
                "users/\(user.uid)": userData,
                "userShopMapping/\(user.uid)/shopID": shopID
            ]
            
            self.db.updateChildValues(updates) { error, _ in
                if let error = error {
                    Crashlytics.crashlytics().record(error: error)
                    completion(.failure(.firestore(.unknown)))
                    return
                }
            }
            
            user.sendEmailVerification { error in
                if let error = error {
                    Crashlytics.crashlytics().record(error: error)
                    completion(.failure(.auth(.unknown)))
                    return
                }
                completion(.success(()))
            }
        }
    }
    
    func onEmailVerified(completion: @escaping (Result<Void, AppError>) -> Void) {
        guard let user = Auth.auth().currentUser else {
            completion(.failure(.auth(.unknown)))
            return
        }

        user.reload { error in
            if let error = error {
                Crashlytics.crashlytics().record(error: error)
                completion(.failure(.auth(.unknown)))
                return
            }

            if user.isEmailVerified {
                completion(.success(()))
            } else {
                completion(.failure(.auth(.unverifiedEmail)))
            }
        }
    }

    // MARK: - Hash (nếu cần)
    private func hashString(_ input: String) -> String {
        return String(input.reversed())
    }
}
