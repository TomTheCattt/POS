//
//  AuthenticationViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import Combine
import FirebaseAuth

final class AuthenticationViewModel: ObservableObject {
    
    private let authService: AuthServiceProtocol
    private let crashlytics: CrashlyticsServiceProtocol
    private let authManager: AuthManager
    
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
        
        // Thực hiện đăng nhập
        authService.login(email: email, password: password) { [weak self] result in
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
                
                switch result {
                case .success(let token):
                    // Lưu token và cập nhật trạng thái đăng nhập
                    // Khi isAuthenticated trở thành true, fullScreenCover sẽ tự động đóng
                    self.authManager.saveToken(token)
                    
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }
    
    func register(completion: @escaping (Result<Void, AppError>) -> Void) {
        authService.registerShopAccount(email: email, password: password, shopName: shopName) { result in
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
