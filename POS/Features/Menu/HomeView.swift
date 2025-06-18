import SwiftUI

enum HomeTab: CaseIterable {
    case order, history, expense, revenue, settings
    
    var title: String {
        switch self {
        case .order:
            return "Thực đơn"
        case .history:
            return "Lịch sử"
        case .expense:
            return "Thu chi"
        case .revenue:
            return "Doanh thu"
        case .settings:
            return "Cài đặt"
        }
    }
    
    var icon: String {
        switch self {
        case .order:
            return "cup.and.saucer.fill"
        case .history:
            return "clock.fill"
        case .expense:
            return "dollarsign.circle.fill"
        case .revenue:
            return "chart.line.uptrend.xyaxis.circle.fill"
        case .settings:
            return "gearshape.fill"
        }
    }
    
    var route: Route {
        switch self {
        case .order:
            return .order
        case .history:
            return .ordersHistory
        case .expense:
            return .expense
        case .revenue:
            return .revenue(nil)
        case .settings:
            return .settings
        }
    }
    
    var themeColors: TabThemeColor {
        let colors = SettingsService.shared.currentThemeColors
        switch self {
        case .order:
            return colors.order
        case .history:
            return colors.history
        case .expense:
            return colors.expense
        case .revenue:
            return colors.revenue
        case .settings:
            return colors.settings
        }
    }
}

struct HomeView: View {
    @ObservedObject private var viewModel: HomeViewModel
    @EnvironmentObject private var appState: AppState
    
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        GeometryReader { geometry in
            if isIphone {
                iPhoneLayout(geometry: geometry)
                    .background(
                        appState.currentTabThemeColors.softGradient(for: colorScheme)
                    )
            } else {
                iPadLayout(geometry: geometry)
                    .background(
                        appState.currentTabThemeColors.softGradient(for: colorScheme)
                    )
            }
        }
    }
}

// MARK: - iPhone Layout
extension HomeView {
    @ViewBuilder
    private func iPhoneLayout(geometry: GeometryProxy) -> some View {
        let sideMenuWidth = min(geometry.size.width * 0.85, 320)
        
        ZStack(alignment: .leading) {
            VStack(spacing: 16) {
                compactNavigationBar
                    .padding(.top, 8)
                
                contentView(for: viewModel.selectedTab)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .scaleEffect(viewModel.isMenuVisible ? 0.92 : 1.0)
                    .offset(x: viewModel.isMenuVisible ? sideMenuWidth * 0.3 : 0)
                    .blur(radius: viewModel.isMenuVisible ? 1.5 : 0)
                    .disabled(viewModel.isMenuVisible)
                    .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.isMenuVisible)
                    .padding(.top, 8)
            }
            .allowsHitTesting(!viewModel.isMenuVisible)
            .zIndex(3)
            
            if viewModel.isMenuVisible {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.4),
                                Color.black.opacity(0.1)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .ignoresSafeArea()
                    .transition(.opacity)
                    .onTapGesture {
                        viewModel.isMenuVisible(false)
                    }
            }
            
            iPhoneSideMenuView(width: sideMenuWidth, geometry: geometry)
                .zIndex(4)
                .frame(maxWidth: sideMenuWidth)
            
