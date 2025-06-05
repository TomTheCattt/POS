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
    
    private var source: SourceModel?
    
    init(source: SourceModel) {
        self.source = source
    }
    
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
            Task {
                try? await Task.sleep(nanoseconds: UInt64(config.autoDismissDelay * 1_000_000_000))
                self.dismiss(style: style)
            }
        }
        
        // Gọi completion handler nếu có
        if let completion = config.completion {
            Task { @MainActor in
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
    @MainActor
    @ViewBuilder
    func makeView(for route: Route) -> some View {
        Group {
            if let source {
                switch route {
                    // Authentication
                case .authentication:
                    let viewModel = AuthenticationViewModel(source: source)
                    AuthenticationView(viewModel: viewModel)
                    
                    // Main Features
                case .home:
                    let viewModel = HomeViewModel(source: source)
                    HomeView(viewModel: viewModel)
                case .menu:
                    let viewModel = OrderViewModel(source: source)
                    OrderView(viewModel: viewModel)
                case .history:
                    let viewModel = HistoryViewModel(source: source)
                    HistoryView(viewModel: viewModel)
                case .analytics:
                    let viewModel = AnalyticsViewModel(source: source)
                    AnalyticsView(viewModel: viewModel)
                case .inventory:
                    let viewModel = IngredientViewModel(source: source)
                    InventoryView(viewModel: viewModel)
                case .note(let orderItem):
                    let viewModel = OrderViewModel(source: source)
                    NoteView(viewModel: viewModel, orderItem: orderItem)
                    
                    // Settings
                case .settings:
                    let viewModel = SettingsViewModel(source: source)
                    SettingsView(viewModel: viewModel)
                case .accountDetail:
                    let viewModel = ProfileViewModel(source: source)
                    AccountDetailView(viewModel: viewModel)
                case .ingredientSection:
                    let viewModel = IngredientViewModel(source: source)
                    IngredientSectionView(viewModel: viewModel)
                case .ingredientForm(let ingredient):
                    let viewModel = IngredientViewModel(source: source)
                    IngredientUsageFormView(viewModel: viewModel, item: ingredient)
                case .menuSection:
                    let viewModel = MenuViewModel(source: source)
                    MenuSectionView(viewModel: viewModel)
                case .menuForm(let menu):
                    let viewModel = MenuViewModel(source: source)
                    MenuFormView(viewModel: viewModel, menu: menu)
                case .menuDetail(let menu):
                    let viewModel = MenuViewModel(source: source)
                    MenuDetailView(viewModel: viewModel, menu: menu)
                case .menuItemForm(let menu, let menuItem):
                    let viewModel = MenuViewModel(source: source)
                    MenuItemFormView(viewModel: viewModel, menu: menu, menuItem: menuItem)
                case .language:
                    let viewModel = SettingsViewModel(source: source)
                    LanguageView(viewModel: viewModel)
                case .theme:
                    let viewModel = SettingsViewModel(source: source)
                    ThemeView(viewModel: viewModel)
                case .setUpPrinter:
                    let viewModel = PrinterViewModel(source: source)
                    PrinterView(viewModel: viewModel)
                case .password:
                    let viewModel = PasswordViewModel(source: source)
                    PasswordView(viewModel: viewModel)
                case .manageShops:
                    let viewModel = ShopManagementViewModel(source: source)
                    ShopManagementView(viewModel: viewModel)
                }
            } else {
                EmptyView()
            }
        }
        .ignoresSafeArea(.keyboard)
    }
    
    // MARK: - Reset
    @MainActor
    func reset() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            navigationPath = NavigationPath()
            presentedRoute = nil
            overlayRoute = nil
            fullScreenRoute = nil
            slideRoute = nil
            slideDirection = nil
        }
    }
}
