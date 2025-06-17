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

@MainActor
final class AuthenticationViewModel: ObservableObject {
    
    private let source: SourceModel
    
    // MARK: - Form Data
    @Published var email = ""
    @Published var displayName = ""
    @Published var ownerPassword = ""
    @Published var password = ""
    @Published var rePassword = ""
    
    // MARK: - UI State
    @Published private(set) var verifyEmailSent = false
    @Published private(set) var forgotPassword = false
    @Published private(set) var showSignInSection = true
    @Published private(set) var focusState: AppTextField?
    @Published private(set) var shakeAnimation = false
    @Published private(set) var scrollProxy: ScrollViewProxy?
    @Published private(set) var focusedFieldID: String?
    
    // MARK: - Validation State
    @Published private(set) var isDisplayNameValid = false
    @Published private(set) var isEmailValid = false
    @Published private(set) var isPasswordValid = false
    @Published private(set) var isLoginFormValid = false
    @Published private(set) var isRegisterFormValid = false
    
    var shakeBinding: Binding<Bool> {
        Binding(
            get: { self.shakeAnimation },
            set: { _ in }
        )
    }
    // MARK: - Computed Properties
    var emailBorderColor: Color {
        borderColor(for: email, isValid: email.isEmpty || isEmailValid)
    }
    
    var displayNameBorderColor: Color {
        borderColor(for: displayName, isValid: displayName.isEmpty || isDisplayNameValid)
    }
    
    var ownerPasswordBorderColor: Color {
        borderColor(for: ownerPassword, isValid: ownerPassword.isEmpty || isPasswordValid)
    }
    
    var passwordBorderColor: Color {
        borderColor(for: password, isValid: password.isEmpty || isPasswordValid)
    }
    
    var rePasswordBorderColor: Color {
        let isValid = rePassword.isEmpty || password == rePassword
        return borderColor(for: rePassword, isValid: isValid)
    }
    
    init(source: SourceModel) {
        self.source = source
        setupValidation()
    }
    
    // MARK: - Validation Setup
    private func setupValidation() {
        // Display Name validation
        $displayName
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { [weak self] displayName in
                self?.isValidDisplayName(displayName) ?? false
            }
            .assign(to: &$isEmailValid)
        // Email validation
        $email
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { [weak self] email in
                self?.isValidEmail(email) ?? false
            }
            .assign(to: &$isEmailValid)
        
        // Password validation
        $password
            .debounce(for: .milliseconds(300), scheduler: RunLoop.main)
            .map { [weak self] password in
                self?.isValidPassword(password) ?? false
            }
            .assign(to: &$isPasswordValid)
        
        // Login form validation
        Publishers.CombineLatest($email, $password)
            .map { email, password in
                !email.isEmpty && !password.isEmpty
            }
            .assign(to: &$isLoginFormValid)
        
        // Register form validation
        Publishers.CombineLatest4($displayName, $email, $password, $rePassword)
            .combineLatest($ownerPassword, $isEmailValid, $isPasswordValid)
            .map { formData, ownerPassword, isEmailValid, isPasswordValid in
                let (displayName, email, password, rePassword) = formData
                return !displayName.isEmpty &&
                       !email.isEmpty &&
                       !ownerPassword.isEmpty &&
                       !password.isEmpty &&
                       !rePassword.isEmpty &&
                       isEmailValid &&
                       isPasswordValid &&
                       password == rePassword
            }
            .assign(to: &$isRegisterFormValid)
    }
    
    // MARK: - Authentication Methods
    private func login() async {
        guard isLoginFormValid else {
            let missingFields = getMissingFields()
            await handleValidationError(.emptyField(field: missingFields))
            return
        }
        
        do {
            try await source.withLoading("Đang đăng nhập...") {
                try await source.environment.authService.login(email: email, password: password)
            }
        } catch {
            source.handleError(error, action: "đăng nhập")
        }
    }
    
    private func register() async {
        guard isRegisterFormValid else {
            let missingFields = getMissingFields()
            await handleValidationError(.emptyField(field: missingFields))
            return
        }
        
        do {
            try await source.withLoading("Đang đăng ký...") {
                let authResult = try await source.environment.authService.registerAccount(
                    email: email,
                    password: password
                )
                
                let newUser = AppUser(
                    uid: authResult.uid,
                    email: email,
                    displayName: displayName,
                    photoURL: nil,
                    ownerPassword: ownerPassword,
                    createdAt: Date(),
                    updatedAt: Date()
                )
                
                _ = try await source.environment.databaseService.createUser(newUser)
            }
            
            await handleRegistrationSuccess()
        } catch {
            source.handleError(error, action: "đăng ký")
        }
    }
    
