//
//  RootView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/5/25.
//

import SwiftUI

struct RootView: View {
    // MARK: - Properties
    @StateObject private var environment: AppEnvironment = AppEnvironment()
    @StateObject private var coordinator: AppCoordinator = AppCoordinator()
    
    @ObservedObject private var authService: AuthService
    
    init() {
        let environment = AppEnvironment()
        _environment = StateObject(wrappedValue: environment)
        authService = environment.authService
    }
    
    // MARK: - Body
    var body: some View {
        NavigationStack(path: $coordinator.navigationPath) {
            Group {
                switch authService.authState {
                case .authenticated:
                    coordinator.makeView(for: .home)
                        .applyNavigationStyle(.push)
                case .unauthenticated:
                    coordinator.makeView(for: .authentication)
                        .applyNavigationStyle(.fade)
                case .loading:
                    LoadingView()
                        .applyNavigationStyle(.fade)
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: Route.self) { route in
                coordinator.makeView(for: route)
                    .applyNavigationStyle(.push)
            }
        }
        .sheet(isPresented: Binding(
            get: { coordinator.presentedRoute != nil },
            set: { if !$0 { coordinator.presentedRoute = nil } }
        )) {
            if let (route, config) = coordinator.presentedRoute {
                coordinator.makeView(for: route)
                    .applyNavigationStyle(.present)
                    .applyBackgroundEffect(config.backgroundEffect)
            }
        }
        .fullScreenCover(isPresented: Binding(
            get: { coordinator.fullScreenRoute != nil },
            set: { if !$0 { coordinator.fullScreenRoute = nil } }
        )) {
            if let (route, _) = coordinator.fullScreenRoute {
                coordinator.makeView(for: route)
                    .applyNavigationStyle(.fullScreen)
            }
        }
        .overlay {
            if let (route, config) = coordinator.overlayRoute {
                coordinator.makeView(for: route)
                    .applyNavigationStyle(.overlay)
                    .applyBackgroundEffect(config.backgroundEffect)
            }
        }
        .overlay {
            if let (route, config) = coordinator.slideRoute {
                coordinator.makeView(for: route)
                    .applyNavigationStyle(coordinator.slideDirection ?? .slideFromRight)
                    .applyBackgroundEffect(config.backgroundEffect)
            }
        }
        .environmentObject(environment)
        .environmentObject(coordinator)
    }
}

//#Preview {
//    RootView()
//}
