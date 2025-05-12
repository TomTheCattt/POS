//
//  AuthenticationView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI

struct AuthenticationView: View {
    
    @State private var reEnterPassword: String = ""
    @State private var login: Bool = true
    @State private var showPopUp: Bool = false
    @State private var errorMessage: String = ""
    
    @ObservedObject var viewModel: AuthenticationViewModel
    @ObservedObject var coordinator: AppCoordinator
    
    private let dependencies = AppDependencyContainer()
    
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
                    
                    // Authentication
                    ZStack {
                        if login {
                            LoginSectionView(showPopUp: $showPopUp, errorMessage: $errorMessage, login: $login, viewModel: viewModel, onLoginTapped: {
                                self.viewModel.login()
                            }, onForgotPasswordTapped: {
                                self.coordinator.navigateTo(.forgotPassword, using: .overlay)
                            })
                                .transition(.move(edge: .leading).combined(with: .opacity))
                        } else {
                            SignUpSectionView(showPopUp: $showPopUp, errorMessage: $errorMessage, login: $login, viewModel: viewModel, onSignUpTapped: {
                                self.viewModel.register { result in
                                    switch result {
                                    case .success:
                                        self.coordinator.navigateTo(.verifyEmailSent, using: .fullScreenCover)
                                        self.login = true
                                        self.viewModel.email = ""
                                        self.viewModel.shopName = ""
                                        self.viewModel.displayName = ""
                                        self.viewModel.password = ""
                                        self.viewModel.rePassword = ""
                                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                            self.coordinator.dismissCover()
                                        }
                                    case .failure(let error):
                                        errorMessage = error.localizedDescription
                                        showPopUp = true
                                    }
                                }
                            })
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                    }
                    .animation(.easeInOut, value: login)
                }
                .frame(maxWidth: UIDevice.current.is_iPhone ? geometry.size.width : geometry.size.width / 1.5)
                .position(x: geometry.frame(in: .local).midX, y: geometry.frame(in: .local).midY)
            }
            
            if showPopUp {
                VStack {
                    Spacer().frame(height: 60)
                    Text(errorMessage)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
                        .shadow(radius: 10)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                                withAnimation {
                                    showPopUp = false
                                }
                            }
                        }
                    Spacer()
                }
                .transition(.opacity)
                .animation(.easeInOut, value: showPopUp)
            }
        }
    }
}
