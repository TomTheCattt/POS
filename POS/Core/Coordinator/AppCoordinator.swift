import SwiftUI
import Combine

@MainActor
class AppCoordinator: ObservableObject {
    
    // MARK: - Properties
    @Published var navigationPath = NavigationPath()
    @Published var presentedRoute: (route: Route, config: NavigationConfig)?
    @Published var overlayRoute: (route: Route, config: NavigationConfig)?
    @Published var fullScreenRoute: (route: Route, config: NavigationConfig)?
    @Published var slideRoute: (route: Route, config: NavigationConfig)?
    @Published var slideDirection: NavigationStyle?
    
    // MARK: - UI States
    @Published var isLoading = false
    @Published var loadingText: String?
    @Published var progress: Double?
    @Published var toastMessage: (type: ToastType, message: String)?
    @Published var showToast = false
    @Published var alert: AlertItem?
    
    private var routerViewModel: RouterViewModel?
    private var sourceModel: SourceModel?
    
    init(routerViewModel: RouterViewModel, sourceModel: SourceModel) {
        self.routerViewModel = routerViewModel
        self.sourceModel = sourceModel
        setupSourceModelBindings()
    }
    
    // MARK: - Source Model Bindings
    private func setupSourceModelBindings() {
        guard let sourceModel = sourceModel else { return }
        
        // Bind loading state
        sourceModel.loadingPublisher
            .sink { [weak self] (isLoading, text) in
                self?.isLoading = isLoading
                self?.loadingText = text
            }
            .store(in: &sourceModel.cancellables)
        
        // Bind progress
        sourceModel.loadingWithProgressPublisher
            .sink { [weak self] progress in
                self?.progress = progress
            }
            .store(in: &sourceModel.cancellables)
        
        // Bind toast messages
        sourceModel.toastPublisher
            .sink { [weak self] message in
                self?.toastMessage = message
                if message != nil {
                    self?.showToast = true
                    self?.hideToastAfterDelay()
                }
            }
            .store(in: &sourceModel.cancellables)
        
        // Bind alerts
        sourceModel.alertPublisher
            .sink { [weak self] alert in
                self?.alert = alert
            }
            .store(in: &sourceModel.cancellables)
    }
    
