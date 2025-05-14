import Foundation
import FirebaseAuth
import FirebaseFirestore
import FirebaseCrashlytics

final class AuthService: AuthServiceProtocol {
    
    private let auth = Auth.auth()
    private let firestore = Firestore.firestore()
    
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

                completion(.success(user.uid))
            }
        }
    }
    
    // MARK: - Register account and store in Firestore
    func registerAccount(email: String, password: String, displayName: String, shopName: String, completion: @escaping (Result<Void, AppError>) -> Void) {
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

            let shopID = UUID().uuidString
            let createdAt = Date()

            let shop = Shop(
                id: shopID,
                shopName: shopName,
                createdAt: createdAt,
                menuItems: [],
                inventoryItems: []
            )

            let appUser = AppUser(
                id: user.uid,
                email: email,
                ownerPassword: "",
                displayName: displayName,
                shopOwned: [shop]
            )

            do {
                let userRef = self.firestore.collection("users").document(user.uid)
                let shopRef = self.firestore.collection("shops").document(shopID)

                let batch = self.firestore.batch()
                try batch.setData(from: appUser, forDocument: userRef)
                try batch.setData(from: shop, forDocument: shopRef)

                batch.commit { error in
                    if let error = error {
                        Crashlytics.crashlytics().record(error: error)
                        completion(.failure(.firestore(.unknown)))
                        return
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
            } catch {
                Crashlytics.crashlytics().record(error: error)
                completion(.failure(.firestore(.encodingFailed)))
            }
        }
    }

    // MARK: - Email verification status
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
    
    // MARK: - Optional hashing
    private func hashString(_ input: String) -> String {
        return String(input.reversed())
    }
}
