//
//  AuthenticationViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

final class AuthenticationViewModel: ObservableObject {
    
    private let source: SourceModel
    
    // MARK: - Published Properties
    var email = ""
    var displayName = ""
    var shopName = ""
    var ownerPassword = ""
    var password = ""
    var rePassword = ""
    @Published var currentSection: AuthenticationSection = .login
    @Published var verifyEmailSent = false
    @Published var forgotPassword = false
    @Published var loginSectionShowed = true
    
    init(source: SourceModel) {
        self.source = source
    }
    
    // MARK: - Authentication Methods
    func login() async throws {
        do {
            try validateLoginInput()
            try await source.withLoading("Đang đăng nhập...") {
                try await source.environment.authService.login(email: email, password: password)
            }
        } catch {
            await source.handleError(error, action: "đăng nhập")
        }
    }
    
    func register() async throws {
        do {
            try validateRegisterInput()
            try await source.withLoading("Đang đăng ký...") {
                let authResult = try await source.environment.authService.registerAccount(email: email, password: password)
                
                let newUser = AppUser(uid: authResult.uid, email: email, displayName: displayName, photoURL: nil, ownerPassword: ownerPassword, createdAt: Date(), updatedAt: Date())
                let userId = try await source.environment.databaseService.createUser(newUser)
                
                
                let shop = Shop(shopName: shopName,createdAt: Date(),updatedAt: Date())
                let _ = try await source.environment.databaseService.createShop(shop, userId: userId)
                
            }
            verifyEmailSent = true
            clearFields()
            loginSectionShowed = true
        } catch {
            await source.handleError(error, action: "đăng ký")
        }
    }
    
    func resetPassword() async {
        do {
            try await source.withLoading("Đang gửi email...") {
                try await source.environment.authService.resetPassword(email: email)
            }
            await source.showSuccess("Email đặt lại mật khẩu đã được gửi")
            forgotPassword = true
        } catch {
            await source.handleError(error, action: "đặt lại mật khẩu")
        }
    }
    
    // MARK: - Validation Methods
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
        if ownerPassword.isEmpty {
            throw AppError.validation(.emptyField(field: "owner password"))
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
    
    // MARK: - Helper Methods
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
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
        ownerPassword = ""
    }
}

enum AuthenticationSection {
    case login
    case signUp
}