            edgeSwipeDetector(geometry: geometry)
                .zIndex(99)
        }
        .onChange(of: viewModel.selectedTab) { _ in
            if viewModel.isMenuVisible {
                viewModel.isMenuVisible(false)
            }
        }
        .onDisappear {
            viewModel.resetState()
        }
    }
    
    // MARK: - Alternative Compact Navigation Bar
    private var compactNavigationBar: some View {
        HStack(spacing: 12) {
            // Menu Button
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    viewModel.isMenuVisible(true)
                }
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                    
                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(viewModel.selectedTab.themeColors.primaryColor)
                                .frame(width: index == 1 ? 12 : 16, height: 2)
                        }
                    }
                }
            }
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.isMenuVisible)
            
            // Title with background
            HStack(spacing: 6) {
                Image(systemName: viewModel.selectedTab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewModel.selectedTab.themeColors.primaryColor)
                
                Text(viewModel.selectedTab.title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(.thinMaterial)
                    .overlay(
                        Capsule()
                            .stroke(viewModel.selectedTab.themeColors.primaryColor.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(viewModel.isMenuVisible ? 0.6 : 1.0)
            .scaleEffect(viewModel.isMenuVisible ? 0.95 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.isMenuVisible)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Enhanced Side Menu
    private func iPhoneSideMenuView(width: CGFloat, geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Header
            headerView
                .padding(.top, safeAreaInsets.top + 24)
                .padding(.bottom, 32)
            
            // Menu Items
            menuItemsScrollView
            
            Spacer()
            
            // Divider
            ModernDivider(tabThemeColors: appState.currentTabThemeColors)
            
            Spacer()
            
            // Logout Button
            logoutButton
                .padding(.bottom, safeAreaInsets.bottom + 20)
        }
        .background(backgroundView)
        .frame(maxHeight: .infinity)
        .frame(width: width)
        .offset(x: viewModel.isMenuVisible ? 0 : -width)
        .offset(x: viewModel.dragOffset)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: viewModel.isMenuVisible)
        .gesture(menuDragGesture(width: width))
    }

    // MARK: - Side Menu Components
    private var headerView: some View {
        VStack(spacing: 12) {
            // App Icon
            appIconView
            
            // App Title
            VStack(spacing: 4) {
                Text("Barista POS")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Quản lý bán hàng")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var appIconView: some View {
        ZStack {
            Circle()
                .fill(viewModel.selectedTab.themeColors.gradient(for: colorScheme))
                .frame(width: 60, height: 60)
                .shadow(color: viewModel.selectedTab.themeColors.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
            
            Image(systemName: "cup.and.saucer.fill")
                .font(.system(size: 28))
                .foregroundColor(.white)
        }
        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.selectedTab)
    }

    private var menuItemsScrollView: some View {
        ScrollViewReader { proxy in
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(HomeTab.allCases, id: \.self) { tab in
                        menuItemButton(for: tab)
                            .id(tab)
                    }
                }
                .padding(.vertical)
                .padding(.horizontal, 16)
            }
            .onChange(of: viewModel.selectedTab) { newTab in
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    proxy.scrollTo(newTab, anchor: .center)
                }
            }
        }
    }

    @ViewBuilder
    private func menuItemButton(for tab: HomeTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectTab(tab)
                appState.coordinator.updateCurrentRoute(tab.route)
                viewModel.isMenuVisible(false)
            }
        } label: {
            HStack(spacing: 16) {
                menuIconView(for: tab, isSelected: isSelected)
                menuTitleView(for: tab, isSelected: isSelected)
                
                Spacer()
                
                if isSelected {
                    Circle()
                        .fill(tab.themeColors.primaryColor)
                        .frame(width: 6, height: 6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(menuItemBackground(for: tab, isSelected: isSelected))
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }

    private func menuIconView(for tab: HomeTab, isSelected: Bool) -> some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 12)
                    .fill(tab.themeColors.primaryColor)
                    .frame(width: 44, height: 44)
                    .shadow(color: tab.themeColors.primaryColor.opacity(0.25), radius: 6, x: 0, y: 4)
                    .transition(.scale)
            }
            
            Image(systemName: tab.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(isSelected ? .white : tab.themeColors.primaryColor)
                .frame(width: 44, height: 44)
        }
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }

    private func menuTitleView(for tab: HomeTab, isSelected: Bool) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(tab.title)
                .font(.system(size: 16, weight: .medium, design: .rounded))
                .foregroundColor(isSelected ? tab.themeColors.primaryColor : .primary)
            
            if isSelected {
                Text("Đang hoạt động")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(tab.themeColors.primaryColor)
            }
        }
    }

    private func menuItemBackground(for tab: HomeTab, isSelected: Bool) -> some View {
        let backgroundColor = isSelected ? tab.themeColors.primaryColor.opacity(0.1) : Color.clear
        let borderColor = isSelected ? tab.themeColors.primaryColor.opacity(0.3) : Color.clear
        let borderWidth: CGFloat = isSelected ? 1 : 0
        
        return RoundedRectangle(cornerRadius: 16)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }

    private var logoutButton: some View {
        Button {
            Task {
                await viewModel.signOut()
                appState.coordinator.updateCurrentRoute(.authentication)
            }
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.1))
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.red)
                }
                
                Text("Đăng xuất")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.red)
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(logoutButtonBackground)
        }
        .padding(.horizontal, 16)
    }

    private var logoutButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.red.opacity(0.15))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
            )
    }

    private var backgroundView: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(.regularMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        viewModel.selectedTab.themeColors.primaryColor.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
    }
    
    // MARK: - Edge Swipe Detector
    private func edgeSwipeDetector(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 20)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .simultaneousGesture(
                DragGesture()
                    .onChanged { value in
                        let isFromLeftEdge = value.startLocation.x < 20
                        let isSwipingRight = value.translation.width > 0
                        
                        if isFromLeftEdge && isSwipingRight {
                            viewModel.setOffSet(value.translation.width)
                            
                            if !viewModel.isDragging {
                                viewModel.isDragging(true)
                                appState.sourceModel.environment.hapticsService.impact(.light)
                            }
                        }
                    }
                    .onEnded { value in
                        let isFromLeftEdge = value.startLocation.x < 20
                        let dragDistance = value.translation.width
                        let hasSufficientSwipe = dragDistance > 50
                        
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                            if isFromLeftEdge && hasSufficientSwipe {
                                viewModel.isMenuVisible(true)
                            } else {
                                viewModel.isMenuVisible(false)
                            }
                        }
                        
                        withAnimation(.easeOut(duration: 0.2)) {
                            viewModel.isDragging(false)
                            viewModel.setOffSet(0)
                        }
                    }
            )
    }

    // MARK: - Menu Drag Gesture
    private func menuDragGesture(width: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.width
                let isOpening = !viewModel.isMenuVisible && translation > 0 && translation <= width
                let isClosing = viewModel.isMenuVisible && translation < 0 && abs(translation) <= width

                if isOpening || isClosing {
                    viewModel.setOffSet(translation)

                    if !viewModel.isDragging {
                        viewModel.isDragging(true)
                        appState.sourceModel.environment.hapticsService.impact(.light)
                    }
                }
            }
            .onEnded { value in
                viewModel.isDragging(false)
                let translation = value.translation.width
                let velocity = value.velocity.width

                let shouldOpen = !viewModel.isMenuVisible && (translation > width * 0.4 || velocity > 800)
                let shouldClose = viewModel.isMenuVisible && (abs(translation) > width * 0.4 || velocity < -800)

                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    viewModel.setOffSet(0)

                    if shouldOpen {
                        viewModel.isMenuVisible(true)
                    } else if shouldClose {
                        viewModel.isMenuVisible(false)
                    }
                }
            }
    }
}

