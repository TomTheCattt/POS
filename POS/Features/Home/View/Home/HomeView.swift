import SwiftUI

enum HomeTab: String, CaseIterable, Identifiable {
    case menu, history, inventory, analytics, settings
    
    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .menu:
            return "square.grid.2x2"
        case .history:
            return "clock.arrow.circlepath"
        case .inventory:
            return "cube.box.fill"
        case .analytics:
            return "chart.bar.fill"
        case .settings:
            return "gearshape.fill"
        }
    }

    var title: String {
        switch self {
        case .menu:
            return "Thực đơn"
        case .history:
            return "Lịch sử"
        case .inventory:
            return "Kho hàng"
        case .analytics:
            return "Thống kê"
        case .settings:
            return "Cài đặt"
        }
    }
    
    var color: Color {
        switch self {
        case .menu:
            return .blue
        case .history:
            return .orange
        case .inventory:
            return .green
        case .analytics:
            return .purple
        case .settings:
            return .gray
        }
    }
    
    var gradient: LinearGradient {
        switch self {
        case .menu:
            return LinearGradient(colors: [.blue, .blue.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .history:
            return LinearGradient(colors: [.orange, .orange.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .inventory:
            return LinearGradient(colors: [.green, .green.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .analytics:
            return LinearGradient(colors: [.purple, .purple.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .settings:
            return LinearGradient(colors: [.gray, .gray.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct HomeView: View {
    @State private var isMenuVisible: Bool = false
    @State private var selectedTab: HomeTab = HomeTab.allCases.first!
    @State private var dragOffset: CGFloat = 0
    @State private var isDragging: Bool = false
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    private let isIphone = UIDevice.current.userInterfaceIdiom == .phone
    private let hapticLight = UIImpactFeedbackGenerator(style: .light)
    private let hapticMedium = UIImpactFeedbackGenerator(style: .medium)
    private let hapticHeavy = UIImpactFeedbackGenerator(style: .heavy)
    
    var body: some View {
        GeometryReader { geometry in
            let sideMenuWidth = isIphone ? min(geometry.size.width * 0.85, 320) : geometry.size.width * 0.15
            
            if isIphone {
                ZStack(alignment: .leading) {
                    
                    VStack(spacing: 16) {
                        // Use either enhancedNavigationBar or compactNavigationBar
                        compactNavigationBar
                            .padding(.top, 8)
                            .background(Color.clear)
                        
                        contentView(for: selectedTab)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .scaleEffect(isMenuVisible ? 0.92 : 1.0)
                            .offset(x: isMenuVisible ? sideMenuWidth * 0.3 : 0)
                            .blur(radius: isMenuVisible ? 1.5 : 0)
                            .brightness(isMenuVisible ? -0.1 : 0)
                            .disabled(isMenuVisible)
                            .animation(.spring(response: 0.4, dampingFraction: 0.85, blendDuration: 0), value: isMenuVisible)
                            .padding(.top, 8)
                    }
                    .background(Color(.systemGray6))
                    .allowsHitTesting(!isMenuVisible)
                    .zIndex(3)
                    
                    if isMenuVisible {
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
                                closeMenuWithHaptic()
                            }
                    }
                    
                    enhancedSideMenuView(width: sideMenuWidth, geometry: geometry)
                        .zIndex(4)
                    
                    edgeSwipeDetector(geometry: geometry)
                        .zIndex(1)
                }
                .onChange(of: selectedTab) { _ in
                    if isMenuVisible {
                        closeMenuWithHaptic()
                    }
                }
            } else {
                HStack(spacing: 0) {
                    SideMenuView(selectedTab: $selectedTab, sideMenuWidth: sideMenuWidth, viewModel: viewModel)
                        .frame(width: sideMenuWidth)
                        .background(Color(.systemBackground))
                    
                    Divider()
                        .shadow(color: Color(.systemGray4).opacity(0.3), radius: 1, x: 1, y: 0)
                    
                    contentView(for: selectedTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
        .preferredColorScheme(colorScheme)
        .onAppear {
            setupHaptics()
        }
    }
    
    // MARK: - Enhanced Navigation Bar
    private var enhancedNavigationBar: some View {
        HStack(spacing: 0) {
            // Menu Button
            Button {
                openMenuWithHaptic()
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(.ultraThinMaterial)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 3)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    
                    // Animated menu icon
                    VStack(spacing: 2.5) {
                        ForEach(0..<3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 1)
                                .fill(selectedTab.color)
                                .frame(width: index == 1 ? 14 : 18, height: 2)
                                .animation(.easeInOut(duration: 0.2).delay(Double(index) * 0.04), value: selectedTab)
                        }
                    }
                }
                .scaleEffect(isDragging ? 1.05 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isDragging)
            }
            .opacity(isMenuVisible ? 0 : 1)
            .scaleEffect(isMenuVisible ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isMenuVisible)
            
            Spacer()
            
            // Center Title
            HStack(spacing: 8) {
                // Tab icon
                Image(systemName: selectedTab.icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundColor(selectedTab.color)
                    .scaleEffect(isMenuVisible ? 0.9 : 1.0)
                
                // Tab title
                Text(selectedTab.title)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                    .lineLimit(1)
                    .scaleEffect(isMenuVisible ? 0.9 : 1.0)
            }
            .opacity(isMenuVisible ? 0.6 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isMenuVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            
            Spacer()
            
            // Right side placeholder (44pt to match left button for symmetry)
            Rectangle()
                .fill(Color.clear)
                .frame(width: 44, height: 44)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(
            // Navigation bar background
            RoundedRectangle(cornerRadius: 20)
                .fill(.regularMaterial)
                .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
        .padding(.horizontal, 12)
    }

    // MARK: - Alternative Compact Navigation Bar (Optional)
    private var compactNavigationBar: some View {
        HStack(spacing: 12) {
            // Menu Button
            Button {
                openMenuWithHaptic()
            } label: {
                ZStack {
                    Circle()
                        .fill(.ultraThinMaterial)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                    
                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { index in
                            RoundedRectangle(cornerRadius: 0.5)
                                .fill(selectedTab.color)
                                .frame(width: index == 1 ? 12 : 16, height: 2)
                        }
                    }
                }
            }
            .opacity(isMenuVisible ? 0 : 1)
            .scaleEffect(isMenuVisible ? 0.8 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isMenuVisible)
            
            // Title with background
            HStack(spacing: 6) {
                Image(systemName: selectedTab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(selectedTab.color)
                
                Text(selectedTab.title)
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
                            .stroke(selectedTab.color.opacity(0.3), lineWidth: 1)
                    )
            )
            .opacity(isMenuVisible ? 0.6 : 1.0)
            .scaleEffect(isMenuVisible ? 0.95 : 1.0)
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: isMenuVisible)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedTab)
            
            Spacer()
        }
        .padding(.horizontal, 16)
    }
    
    // MARK: - Enhanced Side Menu
    private func enhancedSideMenuView(width: CGFloat, geometry: GeometryProxy) -> some View {
        ZStack(alignment: .topTrailing) {
            EnhancedSideMenuView(
                selectedTab: $selectedTab,
                sideMenuWidth: width,
                viewModel: viewModel,
                onTabSelected: { tab in
                    selectTabWithHaptic(tab)
                }
            )
            .frame(width: width)
        }
        .frame(width: width)
        .offset(x: isMenuVisible ? 0 : -width)
        .offset(x: dragOffset)
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isMenuVisible)
        .gesture(menuDragGesture(width: width))
        .frame(maxHeight: .infinity)
    }
    
    // MARK: - Edge Swipe Detector
    private func edgeSwipeDetector(geometry: GeometryProxy) -> some View {
        Rectangle()
            .fill(Color.clear)
            .frame(width: 20)
            .frame(maxHeight: .infinity)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let isFromLeftEdge = value.startLocation.x < 20
                        let isSwipingRight = value.translation.width > 0

                        if isFromLeftEdge && isSwipingRight {
                            dragOffset = value.translation.width

                            if !isDragging {
                                isDragging = true
                                hapticLight.impactOccurred()
                            }
                        }
                    }
                    .onEnded { value in
                        let isFromLeftEdge = value.startLocation.x < 20
                        let hasSufficientSwipe = value.translation.width > 50

                        if isFromLeftEdge && hasSufficientSwipe {
                            openMenuWithHaptic()
                        }

                        withAnimation(.easeOut(duration: 0.2)) {
                            isDragging = false
                            dragOffset = 0
                        }
                    }
            )
    }
    
    // MARK: - Menu Drag Gesture
    private func menuDragGesture(width: CGFloat) -> some Gesture {
        DragGesture()
            .onChanged { value in
                let translation = value.translation.width
                let isOpening = !isMenuVisible && translation > 0 && translation <= width
                let isClosing = isMenuVisible && translation < 0 && abs(translation) <= width

                if isOpening || isClosing {
                    dragOffset = translation

                    if !isDragging {
                        isDragging = true
                        hapticLight.impactOccurred()
                    }
                }
            }
            .onEnded { value in
                isDragging = false
                let translation = value.translation.width
                let velocity = value.velocity.width

                let shouldOpen = !isMenuVisible && (translation > width * 0.4 || velocity > 800)
                let shouldClose = isMenuVisible && (abs(translation) > width * 0.4 || velocity < -800)

                withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                    dragOffset = 0

                    if shouldOpen {
                        isMenuVisible = true
                        hapticMedium.impactOccurred()
                    } else if shouldClose {
                        isMenuVisible = false
                        hapticMedium.impactOccurred()
                    }
                }
            }
    }
    
    // MARK: - Haptic Functions
    private func setupHaptics() {
        hapticLight.prepare()
        hapticMedium.prepare()
        hapticHeavy.prepare()
    }
    
    private func openMenuWithHaptic() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isMenuVisible = true
        }
        hapticMedium.impactOccurred()
    }
    
    private func closeMenuWithHaptic() {
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            isMenuVisible = false
        }
        hapticLight.impactOccurred()
    }
    
    private func selectTabWithHaptic(_ tab: HomeTab) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            selectedTab = tab
        }
        hapticLight.impactOccurred()
    }
    
    @ViewBuilder
    private func contentView(for tab: HomeTab) -> some View {
        Group {
            switch tab {
            case .menu:
                appState.coordinator.makeView(for: .order)
            case .history:
                appState.coordinator.makeView(for: .ordersHistory)
            case .inventory:
                appState.coordinator.makeView(for: .inventory)
            case .analytics:
                appState.coordinator.makeView(for: .analytics)
            case .settings:
                appState.coordinator.makeView(for: .settings)
            }
        }
        .transition(.opacity)
    }
}

// MARK: - Enhanced Side Menu View
struct EnhancedSideMenuView: View {
    @Binding var selectedTab: HomeTab
    @State var sideMenuWidth: CGFloat
    @ObservedObject var viewModel: HomeViewModel
    let onTabSelected: (HomeTab) -> Void
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.safeAreaInsets) private var safeAreaInsets
    
    private let isIphone = UIDevice.current.userInterfaceIdiom == .phone
    
    var body: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            VStack(spacing: 12) {
                // App Icon with gradient background
                ZStack {
                    Circle()
                        .fill(selectedTab.gradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: selectedTab.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                .scaleEffect(1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedTab)
                
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
            .padding(.top, safeAreaInsets.top + 24)
            .padding(.bottom, 32)
            
            // Menu Items with enhanced design
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(HomeTab.allCases, id: \.self) { tab in
                        enhancedMenuButton(for: tab)
                    }
                }
                .padding(.top)
                .padding(.horizontal, 16)
            }
            
            Spacer()
            
            // Enhanced Divider
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [Color.clear, Color(.systemGray4).opacity(0.5), Color.clear],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .frame(height: 1)
                .padding(.horizontal, 16)
                .padding(.vertical, 20)
            
            // Enhanced Logout Button
            Button {
                Task {
                    await viewModel.signOut()
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
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.red.opacity(colorScheme == .dark ? 0.15 : 0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .padding(.horizontal, 16)
            .padding(.bottom, safeAreaInsets.bottom + 20)
        }
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.regularMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color.clear,
                            selectedTab.color.opacity(0.05)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .ignoresSafeArea()
                .shadow(color: Color.black.opacity(0.2), radius: 20, x: 5, y: 0)
                .frame(maxHeight: .infinity)
        )
        .frame(maxHeight: .infinity)
    }
    
    private func enhancedMenuButton(for tab: HomeTab) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            onTabSelected(tab)
        } label: {
            HStack(spacing: 16) {
                // Icon container with enhanced design
                ZStack {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(tab.gradient)
                            .frame(width: 44, height: 44)
                            .shadow(
                                color: tab.color.opacity(0.25),
                                radius: 6,
                                x: 0,
                                y: 4
                            )
                            .transition(.scale)
                    }

                    Image(systemName: tab.icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(isSelected ? .white : tab.color)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.clear)
                        )
                }
                .animation(.easeInOut(duration: 0.2), value: isSelected)
                
                // Title with enhanced typography
                VStack(alignment: .leading, spacing: 2) {
                    Text(tab.title)
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(isSelected ? .primary : .primary)
                    
                    if isSelected {
                        Text("Đang hoạt động")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(tab.color)
                    }
                }
                
                Spacer()
                
                // Selection indicator
                if isSelected {
                    Circle()
                        .fill(tab.color)
                        .frame(width: 6, height: 6)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isSelected ? tab.color.opacity(0.1) : Color.clear)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                isSelected ? tab.color.opacity(0.3) : Color.clear,
                                lineWidth: isSelected ? 1 : 0
                            )
                    )
            )
        }
        .buttonStyle(.plain)
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

