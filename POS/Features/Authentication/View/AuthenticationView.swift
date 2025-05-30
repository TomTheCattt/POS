//
//  AuthenticationView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI

struct AuthenticationView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: AuthenticationViewModel
    
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
                        if viewModel.loginSectionShowed {
                            LoginSectionView(login: $viewModel.loginSectionShowed, viewModel: viewModel)
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        } else {
                            SignUpSectionView(login: $viewModel.loginSectionShowed, viewModel: viewModel)
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut(duration: 0.3), value: viewModel.loginSectionShowed)
                }
                .frame(maxWidth: UIDevice.current.is_iPhone ? geometry.size.width : geometry.size.width / 1.5)
                .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
            }
            
            // Loading View
            if appState.sourceModel.isLoading {
                LoadingView(message: appState.sourceModel.loadingText)
                    .transition(.opacity)
                    .animation(.spring(), value: appState.sourceModel.isLoading)
            }
            
            // Toast Message
            if appState.sourceModel.showToast, let toast = appState.sourceModel.toastMessage {
                ToastView(type: toast.type, message: toast.message)
            }
            
            // Forgot Password Toast
            if viewModel.forgotPassword {
                ToastView(type: .info, message: AppLocalizedString.forgotPasswordContent)
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            withAnimation(.spring()) {
                                viewModel.forgotPassword = false
                            }
                        }
                    }
            }
            
            // Verify Email Toast
            if viewModel.verifyEmailSent {
                ToastView(type: .success, message: AppLocalizedString.verifyEmailSentContent)
                    .onAppear {
                        Task {
                            try? await Task.sleep(nanoseconds: 3_000_000_000)
                            withAnimation(.spring()) {
                                viewModel.verifyEmailSent = false
                            }
                        }
                    }
            }
        }
    }
    
    private func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}


