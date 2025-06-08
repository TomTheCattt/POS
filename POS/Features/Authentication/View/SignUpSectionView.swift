//
//  SignUpSectionView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import SwiftUI

struct SignUpSectionView: View {
    
    enum SignUpField {
        case email, displayName, ownerPassword, password, rePassword
    }
    
    @State private var isSignUpPressed = false
    @State private var shakeAnimation = false
    @FocusState private var focusedField: SignUpField?
    
    @ObservedObject var viewModel: AuthenticationViewModel
    
    func borderColor(for text: String) -> Color {
        if isSignUpPressed && text.isEmpty {
            return .red
        } else {
            return .gray
        }
    }
    
//    func shakeEffect() -> Animation {
//        shakeAnimation ? Animation.default.repeatCount(3, autoreverses: true) : .default
//    }
    
    func handleSignUp() {
        isSignUpPressed = true
        
        guard !viewModel.email.isEmpty else {
            shakeAnimation = true
            return
        }
        guard !viewModel.displayName.isEmpty else {
            shakeAnimation = true
            return
        }
        guard !viewModel.password.isEmpty else {
            shakeAnimation = true
            return
        }
        guard !viewModel.rePassword.isEmpty else {
            shakeAnimation = true
            return
        }
        guard viewModel.password == viewModel.rePassword else {
            shakeAnimation = true
            return
        }
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            shakeAnimation = false
        }
        Task {
            try await self.viewModel.register()
        }
    }
    
    var body: some View {
        VStack {
            // Display Name
            TextField(AppLocalizedString.displayNamePlaceholder, text: $viewModel.displayName)
                .keyboardType(.default)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(lineWidth: 2)
                      .foregroundColor(borderColor(for: viewModel.displayName))
                  )
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)
                .modifier(ShakeEffect(shake: $shakeAnimation))
                .focused($focusedField, equals: .displayName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            // Email
            TextField(AppLocalizedString.emailPlaceholder, text: $viewModel.email)
                .keyboardType(.default)
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
                .focused($focusedField, equals: .email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            // Owner Password
            SecureField("Shop Owner Password", text: $viewModel.ownerPassword)
                .keyboardType(.default)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(lineWidth: 2)
                      .foregroundColor(borderColor(for: viewModel.ownerPassword))
                  )
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)
                .modifier(ShakeEffect(shake: $shakeAnimation))
                .focused($focusedField, equals: .ownerPassword)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            // Password
            SecureField(AppLocalizedString.passwordPlaceholder, text: $viewModel.password)
                .keyboardType(.default)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(lineWidth: 2)
                      .foregroundColor(borderColor(for: viewModel.password))
                  )
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)
                .modifier(ShakeEffect(shake: $shakeAnimation))
                .focused($focusedField, equals: .password)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            // Re-Enter Password
            SecureField(AppLocalizedString.reEnterPasswordPlaceholder, text: $viewModel.rePassword)
                .keyboardType(.default)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(lineWidth: 2)
                      .foregroundColor(borderColor(for: viewModel.rePassword))
                  )
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)
                .modifier(ShakeEffect(shake: $shakeAnimation))
                .focused($focusedField, equals: .rePassword)
                .submitLabel(.done)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            // Sign Up
            Button {
                focusedField = nil
                handleSignUp()
            } label: {
                Text(AppLocalizedString.signUp)
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
            // Login
            HStack {
                Text(AppLocalizedString.alreadyHaveAnAccount)
                Button {
                    viewModel.loginSectionShowed = true
                } label: {
                    Text(AppLocalizedString.login)
                        .fontWeight(.bold)
                }
            }
            .padding(.leading)
            .padding(.trailing)
        }
        .onSubmit {
            switch focusedField {
            case .displayName:
                focusedField = .email
            case .email:
                focusedField = .ownerPassword
            case .ownerPassword:
                focusedField = .password
            case .password:
                focusedField = .rePassword
            case .rePassword:
                focusedField = nil
                handleSignUp()
            default:
                break
            }
        }
        .onAppear {
            viewModel.email = ""
            viewModel.ownerPassword = ""
            viewModel.password = ""
            viewModel.rePassword = ""
            viewModel.displayName = ""
        }
    }
}