// MARK: - Original SideMenuView for iPad
struct SideMenuView: View {
    @Binding var selectedTab: HomeTab
    @State var sideMenuWidth: CGFloat
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private let isIphone = UIDevice.current.userInterfaceIdiom == .phone
    
    var body: some View {
        VStack(spacing: 0) {
            // Logo/App Name
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(selectedTab.gradient)
                        .frame(width: 60, height: 60)
                        .shadow(color: selectedTab.color.opacity(0.3), radius: 8, x: 0, y: 4)
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white)
                }
                .scaleEffect(1.0)
                .animation(.spring(response: 0.5, dampingFraction: 0.7), value: selectedTab)
                
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
            .padding(.vertical, isIphone ? 20 : 30)
            
            // Menu Items
            ScrollView(showsIndicators: false) {
                VStack(spacing: isIphone ? 8 : 12) {
                    ForEach(HomeTab.allCases, id: \.self) { tab in
                        menuButton(for: tab)
                    }
                }
                .padding(.horizontal, 8)
            }
            
            Spacer()
            
            // Divider
            Rectangle()
                .fill(Color(.systemGray4).opacity(0.3))
                .frame(height: 1)
                .padding(.horizontal)
            
            // Logout Button
            Button {
                Task {
                    await viewModel.signOut()
                }
            } label: {
                HStack(spacing: 12) {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: isIphone ? 16 : 20))
                    Text("Đăng xuất")
                        .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                }
                .foregroundColor(.red)
                .frame(maxWidth: .infinity)
                .padding(.vertical, isIphone ? 12 : 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.red.opacity(colorScheme == .dark ? 0.2 : 0.1))
                )
            }
            .padding(.horizontal)
            .padding(.vertical, isIphone ? 16 : 20)
        }
    }
    
    private func menuButton(for tab: HomeTab) -> some View {
        let isSelected = selectedTab == tab
        
        return Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedTab = tab
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: tab.icon)
                    .font(.system(size: isIphone ? 16 : 20))
                    .foregroundColor(isSelected ? .white : tab.color)
                    .frame(width: isIphone ? 24 : 28)
                
                Text(tab.title)
                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : (colorScheme == .dark ? .white : .primary))
                
                Spacer()
            }
            .padding(.horizontal, isIphone ? 12 : 16)
            .padding(.vertical, isIphone ? 10 : 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? tab.color : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.clear : tab.color.opacity(colorScheme == .dark ? 0.4 : 0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
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
