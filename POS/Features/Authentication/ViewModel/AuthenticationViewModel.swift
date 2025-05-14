//
//  AuthenticationViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI
import Combine
import FirebaseAuth

final class AuthenticationViewModel: ObservableObject {
    
    private let authService: AuthServiceProtocol
    private let crashlytics: CrashlyticsServiceProtocol
    @ObservedObject private var authManager: AuthManager
    
    @Published var email = ""
    @Published var displayName = ""
    @Published var shopName = ""
    @Published var password = ""
    @Published var rePassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    init(authService: AuthServiceProtocol = AuthService(),
         authManager: AuthManager, crashlytics: CrashlyticsServiceProtocol = CrashlyticsService()) {
        self.authService = authService
        self.authManager = authManager
        self.crashlytics = crashlytics
    }
    
    func login() {
        isLoading = true
        errorMessage = nil
        
        authService.login(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let uid):
                    self.authManager.saveUID(uid)
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func register(completion: @escaping (Result<Void, AppError>) -> Void) {
        authService.registerAccount(email: email, password: password, displayName: displayName, shopName: shopName) { result in
            switch result {
            case .success:
                completion(.success(()))
            case .failure(let error):
                self.crashlytics.log("Register failed for \(self.email)")
                self.crashlytics.record(error: error)
                completion(.failure(error))
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
                self.crashlytics.log("Failed to reload user during email verification check: \(self.email)")
                self.crashlytics.record(error: error)
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

}
