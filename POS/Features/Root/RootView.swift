//
//  RootView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 7/5/25.
//

import SwiftUI
import FirebaseAuth

struct RootView: View {
    @StateObject private var coordinator = AppCoordinator()
    @StateObject private var authManager = AuthManager()
    private let dependencies = AppDependencyContainer()

    private var factory: ViewFactory {
        ViewFactory(coordinator: coordinator)
    }

    var body: some View {
        ZStack {
            NavigationStack(path: $coordinator.navigationPath) {
                factory.viewForDestination(.home) // Luôn đặt .home làm view gốc
                    .navigationBarBackButtonHidden(!coordinator.navigationConfig.showBackButton)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            if coordinator.navigationPath.count > 0 && coordinator.navigationConfig.showBackButton {
                                Button {
                                    coordinator.navigateBack()
                                } label: {
                                    HStack(spacing: 3) {
                                        Image(systemName: "chevron.left")
                                        Text("Back")
                                    }
                                }
                            }
                        }
                    }
                    .navigationDestination(for: AppDestination.self) { destination in
                        factory.viewForDestination(destination)
                    }
            }
            .sheet(isPresented: $coordinator.isSheetPresented) {
                if let destination = coordinator.activeSheet {
                    factory.viewForDestination(destination)
                }
            }
            .fullScreenCover(isPresented: .constant(!authManager.isAuthenticated)) {
                factory.viewForDestination(.authentication)
            }
            .overlay(
                ZStack {
                    if coordinator.isOverlayPresented {
                        Color.black.opacity(0.4)
                            .edgesIgnoringSafeArea(.all)
                            .transition(.opacity)
                            .onTapGesture {
                                coordinator.dismissOverlay()
                            }
                    }

                    if let destination = coordinator.activeOverlay {
                        factory.viewForDestination(destination)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white)
                                    .shadow(radius: 10)
                            )
                            .transition(.scale)
                            .zIndex(1)
                    }
                }
            )
            .animation(.easeInOut(duration: 0.3), value: coordinator.isOverlayPresented)

            if coordinator.isLoading {
                LoadingOverlayView()
                    .transition(.opacity)
                    .zIndex(999)
            }
        }
    }
}

struct LoadingOverlayView: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 20) {
                ProgressView()
                    .scaleEffect(1.5)
                    .tint(.white)
                
                Text("Loading...")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .padding(25)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.gray.opacity(0.7))
            )
        }
        .transition(.opacity)
    }
}