    // MARK: - UI Display Methods
    private func hideToastAfterDelay() {
        Task { @MainActor [weak self] in
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.spring()) {
                self?.showToast = false
            }
        }
    }
    
    @ViewBuilder
    func loadingOverlay() -> some View {
        if isLoading {
            LoadingView(message: loadingText)
        }
    }
    
    @ViewBuilder
    func progressOverlay() -> some View {
        if let progress = progress {
            ProgressView(value: progress) {
                Text("Đang xử lý...")
            }
            .progressViewStyle(.circular)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.black.opacity(0.4))
        }
    }
    
    @ViewBuilder
    func toastOverlay() -> some View {
        if showToast, let (type, message) = toastMessage {
            ToastView(type: type, message: message)
                .transition(.opacity)
        }
    }
    
    // MARK: - View Wrapper
    
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
            if let routerViewModel {
                switch route {
                    // Authentication
                case .authentication:
                    let viewModel = routerViewModel.authVM
                    AuthenticationView(viewModel: viewModel)
                case .ownerAuth:
                    let viewModel = routerViewModel.settingsVM
                    OwnerAuthView(viewModel: viewModel)
                case .signIn:
                    let viewModel = routerViewModel.authVM
                    LoginSectionView(viewModel: viewModel)
                case .signUp:
                    let viewModel = routerViewModel.authVM
                    SignUpSectionView(viewModel: viewModel)
                    // Main Features
                case .home:
                    let viewModel = routerViewModel.homeVM
                    HomeView(viewModel: viewModel)
                case .order:
                    let viewModel = routerViewModel.orderVM
                    OrderView(viewModel: viewModel)
                case .orderMenuItemCard(let menuItem):
                    let viewModel = routerViewModel.orderVM
                    MenuItemCard(viewModel: viewModel, item: menuItem)
                case .orderItem(let orderItem):
                    let viewModel = routerViewModel.orderVM
                    ModernOrderItemView(viewModel: viewModel, item: orderItem)
                case .ordersHistory:
                    let viewModel = routerViewModel.historyVM
                    HistoryView(viewModel: viewModel)
                case .filter:
                    let viewModel = routerViewModel.historyVM
                    EnhancedFilterView(viewModel: viewModel)
                case .orderCard(let order):
                    let viewModel = routerViewModel.historyVM
                    EnhancedOrderCard(order: order, viewModel: viewModel)
                case .orderDetail(let order):
                    let viewModel = routerViewModel.historyVM
                    EnhancedOrderDetailView(order: order, viewModel: viewModel)
                case .analytics:
                    let viewModel = routerViewModel.analyticsVM
                    AnalyticsView(viewModel: viewModel)
                case .inventory:
                    let viewModel = routerViewModel.ingredientVM
                    InventoryView(viewModel: viewModel)
                case .note(let orderItem):
                    let viewModel = routerViewModel.orderVM
                    NoteView(viewModel: viewModel, orderItem: orderItem)
                    
                    // Settings
                case .settings:
                    let viewModel = routerViewModel.settingsVM
                    SettingsView(viewModel: viewModel)
                case .addShop:
                    let viewModel = routerViewModel.shopVM
                    AddShopSheet(viewModel: viewModel)
                case .staff:
                    let viewModel = routerViewModel.staffVM
                    StaffView(viewModel: viewModel)
                case .accountDetail:
                    let viewModel = routerViewModel.profileVM
                    AccountDetailView(viewModel: viewModel)
                case .ingredientSection:
                    let viewModel = routerViewModel.ingredientVM
                    IngredientSectionView(viewModel: viewModel)
                case .ingredientForm(let ingredient):
                    let viewModel = routerViewModel.ingredientVM
                    IngredientUsageFormView(viewModel: viewModel, item: ingredient)
                case .menuSection:
                    let viewModel = routerViewModel.menuVM
                    MenuSectionView(viewModel: viewModel)
                case .menuForm(let menu):
                    let viewModel = routerViewModel.menuVM
                    MenuFormView(viewModel: viewModel, menu: menu)
                case .updateMenuForm:
                    let viewModel = routerViewModel.menuVM
                    UpdateMenuForm(viewModel: viewModel)
                case .menuRow(let menu):
                    MenuRow(menu: menu)
                case .menuDetail:
                    let viewModel = routerViewModel.menuVM
                    MenuDetailView(viewModel: viewModel)
                case .menuItemForm(let menu, let menuItem):
                    let viewModel = routerViewModel.menuVM
                    MenuItemFormView(viewModel: viewModel, menu: menu, menuItem: menuItem)
                case .menuItemCard(let menuItem):
                    let viewModel = routerViewModel.menuVM
                    EnhancedMenuItemCard(viewModel: viewModel, item: menuItem)
                case .language:
                    let viewModel = routerViewModel.settingsVM
                    LanguageView(viewModel: viewModel)
                case .theme:
                    let viewModel = routerViewModel.settingsVM
                    ThemeView(viewModel: viewModel)
                case .setUpPrinter:
                    let viewModel = routerViewModel.printerVM
                    PrinterView(viewModel: viewModel)
                case .password:
                    let viewModel = routerViewModel.passwordVM
                    PasswordView(viewModel: viewModel)
                case .manageShops:
                    let viewModel = routerViewModel.shopVM
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

extension View {
    func customAlert(_ alert: Binding<AlertItem?>) -> some View {
        self.alert(
            alert.wrappedValue?.title ?? "",
            isPresented: Binding(
                get: { alert.wrappedValue != nil },
                set: { if !$0 { alert.wrappedValue = nil } }
            ),
            presenting: alert.wrappedValue
        ) { alertData in
            if let primary = alertData.primaryButton {
                Button(primary.title, role: primary.role) {
                    primary.action?()
                    alert.wrappedValue = nil
                }
            }
            if let secondary = alertData.secondaryButton {
                Button(secondary.title, role: secondary.role) {
                    secondary.action?()
                    alert.wrappedValue = nil
                }
            }
        } message: { alertData in
            if let message = alertData.message {
                Text(message)
            }
        }
    }
}