// MARK: - iPad Layout
extension HomeView {
    @ViewBuilder
    private func iPadLayout(geometry: GeometryProxy) -> some View {
        let sideMenuWidth = geometry.size.width * 0.15
        
        HStack(spacing: 0) {
            iPadSideMenu(width: sideMenuWidth)
                .frame(maxWidth: sideMenuWidth)
            
            ModernDivider(tabThemeColors: viewModel.selectedTab.themeColors, isVertical: true)
            
            contentView(for: viewModel.selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onDisappear {
            viewModel.resetState()
        }
    }
    
    private func iPadSideMenu(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            // Header với logo và tên app
            headerSection
                .padding(.vertical, 30)
            
            // Menu tabs
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(HomeTab.allCases, id: \.self) { tab in
                        menuButton(for: tab)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Logout section
            logoutSection
        }
        .background(sideMenuBackground)
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - View Components
    private var headerSection: some View {
        VStack(spacing: 4) {
            // Logo với animation
            ZStack {
                Circle()
                    .fill(viewModel.selectedTab.themeColors.gradient(for: colorScheme))
                    .frame(width: 60, height: 60)
                    .shadow(color: viewModel.selectedTab.themeColors.primaryColor.opacity(0.3), radius: 8, x: 0, y: 4)
                
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.7), value: viewModel.selectedTab)
            
            // Tên app
            VStack(spacing: 4) {
                Text("Barista POS")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Quản lý bán hàng")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private var logoutSection: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color(.systemGray4).opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal)
            
            VStack {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 20))
                    Text("Đăng xuất")
                        .font(.system(size: 16, weight: .medium))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .layeredAlertButton(cornerRadius: 16, hasStroke: true) {
                    Task {
                        await viewModel.signOut()
                        appState.coordinator.updateCurrentRoute(.authentication)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 20)
        }
    }
    
    private var sideMenuBackground: some View {
        RoundedRectangle(cornerRadius: 0)
            .fill(.regularMaterial)
            .overlay(
                LinearGradient(
                    colors: [
                        Color.clear,
                        viewModel.selectedTab.themeColors.primaryColor.opacity(0.05)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .ignoresSafeArea()
    }
    
    private func menuButton(for tab: HomeTab) -> some View {
        let isSelected = viewModel.selectedTab == tab
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                viewModel.selectTab(tab)
                appState.coordinator.updateCurrentRoute(tab.route)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? .white : tab.themeColors.primaryColor)
                    .frame(width: 28)
                
                Text(tab.title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : tab.themeColors.primaryColor)
                
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? viewModel.selectedTab.themeColors.primaryColor : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : viewModel.selectedTab.themeColors.primaryColor.opacity(0.4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Content Views
extension HomeView {
    @ViewBuilder
    private func contentView(for route: HomeTab) -> some View {
        switch route {
        case .order:
            appState.coordinator.makeView(for: .order)
        case .history:
            appState.coordinator.makeView(for: .ordersHistory)
        case .expense:
            appState.coordinator.makeView(for: .expense)
        case .revenue:
            appState.coordinator.makeView(for: .revenue(nil))
        case .settings:
            appState.coordinator.makeView(for: .settings)
        }
    }
}

// MARK: - SafeAreaInsets Environment Extension
struct SafeAreaInsetsKey: EnvironmentKey {
    static var defaultValue: EdgeInsets {
        // Lấy cửa sổ đầu tiên từ UIWindowScene đang chạy
        let window = UIApplication.shared
            .connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }
        
        return window?.safeAreaInsets.swiftUIInsets ?? EdgeInsets()
    }
}

extension EnvironmentValues {
    var safeAreaInsets: EdgeInsets {
        self[SafeAreaInsetsKey.self]
    }
}

private extension UIEdgeInsets {
    var swiftUIInsets: EdgeInsets {
        EdgeInsets(top: top, leading: left, bottom: bottom, trailing: right)
    }
}
