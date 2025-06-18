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
    @Published var currentRoute: Route = .authentication
    
    // MARK: - UI States
    @Published var isLoading = false
    @Published var loadingText: String?
    @Published var progress: Double?
    @Published var toastMessage: (type: ToastType, message: String)?
    @Published var showToast = false
    @Published var alert: AlertItem?
    
    private var routerViewModel: RouterViewModel?
    private var sourceModel: SourceModel?
    private var toastTask: Task<Void, Never>?
    
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
                self?.handleToastMessage(message)
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
    private func handleToastMessage(_ message: (type: ToastType, message: String)?) {
        // Hủy task hiện tại nếu có
        toastTask?.cancel()
        
        guard let message = message else {
            withAnimation(.spring()) {
                showToast = false
            }
            return
        }
        
        // Tạo task mới để xử lý toast
        toastTask = Task { @MainActor in
            // Cập nhật message và hiển thị toast
            toastMessage = message
            withAnimation(.spring()) {
                showToast = true
            }
            
            // Đợi 2 giây
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            
            // Kiểm tra xem task có bị hủy không
            guard !Task.isCancelled else { return }
            
            // Ẩn toast với animation
            withAnimation(.spring()) {
                showToast = false
            }
            
            // Xóa message sau khi ẩn
            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3 giây
            if !Task.isCancelled {
                toastMessage = nil
            }
        }
    }
    
    @ViewBuilder
    func loadingOverlay() -> some View {
        if isLoading {
            LoadingView(message: loadingText)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.2))
                .allowsHitTesting(true)
                .contentShape(Rectangle())
                .onTapGesture {}
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
            .background(Color.black.opacity(0.2))
            .allowsHitTesting(true)
            .contentShape(Rectangle())
            .onTapGesture {}
        }
    }
    
    @ViewBuilder
    func toastOverlay() -> some View {
        if showToast, let (type, message) = toastMessage {
            ToastView(type: type, message: message)
                .transition(.opacity)
                .zIndex(1000) // Đảm bảo toast luôn hiển thị trên cùng
        }
    }
    
    // MARK: - View Wrapper
    
    func updateCurrentRoute(_ route: Route) {
        currentRoute = route
    }
    
    // MARK: - Navigation Methods
    func navigateTo(_ route: Route, using style: NavigationStyle = .push, with config: NavigationConfig = .default) {
        // Cập nhật currentRoute
        //currentRoute = route
        
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
                case .authentication:
                    AuthenticationView(viewModel: routerViewModel.authVM)
                case .home:
                    HomeView(viewModel: routerViewModel.homeVM)
                case .order:
                    OrderView(viewModel: routerViewModel.orderVM)
                case .orderSummary:
                    OrderSummarySheet(viewModel: routerViewModel.orderVM)
                case .note(let orderItem):
                    NoteView(viewModel: routerViewModel.orderVM, orderItem: orderItem)
                case .addCustomer:
                    AddCustomerView(viewModel: routerViewModel.orderVM)
                case .ordersHistory:
                    HistoryView(viewModel: routerViewModel.historyVM)
                case .orderDetail(let order):
                    EnhancedOrderDetailView(viewModel: routerViewModel.historyVM, order: order)
                case .revenue(let shop):
                    RevenueRecordView(viewModel: routerViewModel.revenueRecordVM, shop: shop)
                case .expense:
                    ExpenseManagementView(viewModel: routerViewModel.expenseVM)
                case .settings:
                    SettingsView(viewModel: routerViewModel.settingsVM)
                case .accountDetail:
                    AccountDetailView(viewModel: routerViewModel.profileVM)
                case .password:
                    PasswordView(viewModel: routerViewModel.passwordVM)
                case .manageShops:
                    ShopManagementView(viewModel: routerViewModel.shopVM)
                case .menuSection(let shop):
                    MenuSectionView(viewModel: routerViewModel.menuVM, shop: shop)
                case .menuForm(let appMenu):
                    MenuFormView(viewModel: routerViewModel.menuVM, menu: appMenu)
                case .menuItemForm(let appMenu, let menuItem):
                    MenuItemFormView(viewModel: routerViewModel.menuVM, menu: appMenu, menuItem: menuItem)
                case .ingredientSection(let shop):
                    IngredientSectionView(viewModel: routerViewModel.ingredientVM, shop: shop)
                case .ingredientForm(let ingredientUsage):
                    IngredientUsageFormView(viewModel: routerViewModel.ingredientVM, item: ingredientUsage)
                case .setUpPrinter:
                    PrinterView(viewModel: routerViewModel.printerVM)
                case .language:
                    LanguageView(viewModel: routerViewModel.settingsVM)
                case .theme:
                    ThemeView(viewModel: routerViewModel.settingsVM)
                case .addShop(let shop):
                    AddShopSheet(viewModel: routerViewModel.shopVM, shop: shop)
                case .ownerAuth:
                    OwnerAuthView(viewModel: routerViewModel.settingsVM)
                case .staff(let shop):
                    StaffView(viewModel: routerViewModel.staffVM, shop: shop)
                case .orderItem(let orderItem):
                    OrderItemView(viewModel: routerViewModel.orderVM, item: orderItem)
                case .orderMenuItemCardIphone(let menuItem):
                    CompactMenuItemCard(viewModel: routerViewModel.orderVM, item: menuItem)
                case .orderMenuItemCardIpad(let menuItem):
                    MenuItemCard(viewModel: routerViewModel.orderVM, item: menuItem)
                case .addVoucher:
                    AddVoucherSheet(viewModel: routerViewModel.shopVM)
                case .shopDetail(let shop):
                    ShopDetailView(viewModel: routerViewModel.shopVM, shop: shop)
                case .shopRow(let shop):
                    ShopRow(shop: shop)
                case .menuDetail(let menu):
                    MenuDetailView(viewModel: routerViewModel.menuVM, currentMenu: menu)
                case .menuRow(let menu):
                    MenuRow(menu: menu)
                case .menuItemCard(let menuItem):
                    EnhancedMenuItemCard(viewModel: routerViewModel.menuVM, item: menuItem)
                }
            } else {
                EmptyView()
            }
        }
        .dismissKeyboardOnTap()
//        .ignoresSafeArea(.keyboard)
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

//extension View {
//    func customAlert(_ alert: Binding<AlertItem?>) -> some View {
//        self.alert(
//            alert.wrappedValue?.title ?? "",
//            isPresented: Binding(
//                get: { alert.wrappedValue != nil },
//                set: { if !$0 { alert.wrappedValue = nil } }
//            ),
//            presenting: alert.wrappedValue
//        ) { alertData in
//            if let primary = alertData.primaryButton {
//                Button(primary.title, role: primary.role) {
//                    primary.action?()
//                    alert.wrappedValue = nil
//                }
//            }
//            if let secondary = alertData.secondaryButton {
//                Button(secondary.title, role: secondary.role) {
//                    secondary.action?()
//                    alert.wrappedValue = nil
//                }
//            }
//        } message: { alertData in
//            if let message = alertData.message {
//                Text(message)
//            }
//        }
//    }
//}
