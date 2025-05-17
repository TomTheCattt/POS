//
//  SignUpSectionView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import SwiftUI

struct SignUpSectionView: View {
    
    enum SignUpField {
        case shopName, email, displayName, password, rePassword
    }
    
    private let strings = AppLocalizedString()
    private let validationStrings = ValidationLocalizedString()
    
    @Binding var login: Bool
    
    @State private var isSignUpPressed = false
    @State private var shakeAnimation = false
    @FocusState private var focusedField: SignUpField?
    
    @ObservedObject var viewModel: AuthenticationViewModel
    
    var onSignUpTapped: (() -> Void)?
    
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
        
        guard !viewModel.shopName.isEmpty else {
            shakeAnimation = true
            viewModel.showError = true
            viewModel.errorMessage = validationStrings.authErrorEmptyShopName
            return
        }
        
        guard !viewModel.email.isEmpty else {
            shakeAnimation = true
            viewModel.showError = true
            viewModel.errorMessage = validationStrings.authErrorEmptyEmail
            return
        }
        guard !viewModel.displayName.isEmpty else {
            shakeAnimation = true
            viewModel.showError = true
            viewModel.errorMessage = validationStrings.authErrorEmptyDisplayName
            return
        }
        guard !viewModel.password.isEmpty else {
            shakeAnimation = true
            viewModel.showError = true
            viewModel.errorMessage = validationStrings.authErrorEmptyPassword
            return
        }
        guard !viewModel.rePassword.isEmpty else {
            shakeAnimation = true
            viewModel.showError = true
            viewModel.errorMessage = validationStrings.authErrorReEnterPasswordEmpty
            return
        }
        guard viewModel.password == viewModel.rePassword else {
            shakeAnimation = true
            viewModel.showError = true
            viewModel.errorMessage = validationStrings.authErrorValidatePasswordFailed
            return
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            shakeAnimation = false
        }
        onSignUpTapped?()
    }
    
    var body: some View {
        VStack {
            // Shop Name
            TextField(strings.shopNamePlaceholder, text: $viewModel.shopName)
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                      .stroke(lineWidth: 2)
                      .foregroundColor(borderColor(for: viewModel.shopName))
                  )
                .padding(.leading)
                .padding(.trailing)
                .padding(.bottom)
                .modifier(ShakeEffect(shake: $shakeAnimation))
                .focused($focusedField, equals: .shopName)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            // Display Name
            TextField(strings.displayNamePlaceholder, text: $viewModel.displayName)
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
                .focused($focusedField, equals: .email)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
            // Password
            SecureField(strings.passwordPlaceholder, text: $viewModel.password)
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
            SecureField(strings.reEnterPasswordPlaceholder, text: $viewModel.rePassword)
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
                Text(strings.signUp)
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
                Text(strings.alreadyHaveAnAccount)
                Button {
                    login = true
                } label: {
                    Text(strings.login)
                        .fontWeight(.bold)
                }
            }
            .padding(.leading)
            .padding(.trailing)
        }
        .onSubmit {
            switch focusedField {
            case .shopName:
                focusedField = .displayName
            case .displayName:
                focusedField = .email
            case .email:
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
            viewModel.password = ""
            viewModel.rePassword = ""
            viewModel.displayName = ""
            viewModel.shopName = ""
        }
    }
}
