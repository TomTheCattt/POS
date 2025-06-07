//
//  RootView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/5/25.
//

import SwiftUI
import Combine

struct RootView: View {
    // MARK: - Properties
    @StateObject private var appState: AppState = AppState()
    
    // MARK: - Body
    var body: some View {
        GeometryReader { _ in
            NavigationStack(path: $appState.coordinator.navigationPath) {
                Group {
                    if appState.sourceModel.isLoading {
                        LoadingView()
                            .applyNavigationStyle(.fade)
                    }
                    else if let _ = appState.sourceModel.currentUser {
                        appState.coordinator.makeView(for: .home)
                            .applyNavigationStyle(.push)
                    } else {
                        appState.coordinator.makeView(for: .authentication)
                            .applyNavigationStyle(.fade)
                    }
                }
                .navigationBarHidden(true)
                .navigationDestination(for: Route.self) { route in
                    appState.coordinator.makeView(for: route)
                        .applyNavigationStyle(.push)
                }
            }
            .sheet(isPresented: Binding(
                get: { appState.coordinator.presentedRoute != nil },
                set: { if !$0 { appState.coordinator.presentedRoute = nil } }
            )) {
                if let (route, config) = appState.coordinator.presentedRoute {
                    appState.coordinator.makeView(for: route)
                        .applyNavigationStyle(.present)
                        .applyBackgroundEffect(config.backgroundEffect)
                }
            }
            .fullScreenCover(isPresented: Binding(
                get: { appState.coordinator.fullScreenRoute != nil },
                set: { if !$0 { appState.coordinator.fullScreenRoute = nil } }
            )) {
                if let (route, _) = appState.coordinator.fullScreenRoute {
                    appState.coordinator.makeView(for: route)
                        .applyNavigationStyle(.fullScreen)
                }
            }
            .overlay {
                if let (route, config) = appState.coordinator.overlayRoute {
                    appState.coordinator.makeView(for: route)
                        .applyNavigationStyle(.overlay)
                        .applyBackgroundEffect(config.backgroundEffect)
                }
            }
            .overlay {
                if let (route, config) = appState.coordinator.slideRoute {
                    appState.coordinator.makeView(for: route)
                        .applyNavigationStyle(appState.coordinator.slideDirection ?? .slideFromRight)
                        .applyBackgroundEffect(config.backgroundEffect)
                }
            }
            .overlay { appState.coordinator.loadingOverlay() }
            .overlay { appState.coordinator.progressOverlay() }
            .overlay { appState.coordinator.toastOverlay() }
            .optimizedShadow()
            .customAlert($appState.coordinator.alert)
        }
        .ignoresSafeArea(.keyboard)
        .environmentObject(appState)
    }
}

@MainActor
final class AppState: ObservableObject {
    let sourceModel: SourceModel
    private let routerViewModel: RouterViewModel
    var coordinator: AppCoordinator
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        self.sourceModel = SourceModel()
        self.routerViewModel = RouterViewModel(source: sourceModel)
        self.coordinator = AppCoordinator(routerViewModel: routerViewModel, sourceModel: sourceModel)
        
        sourceModel.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
        
        coordinator.objectWillChange
            .sink { [weak self] in
                self?.objectWillChange.send()
            }
            .store(in: &cancellables)
    }
}

class KeyboardObserver: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0
    
    init() {
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillShowNotification,
            object: nil,
            queue: .main
        ) { notification in
            if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
                self.keyboardHeight = keyboardFrame.height
            }
        }
        
        NotificationCenter.default.addObserver(
            forName: UIResponder.keyboardWillHideNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.keyboardHeight = 0
        }
    }
}
