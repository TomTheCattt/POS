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
    var currentSection: AuthenticationSection = .login
    @Published var email = ""
    @Published var displayName = ""
    @Published var shopName = ""
    @Published var password = ""
    @Published var rePassword = ""
    @Published var showError = false
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
                
                let newUser = AppUser(uid: authResult.uid, email: email, displayName: displayName, photoURL: nil, createdAt: Date(), updatedAt: Date())
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
        showError = false
    }
}

enum AuthenticationSection {
    case login
    case signUp
}





///// Firebase Auth state listener
//private var authStateListener: AuthStateDidChangeListenerHandle?
///// Firestore user document listener
//private var userListener: ListenerRegistration?



//// MARK: - Setup Methods
//private func setupAuthStateListener() {
//    authStateListener = environment.authService.auth.addStateDidChangeListener { [weak self] auth, user in
//        Task { [weak self] in
//            print("DEBUG: [\(#fileID):\(#line)] \(#function) - Auth State Listen to User: \(String(describing: user?.uid ?? "nil"))")
//            print("DEBUG: [\(#fileID):\(#line)] \(#function) - Auth State : \(String(describing: Auth.authStateDidChangeNotification))")
//
//            await self?.handleAuthStateChange(user)
//        }
//    }
//}
//
//// MARK: - Auth State Handling
//private func handleAuthStateChange(_ user: FirebaseAuth.User?) async {
//    if let user = user {
//        do {
//            try await environment.authService.checkEmailVerification()
//            
//            if let userData: AppUser = try await environment.databaseService.getUser(userId: user.uid) {
//                await setupUserListener(userId: userData.id ?? "")
////                    await fetchAndSetupShop()
//            } else {
//                await MainActor.run {
//                    self.currentUserSubject.send(nil)
//                    self.userId = ""
////                        self.selectedShopId = nil
//                }
//            }
//        } catch let error as AppError {
//            if case .auth(.unverifiedEmail) = error {
//                await MainActor.run {
//                    self.currentUserSubject.send(nil)
//                    self.userId = ""
//                }
//            } else {
//                await MainActor.run {
//                    self.currentUserSubject.send(nil)
//                    self.userId = ""
////                        self.selectedShopId = nil
//                }
//            }
//        } catch {
//            await MainActor.run {
//                self.currentUserSubject.send(nil)
//                self.userId = ""
////                    self.selectedShopId = nil
//            }
//        }
//    } else {
//        await MainActor.run {
//            self.currentUserSubject.send(nil)
//            self.userId = ""
////                self.selectedShopId = nil
//        }
//    }
//}
//
//private func fetchStoredUserData() async {
//    do {
//        guard let userId else {
//            await MainActor.run {
//                self.currentUserSubject.send(nil)
//            }
//            return
//        }
//        
//        if let userData: AppUser = try await environment.databaseService.getUser(userId: userId) {
//            await MainActor.run {
//                self.currentUserSubject.send(userData)
//            }
//            //await fetchAndSetupShop()
//        } else {
//            await MainActor.run {
//                self.currentUserSubject.send(nil)
//                self.userId = ""
//            }
//        }
//    } catch {
//        await MainActor.run {
//            self.handleError(error, action: "tải dữ liệu người dùng")
//            self.currentUserSubject.send(nil)
//            self.userId = ""
//        }
//    }
//}
//
//// MARK: - User & Shop Listeners
//private func setupUserListener(userId: String) async {
//    userListener = environment.databaseService.addDocumentListener(
//        collection: .users,
//        type: .collection,
//        id: userId
//    ) { [weak self] (result: Result<AppUser?, Error>) in
//        guard let self = self else { return }
//        
//        switch result {
//        case .success(let user):
//            guard let user = user, let id = user.id else {
//                self.handleError(AppError.auth(.userNotFound))
//                return
//            }
//            self.currentUserSubject.send(user)
//            self.userId = id
//            
////                Task {
////                    await self.fetchAndSetupShop()
////                }
//            
//        case .failure(let error):
//            self.currentUserSubject.send(nil)
//            self.userId = ""
//            self.handleError(error, action: "tải thông tin người dùng")
//        }
//    }
//    
//    if let listener = userListener {
//        addToListeners(listener)
//    }
//}
