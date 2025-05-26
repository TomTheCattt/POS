//
//  LoginSectionView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import SwiftUI

struct LoginSectionView: View {
    
    enum LoginField {
        case userName, password
    }
    
    private let strings = AppLocalizedString()
    private let validationStrings = ValidationLocalizedString()
    
    @Binding var login: Bool
    
    @State private var isLoginPressed = false
    @State private var shakeAnimation = false
    @FocusState private var focusedField: LoginField?
    
    @ObservedObject var viewModel: AuthenticationViewModel
    
    func borderColor(for text: String) -> Color {
        if isLoginPressed && text.isEmpty {
            return .red
        } else {
            return .gray
        }
    }
    
    func shakeEffect() -> Animation {
        shakeAnimation ? Animation.default.repeatCount(3, autoreverses: true) : .default
    }
    
    func handleLogin() {
        isLoginPressed = true
        
        guard !viewModel.email.isEmpty else {
            viewModel.showError = true
            viewModel.errorMessage = validationStrings.authErrorEmptyEmail
            shakeAnimation = true
            return
        }
        guard !viewModel.password.isEmpty else {
            viewModel.showError = true
            viewModel.errorMessage = validationStrings.authErrorEmptyPassword
            shakeAnimation = true
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shakeAnimation = false
        }
        Task {
            try await self.viewModel.login()
        }
    }
    
    var body: some View {
        VStack {
            // Email
            TextField(strings.emailPlaceholder, text: $viewModel.email)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(lineWidth: 2)
                        .foregroundColor(borderColor(for: viewModel.email))
                )
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)
                .modifier(ShakeEffect(shake: $shakeAnimation))
                .focused($focusedField, equals: .userName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            
            // Password
            VStack {
                SecureField(strings.passwordPlaceholder, text: $viewModel.password)
                    .padding()
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(lineWidth: 2)
                            .foregroundColor(borderColor(for: viewModel.password))
                    )
                    .modifier(ShakeEffect(shake: $shakeAnimation))
                    .focused($focusedField, equals: .password)
                    .submitLabel(.done)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                // Forgot Password
                HStack {
                    Spacer()
                    Button {
                        // Forgot password action
                        viewModel.forgotPassword = true
                    } label: {
                        Text(strings.forgotPassword)
                            .fontWeight(.bold)
                            .font(.footnote)
                            .italic()
                            .foregroundStyle(Color.gray)
                    }
                }
            }
            .padding(.leading)
            .padding(.trailing)
            .padding(.bottom)
            
            // Login Button
            Button {
                focusedField = nil
                handleLogin()
            } label: {
                Text(strings.login)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(lineWidth: 2)
                            .foregroundColor(.blue)
                    )
                    .font(Font.body.bold())
            }
            .tint(.white)
            .padding(.leading)
            .padding(.trailing)
            .padding(.bottom)
            
            // Sign Up
            HStack {
                Text(strings.dontHaveAnAccount)
                Button {
                    login = false
                } label: {
                    Text(strings.signUp)
                        .fontWeight(.bold)
                }
            }
            .padding(.leading)
            .padding(.trailing)
        }
        .onSubmit {
            switch focusedField {
            case .userName:
                focusedField = .password
            case .password:
                focusedField = nil
                handleLogin()
            default:
                break
            }
        }
        .onAppear {
            viewModel.email = ""
            viewModel.password = ""
            viewModel.rePassword = ""
            viewModel.displayName = ""
            viewModel.shopName = ""
        }
    }
}

