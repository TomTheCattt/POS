//
//  AuthenticationView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI

struct AuthenticationView: View { 
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: AuthenticationViewModel
    
    @FocusState private var focusField: AppTextField?
    @Environment(\.colorScheme) private var colorScheme
    
    init(viewModel: AuthenticationViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if isIphone {
                    iPhoneLayout(geometry: geometry)
                } else {
                    iPadLayout(geometry: geometry)
                }
            }
            .background(appState.currentTabThemeColors.softGradient(for: colorScheme))
        }
    }
    
    // MARK: - iPhone Layout
    private func iPhoneLayout(geometry: GeometryProxy) -> some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(spacing: 24) {
                    // Logo Section
                    logoSection
                        .padding(.top, 40)
                    
                    // Authentication Section
                    VStack(spacing: 20) {
                        ZStack {
                            if viewModel.showSignInSection {
                                signInSection()
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                            } else {
                                signUpSection()
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: viewModel.showSignInSection)
                    }
                    .padding(.horizontal)
                }
                .frame(minHeight: geometry.size.height)
            }
            .onAppear {
                viewModel.setScrollProxy(proxy)
            }
            .onChange(of: focusField) { newValue in
                if let field = newValue {
                    viewModel.setFocusedFieldID(field.id)
                    viewModel.scrollToFocusedField()
                }
            }
        }
    }
    
    // MARK: - iPad Layout
    private func iPadLayout(geometry: GeometryProxy) -> some View {
        HStack(spacing: 40) {
            // Left side - Logo
            VStack(spacing: 24) {
                logoSection
                //Spacer()
            }
            .frame(width: geometry.size.width * 0.4)
            .padding(.leading, 40)
            
            // Right side - Authentication
            ScrollViewReader { proxy in
                ScrollView {
                    VStack(spacing: 20) {
                        ZStack {
                            if viewModel.showSignInSection {
                                signInSection()
                                    .transition(.move(edge: .leading).combined(with: .opacity))
                            } else {
                                signUpSection()
                                    .transition(.move(edge: .trailing).combined(with: .opacity))
                            }
                        }
                        .animation(.easeInOut(duration: 0.3), value: viewModel.showSignInSection)
                    }
                    .frame(minHeight: geometry.size.height)
                }
                .onAppear {
                    viewModel.setScrollProxy(proxy)
                }
                .onChange(of: focusField) { newValue in
                    if let field = newValue {
                        viewModel.setFocusedFieldID(field.id)
                        viewModel.scrollToFocusedField()
                    }
                }
            }
            .frame(width: geometry.size.width * 0.5)
        }
        .padding(.vertical, 40)
    }
    
    // MARK: - Logo Section
    private var logoSection: some View {
        VStack(spacing: 16) {
            // Demo Logo
            ZStack {
                Circle()
                    .fill(
                        appState.currentTabThemeColors.gradient(for: colorScheme)
                    )
                    .frame(width: 100, height: 100)
//                    .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
                
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.white)
            }
            
            // Commented Real Logo Implementation
            /*
            Image("app_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .shadow(color: .blue.opacity(0.3), radius: 10, x: 0, y: 5)
            */
            
            Text("Barista POS")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("Quản lý bán hàng")
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Sign In Section
    private func signInSection() -> some View {
        VStack(spacing: 20) {
            // Email
            ShakeTextField(
                title: "Email",
                placeholder: AppLocalizedString.emailPlaceholder,
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                borderColor: viewModel.emailBorderColor,
                focusField: $focusField,
                field: .signInSection(.email),
                shakeAnimation: viewModel.shakeBinding
            )
            
            // Password
            VStack(spacing: 8) {
                ShakeTextField(
                    title: "Mật khẩu",
                    placeholder: AppLocalizedString.passwordPlaceholder,
                    text: $viewModel.password,
                    textContentType: .password,
                    borderColor: viewModel.passwordBorderColor,
                    isSecure: true,
                    submitLabel: .done,
                    focusField: $focusField,
                    field: .signInSection(.password),
                    shakeAnimation: viewModel.shakeBinding
                )
                
                // Forgot Password
                HStack {
                    Spacer()
                    Button {
                        viewModel.handleForgotPassword()
                    } label: {
                        Text(AppLocalizedString.forgotPassword)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
            }
            
            // Login Button
            
            VStack {
                Text(AppLocalizedString.login)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
                        focusField = nil
                        viewModel.handleSubmit()
                    }
            }
            .tint(.white)
            .padding(.top, 8)
            
            // Sign Up
            HStack {
                Text(AppLocalizedString.dontHaveAnAccount)
                    .foregroundColor(.secondary)
                Button {
                    viewModel.toggleSignInSection()
                } label: {
                    Text(AppLocalizedString.signUp)
                        .fontWeight(.semibold)
                        .foregroundColor(appState.currentTabThemeColors.textColor(for: colorScheme))
                }
            }
            .font(.system(size: 14))
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.systemBackground))
//                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
    }
    
    // MARK: - Sign Up Section
    private func signUpSection() -> some View {
        VStack(spacing: 20) {
            // Display Name
            ShakeTextField(
                title: "Tên hiển thị",
                placeholder: AppLocalizedString.displayNamePlaceholder,
                text: $viewModel.displayName,
                borderColor: viewModel.displayNameBorderColor,
                focusField: $focusField,
                field: .signUpSection(.userName),
                shakeAnimation: viewModel.shakeBinding
            )
            
            // Email
            ShakeTextField(
                title: "Email",
                placeholder: AppLocalizedString.emailPlaceholder,
                text: $viewModel.email,
                keyboardType: .emailAddress,
                textContentType: .emailAddress,
                borderColor: viewModel.emailBorderColor,
                focusField: $focusField,
                field: .signUpSection(.email),
                shakeAnimation: viewModel.shakeBinding
            )
            
            // Owner Password
            ShakeTextField(
                title: "Mật khẩu chủ cửa hàng",
                placeholder: "Shop Owner Password",
                text: $viewModel.ownerPassword,
                textContentType: .password,
                borderColor: viewModel.ownerPasswordBorderColor,
                isSecure: true,
                focusField: $focusField,
                field: .signUpSection(.ownerPassword),
                shakeAnimation: viewModel.shakeBinding
            )
            
            // Password
            ShakeTextField(
                title: "Mật khẩu",
                placeholder: AppLocalizedString.passwordPlaceholder,
                text: $viewModel.password,
                textContentType: .password,
                borderColor: viewModel.passwordBorderColor,
                isSecure: true,
                focusField: $focusField,
                field: .signUpSection(.password),
                shakeAnimation: viewModel.shakeBinding
            )
            
            // Re-Enter Password
            ShakeTextField(
                title: "Nhập lại mật khẩu",
                placeholder: AppLocalizedString.reEnterPasswordPlaceholder,
                text: $viewModel.rePassword,
                textContentType: .password,
                borderColor: viewModel.rePasswordBorderColor,
                isSecure: true,
                submitLabel: .done,
                focusField: $focusField,
                field: .signUpSection(.rePassword),
                shakeAnimation: viewModel.shakeBinding
            )
            
            VStack {
                Text(AppLocalizedString.signUp)
                    .font(.system(size: 16, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding()
                    .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
                        focusField = nil
                        viewModel.handleSubmit()
                    }
            }
            .tint(.white)
            .padding(.top, 8)
            
            // Login
            HStack {
                Text(AppLocalizedString.alreadyHaveAnAccount)
                    .foregroundColor(.secondary)
                Button {
                    viewModel.toggleSignInSection()
                } label: {
                    Text(AppLocalizedString.login)
                        .fontWeight(.semibold)
                        .foregroundColor(appState.currentTabThemeColors.textColor(for: colorScheme))
                }
            }
            .font(.system(size: 14))
        }
        .padding(24)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
    }
}