    func resetPassword() async {
        guard !email.isEmpty else {
            await handleValidationError(.emptyField(field: "email"))
            return
        }
        
        guard isEmailValid else {
            await handleValidationError(.invalidFormat(field: "email", message: "Email không hợp lệ"))
            return
        }
        
        do {
            try await source.withLoading("Đang gửi email...") {
                try await source.environment.authService.resetPassword(email: email)
            }
            source.showSuccess("Email đặt lại mật khẩu đã được gửi")
        } catch {
            source.handleError(error, action: "đặt lại mật khẩu")
        }
    }
    
    // MARK: - Helper Methods
    private func handleRegistrationSuccess() async {
        source.showSuccess(AppLocalizedString.verifyEmailSentContent)
        clearFields()
        showSignInSection = true
        verifyEmailSent = true
    }
    
    private func handleValidationError(_ error: ValidationError) async {
        triggerShakeAnimation()
        source.handleError(AppError.validation(error), action: "xác thực")
    }
    
    private func getMissingFields() -> String {
        var missing: [String] = []
        
        if showSignInSection {
            if email.isEmpty { missing.append("email") }
            if password.isEmpty { missing.append("mật khẩu") }
        } else {
            if displayName.isEmpty { missing.append("tên hiển thị") }
            if email.isEmpty { missing.append("email") }
            if ownerPassword.isEmpty { missing.append("mật khẩu chủ") }
            if password.isEmpty { missing.append("mật khẩu") }
            if rePassword.isEmpty { missing.append("xác nhận mật khẩu") }
        }
        
        return missing.joined(separator: ", ")
    }
    
    private func isValidDisplayName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Kiểm tra độ dài
        guard !trimmedName.isEmpty else {
            return false
        }
        
        guard trimmedName.count >= 2 else {
            return false
        }
        
        // Kiểm tra ký tự hợp lệ (chữ cái, khoảng trắng, dấu)
        let nameRegex = "^[\\p{L} .'-]+$"
        let predicate = NSPredicate(format:"SELF MATCHES %@", nameRegex)
        
        guard predicate.evaluate(with: trimmedName) else {
            return false
        }
        
        return true // hợp lệ
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let emailPred = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailPred.evaluate(with: email)
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
        let passwordRegEx = "^(?=.*[A-Z])(?=.*[0-9])(?=.*[a-z]).{8,}$"
        let passwordPred = NSPredicate(format:"SELF MATCHES %@", passwordRegEx)
        return passwordPred.evaluate(with: password)
    }
    
    private func clearFields() {
        email = ""
        password = ""
        rePassword = ""
        displayName = ""
        ownerPassword = ""
    }
    
    // MARK: - UI State Methods
    func toggleSignInSection() {
        showSignInSection.toggle()
        clearFields() // Clear fields when switching modes
    }
    
    func setFocusState(_ field: AppTextField?) {
        focusState = field
    }
    
    func setScrollProxy(_ proxy: ScrollViewProxy) {
        scrollProxy = proxy
    }
    
    func setFocusedFieldID(_ id: String?) {
        focusedFieldID = id
    }
    
    func scrollToFocusedField() {
        guard let id = focusedFieldID else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            scrollProxy?.scrollTo(id, anchor: .center)
        }
    }
    
    func triggerShakeAnimation() {
        shakeAnimation = true
        
        Task {
            try? await Task.sleep(nanoseconds: 600_000_000)
            await MainActor.run {
                self.shakeAnimation = false
            }
        }
    }
    
    func borderColor(for text: String, isValid: Bool = true) -> Color {
        if text.isEmpty {
            return .gray.opacity(0.5)
        }
        return isValid ? .blue : .red
    }
    
    // MARK: - Action Methods
    
    func handleForgotPassword() {
        Task {
            await resetPassword()
        }
    }
    
    func handleSubmit() {
        if showSignInSection {
            Task {
                await login()
            }
        } else {
            Task {
                await register()
            }
        }
    }
}
