import SwiftUI
import Combine

class AppCoordinator: ObservableObject {
    // MARK: - Properties
    @Published var navigationPath = NavigationPath()
    @Published var presentedRoute: (route: Route, config: NavigationConfig)?
    @Published var overlayRoute: (route: Route, config: NavigationConfig)?
    @Published var fullScreenRoute: (route: Route, config: NavigationConfig)?
    @Published var slideRoute: (route: Route, config: NavigationConfig)?
    @Published var slideDirection: NavigationStyle?
    
    private let viewModelFactory = ViewModelFactory.shared
    
    // MARK: - Navigation Methods
    func navigateTo(_ route: Route, using style: NavigationStyle = .push, with config: NavigationConfig = .default) {
        // Xử lý dismiss previous nếu được yêu cầu
        if config.shouldDismissPrevious {
            dismiss()
        }
        
        let animation = config.customAnimation ?? style.animation
        let performNavigation = {
            switch style {
            case .push:
                if config.isAnimated {
                    withAnimation(animation) {
                        self.navigationPath.append(route)
                    }
                } else {
                    self.navigationPath.append(route)
                }
                
            case .present:
                if config.isAnimated {
                    withAnimation(animation) {
                        self.presentedRoute = (route, config)
                    }
                } else {
                    self.presentedRoute = (route, config)
                }
                
            case .overlay:
                if config.isAnimated {
                    withAnimation(animation) {
                        self.overlayRoute = (route, config)
                    }
                } else {
                    self.overlayRoute = (route, config)
                }
                
            case .fullScreen:
                if config.isAnimated {
                    withAnimation(animation) {
                        self.fullScreenRoute = (route, config)
                    }
                } else {
                    self.fullScreenRoute = (route, config)
                }
                
            case .slideFromLeft, .slideFromRight, .slideFromTop, .slideFromBottom:
                if config.isAnimated {
                    withAnimation(animation) {
                        self.slideDirection = style
                        self.slideRoute = (route, config)
                    }
                } else {
                    self.slideDirection = style
                    self.slideRoute = (route, config)
                }
                
            case .fade, .scale:
                if config.isAnimated {
                    withAnimation(animation) {
                        self.overlayRoute = (route, config)
                    }
                } else {
                    self.overlayRoute = (route, config)
                }
            }
        }
        
        performNavigation()
        
        // Xử lý auto-dismiss nếu được cấu hình
        if config.autoDismiss {
            DispatchQueue.main.asyncAfter(deadline: .now() + config.autoDismissDelay) {
                self.dismiss(style: style)
            }
        }
        
        // Gọi completion handler nếu có
        if let completion = config.completion {
            DispatchQueue.main.async {
                completion()
            }
        }
    }
    
    func dismiss(style: NavigationStyle? = nil) {
        if let style = style {
            let animation = style.animation
            switch style {
            case .present:
                withAnimation(animation) {
                    presentedRoute = nil
                }
            case .overlay, .fade, .scale:
                withAnimation(animation) {
                    overlayRoute = nil
                }
            case .fullScreen:
                withAnimation(animation) {
                    fullScreenRoute = nil
                }
            case .slideFromLeft, .slideFromRight, .slideFromTop, .slideFromBottom:
                withAnimation(animation) {
                    slideRoute = nil
                    slideDirection = nil
                }
            case .push:
                pop()
            }
        } else {
            // Tự động xác định và đóng view hiện tại
            if overlayRoute != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    overlayRoute = nil
                }
            } else if presentedRoute != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    presentedRoute = nil
                }
            } else if fullScreenRoute != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    fullScreenRoute = nil
                }
            } else if slideRoute != nil {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    slideRoute = nil
                    slideDirection = nil
                }
            }
        }
    }
    
    func pop() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            if !navigationPath.isEmpty {
                navigationPath.removeLast()
            }
        }
    }
    
    func popToRoot() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            navigationPath.removeLast(navigationPath.count)
        }
    }
    
    // MARK: - View Creation
    @ViewBuilder
    func makeView(for route: Route) -> some View {
        Group {
            switch route {
            // Authentication
            case .authentication:
                let viewModel = route.makeViewModel() as! AuthenticationViewModel
                AuthenticationView(viewModel: viewModel, coordinator: self)
            case .verifyEmail:
                VerifyEmailSentView()
            case .forgotPassword:
                ForgotPasswordView(coordinator: self)
                
            // Main Features
            case .home:
                let viewModel = route.makeViewModel() as! HomeViewModel
                HomeView(viewModel: viewModel, coordinator: self)
            case .menu:
                let viewModel = route.makeViewModel() as! MenuViewModel
                MenuView(viewModel: viewModel, coordinator: self)
            case .history:
                let viewModel = route.makeViewModel() as! HistoryViewModel
                HistoryView(viewModel: viewModel, coordinator: self)
            case .analytics:
                let viewModel = route.makeViewModel() as! AnalyticsViewModel
                AnalyticsView(viewModel: viewModel, coordinator: self)
            case .inventory:
                let viewModel = route.makeViewModel() as! InventoryViewModel
                InventoryView(viewModel: viewModel, coordinator: self)
            case .note(let orderItem):
                let viewModel = route.makeViewModel() as! MenuViewModel
                NoteView(viewModel: viewModel, coordinator: self, orderItem: orderItem)
                
            // Settings
            case .settings:
                let viewModel = route.makeViewModel() as! SettingsViewModel
                SettingsView(viewModel: viewModel, coordinator: self)
            case .updateInventory:
                let viewModel = route.makeViewModel() as! InventoryViewModel
                UpdateInventoryView(viewModel: viewModel, coordinator: self)
            case .updateMenu:
                let viewModel = route.makeViewModel() as! MenuViewModel
                UpdateMenuView(viewModel: viewModel, coordinator: self)
            case .language:
                let viewModel = route.makeViewModel() as! SettingsViewModel
                LanguageView(viewModel: viewModel, coordinator: self)
            case .theme:
                let viewModel = route.makeViewModel() as! SettingsViewModel
                ThemeView(viewModel: viewModel, coordinator: self)
            case .setUpPrinter:
                let viewModel = route.makeViewModel() as! PrinterViewModel
                PrinterView(viewModel: viewModel, coordinator: self)
            }
        }
    }
    
    // MARK: - Reset
    func reset() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            navigationPath = NavigationPath()
            presentedRoute = nil
            overlayRoute = nil
            fullScreenRoute = nil
            slideRoute = nil
            slideDirection = nil
            viewModelFactory.resetAll()
        }
    }
} 
