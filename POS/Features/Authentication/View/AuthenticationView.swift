//
//  AuthenticationView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI

struct AuthenticationView: View {
    private let strings = AppLocalizedString()
    
    @State private var login: Bool = true
    
    @ObservedObject var viewModel: AuthenticationViewModel
    @ObservedObject var coordinator: AppCoordinator
    
    var body: some View {
        ZStack {
            Color.white.edgesIgnoringSafeArea(.all)
            
            Color.clear
                .contentShape(Rectangle())
                .onTapGesture {
                    dismissKeyboard()
                }
            
            GeometryReader { geometry in
                VStack {
                    // Logo
                    Image("app_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .padding(.top, 40)
                    
                    // Authentication
                    ZStack {
                        if login {
                            LoginSectionView(
                                login: $login, 
                                viewModel: viewModel
                            ) {
                                Task {
                                    await self.viewModel.login()
                                }
                            } onForgotPasswordTapped: {
                                self.coordinator.navigateTo(.forgotPassword, using: .overlay, with: .overlay)
                            }
                            .transition(.move(edge: .leading).combined(with: .opacity))
                        } else {
                            SignUpSectionView(
                                login: $login, 
                                viewModel: viewModel
                            ) {
                                Task {
                                    try await self.viewModel.register()
                                }
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: login)
                }
                .frame(maxWidth: UIDevice.current.is_iPhone ? geometry.size.width : geometry.size.width / 1.5)
                .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
            }
            
            // Loading View
            if viewModel.isLoading {
                LoadingView(message: "Đang xử lý...")
                    .transition(.opacity)
            }
            
            // Error Message Overlay
            if viewModel.showError {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(viewModel.errorMessage ?? "")
                            .foregroundColor(.black)
                            .font(.system(size: 16, weight: .medium))
                    }
                    .overlayStyle(
                        config: NavigationConfig(
                            isAnimated: true,
                            autoDismiss: true,
                            autoDismissDelay: 3.0,
                            dismissOnTapOutside: true,
                            backgroundEffect: .none,
                            overlaySize: .small,
                            overlayAlignment: .bottom,
                            overlayPadding: 16,
                            customAnimation: .spring()
                        )
                    )
                    .padding(.horizontal, 20)
                    .padding(.bottom, 32)
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                            withAnimation(.spring()) {
                                viewModel.showError = false
                            }
                        }
                    }
                }
                .animation(.spring(), value: viewModel.showError)
                .zIndex(1)
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


