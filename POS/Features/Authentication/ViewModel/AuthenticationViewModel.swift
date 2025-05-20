//
//  AuthenticationViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI
import Combine
import FirebaseAuth

final class AuthenticationViewModel: BaseViewModel {
    // MARK: - Dependencies
    let environment: AppEnvironment
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var currentSection: AuthenticationSection = .login
    @Published var email = ""
    @Published var displayName = ""
    @Published var shopName = ""
    @Published var password = ""
    @Published var rePassword = ""
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var showError = false
    @Published var verifyEmailSent = false
    @Published var forgotPassword = false
    @Published var loginSectionShowed = true
    
    private let authService: AuthService
    private let crashlytics: CrashlyticsService
    
    // MARK: - Initialization
    init(environment: AppEnvironment) {
        self.environment = environment
        self.authService = environment.authService
        self.crashlytics = environment.crashlyticsService
        
        authService.$authState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                if case .unauthenticated = state {
                    self?.clearFields()
                }
            }
            .store(in: &cancellables)
    }
    
    @MainActor
    func login() async {
        do {
            showLoading(true)
            
            // Validate input
            try validateLoginInput()
            
            try await checkEmailVerification()
            
            // Attempt login
            _ = try await authService.login(email: email, password: password)
            showLoading(false)
            
        } catch let error as AppError {
            handleError(error)
            showLoading(false)
        } catch {
            handleError(AppError.unknown)
            showLoading(false)
        }
        
    }
    
    @MainActor
    func register() async throws {
        do {
            showLoading(true)
            
            // Validate input
            try validateRegisterInput()
            
            // Attempt registration
            try await authService.registerAccount(
                email: email,
                password: password,
                displayName: displayName,
                shopName: shopName
            )
            
            clearFields()
            verifyEmailSent = true
            showLoading(false)
            loginSectionShowed = true
            
        } catch let error as AppError {
            handleError(error)
            showLoading(false)
            throw error
        } catch {
            let appError = AppError.unknown
            handleError(appError)
            showLoading(false)
            throw appError
        }
        
    }
    
    func checkEmailVerification() async throws {
        do {
            showLoading(true)
            try await authService.checkEmailVerification()
            showLoading(false)
        } catch {
            handleError(AppError.auth(.unverifiedEmail))
            showLoading(false)
            throw error
        }
    }
    
    private func validateLoginInput() throws {
        if email.isEmpty {
            throw AppError.validation(.emptyField(field: "email"))
        }
        if password.isEmpty {
            throw AppError.validation(.emptyField(field: "password"))
        }
        if !isValidEmail(email) {
            throw AppError.validation(.invalidFormat(field: "email", message: ""))
        }
    }
    
    private func validateRegisterInput() throws {
        if displayName.isEmpty {
            throw AppError.validation(.emptyField(field: "display name"))
        }
        if shopName.isEmpty {
            throw AppError.validation(.emptyField(field: "shop name"))
        }
        if email.isEmpty {
            throw AppError.validation(.emptyField(field: "email"))
        }
        if password.isEmpty {
            throw AppError.validation(.emptyField(field: "password"))
        }
        if rePassword.isEmpty {
            throw AppError.validation(.emptyField(field: "re-enter password"))
        }
        if !isValidEmail(email) {
            throw AppError.validation(.invalidFormat(field: "email", message: ""))
        }
        if password != rePassword {
            throw AppError.validation(.passwordMismatch)
        }
        if !isValidPassword(password) {
            throw AppError.validation(.passwordTooWeak)
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // Ít nhất 8 ký tự, bao gồm chữ hoa, chữ thường và số
        let passwordRegEx = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{8,}$"
        let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }
    
    private func clearFields() {
        email = ""
        password = ""
        rePassword = ""
        displayName = ""
        shopName = ""
        errorMessage = nil
        showError = false
    }
}

enum AuthenticationSection {
    case login
    case signUp
}
