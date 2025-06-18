import SwiftUI
import FirebaseFirestore

struct ShopManagementView: View {
    @ObservedObject private var viewModel: ShopManagementViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var showingSearchBar = false
    @State private var searchText = ""
    @State private var animateHeader = false
    
    var filteredShops: [Shop] {
        if searchText.isEmpty {
            return appState.sourceModel.shops ?? []
        }
        return (appState.sourceModel.shops ?? []).filter {
            $0.shopName.localizedCaseInsensitiveContains(searchText)
        }
    }
    
    init(viewModel: ShopManagementViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        Group {
            if let shops = appState.sourceModel.shops, shops.isEmpty {
                emptyStateView
            } else {
                mainContentView
            }
        }
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: isIphone ? 60 : 80))
                .foregroundStyle(appState.sourceModel.currentThemeColors.settings.gradient(for: colorScheme))
            
            VStack(spacing: 12) {
                Text("Chưa có cửa hàng nào")
                    .font(.system(size: isIphone ? 20 : 28, weight: .semibold))
                
                Text("Bạn hiện chưa có cửa hàng nào, tạo cửa hàng ngay để bắt đầu")
                    .font(.system(size: isIphone ? 16 : 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, isIphone ? 40 : 60)
            }
            
            Button {
                appState.coordinator.navigateTo(.addShop(nil), using: .present, with: .present)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: isIphone ? 18 : 20))
                    Text("Tạo cửa hàng mới")
                        .font(.system(size: isIphone ? 16 : 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: isIphone ? .infinity : 300)
                .padding(.vertical, isIphone ? 16 : 20)
                .background(appState.sourceModel.currentThemeColors.settings.gradient(for: colorScheme))
                .cornerRadius(16)
            }
            .padding(.horizontal, isIphone ? 40 : 60)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(spacing: 0) {
            // Enhanced Header
            headerSection
                .opacity(animateHeader ? 1 : 0)
                .offset(y: animateHeader ? 0 : -20)
            
            // Search Bar
            if showingSearchBar {
                EnhancedSearchBar(
                    text: $searchText,
                    placeholder: "Tìm kiếm cửa hàng..."
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
            
            // Shops List
            ScrollView(showsIndicators: false){
                LazyVStack(spacing: isIphone ? 16 : 20) {
                    ForEach(filteredShops) { shop in
                        Button {
                            appState.coordinator.navigateTo(.shopDetail(shop))
                        } label: {
                            appState.coordinator.makeView(for: .shopRow(shop))
                        }
                    }
                }
                .padding(.horizontal, isIphone ? 16 : 24)
                .padding(.bottom, 20)
            }
        }
        .background(appState.currentTabThemeColors.softGradient(for: colorScheme))
        .navigationTitle("Quản lý cửa hàng")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingSearchBar.toggle()
                        }
                    }) {
                        Image(systemName: showingSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                            .font(.system(size: isIphone ? 18 : 20))
                            .foregroundStyle(.primary)
                    }
                    
                    Button {
                        appState.coordinator.navigateTo(.addShop(nil), using: .present, with: .present)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: isIphone ? 18 : 20))
                            .foregroundStyle(appState.sourceModel.currentThemeColors.settings.gradient(for: colorScheme))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
        }
    }
    
    private var headerSection: some View {
            VStack(alignment: .leading, spacing:  isIphone ? 16 : 20) {
                HStack {
                    VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                        HStack {
                            Image(systemName: "building.2.fill")
                                .font(.title2)
                                .foregroundStyle(appState.sourceModel.currentThemeColors.settings.radialGradient(for: colorScheme))
                            
                            Text("\(filteredShops.count) cửa hàng")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Decorative divider
                HStack {
                    Rectangle()
                        .fill(appState.sourceModel.currentThemeColors.settings.radialGradient(for: colorScheme).opacity(0.6))
                        .frame(height: 2)
                        .frame(maxWidth: 100)
                    
                    Spacer()
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
}

struct ShopRow: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    @State private var isHovered = false
    
    let shop: Shop
    
    var body: some View {
        VStack(spacing: isIphone ? 20 : 24) {
            HStack(spacing: isIphone ? 16 : 20) {
                // Shop icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    shop.isActive ?
                                        appState.sourceModel.currentThemeColors.settings.primaryColor :
                                        Color.gray,
                                    shop.isActive ?
                                        appState.sourceModel.currentThemeColors.settings.secondaryColor :
                                        Color.gray.opacity(0.8)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: isIphone ? 56 : 64, height: isIphone ? 56 : 64)
                    
                    Image(systemName: "building.2.fill")
                        .font(.system(size: isIphone ? 24 : 28, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Shop info
                VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                    Text(shop.shopName)
                        .font(.system(size: isIphone ? 18 : 22, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    
                    VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                        // Ground Rent
                        HStack(spacing: 8) {
                            Image(systemName: "banknote.fill")
                                .font(.system(size: isIphone ? 12 : 14))
                                .foregroundColor(.secondary)
                            
                            Text(shop.formattedGroundRent)
                                .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        // Created Date
                        HStack(spacing: 8) {
                            Image(systemName: "calendar")
                                .font(.system(size: isIphone ? 12 : 14))
                                .foregroundColor(.secondary)
                            
                            Text("Tạo ngày \(formatDate(shop.createdAt))")
                                .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                        
                        // Business Hours
                        HStack(spacing: 8) {
                            Image(systemName: "clock")
                                .font(.system(size: isIphone ? 12 : 14))
                                .foregroundColor(.secondary)
                            
                            Text(shop.businessHours.businessHoursFormat)
                                .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: isIphone ? 8 : 12) {
                    // Status Badge
                    if shop.isActive {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            
                            Text("Đang hoạt động")
                                .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.1))
                        )
                    } else {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.gray)
                                .frame(width: 8, height: 8)
                            
                            Text("Tạm ngưng")
                                .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.gray.opacity(0.1))
                        )
                    }
                    
                    // Arrow indicator
                    Image(systemName: "chevron.right")
                        .font(.system(size: isIphone ? 14 : 16, weight: .semibold))
                        .foregroundStyle(.tertiary)
                        .opacity(isHovered ? 1 : 0.6)
                        .offset(x: isHovered ? 4 : 0)
                }
            }
        }
        .padding(.horizontal, isIphone ? 24 : 28)
        .padding(.vertical, isIphone ? 20 : 24)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
}

struct ShopDetailView: View {
    @ObservedObject private var viewModel: ShopManagementViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    private let shop: Shop
    
    @State private var animateHeader = false
    
    init(viewModel: ShopManagementViewModel, shop: Shop) {
        self.viewModel = viewModel
        self.shop = shop
    }
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: isIphone ? 24 : 32) {
                // Enhanced Header
                headerSection
                    .opacity(animateHeader ? 1 : 0)
                    .offset(y: animateHeader ? 0 : -20)
                
                // Quick Statistics
                if viewModel.isLoadingStatistics {
                    statisticsLoadingView
                } else {
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: isIphone ? 16 : 20) {
                        ForEach(viewModel.shopStatistics) { stat in
                            StatisticCard(item: stat)
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Shop Information
                shopInfoSection
                
                // Action Buttons
                actionButtonsSection
            }
            .padding(.vertical)
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        appState.coordinator.navigateTo(.addShop(shop), using: .present, with: .present)
                    } label: {
                        Label("Chỉnh sửa", systemImage: "pencil")
                    }
                    
                    Button(role: .destructive) {
                        appState.sourceModel.showAlert(
                            title: "Xoá cửa hàng",
                            message: "Bạn có chắc chắn muốn xóa cửa hàng này? Hành động này không thể hoàn tác.",
                            primaryButton: AlertButton(title: "Xoá", role: .destructive, action: {
                                Task {
                                    await viewModel.deleteShop(shop)
                                }
                            }),
                            secondaryButton: AlertButton(title: "Huỷ", role: .cancel)
                        )
                    } label: {
                        Label("Xóa cửa hàng", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                        .font(.system(size: isIphone ? 18 : 20))
                }
            }
        }
        .background(appState.currentTabThemeColors.softGradient(for: colorScheme))
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            viewModel.loadShopStatistics(for: shop)
        }
    }
    
    // MARK: - Statistics Loading View
    private var statisticsLoadingView: some View {
        LazyVGrid(columns: [
            GridItem(.flexible()),
            GridItem(.flexible())
        ], spacing: isIphone ? 16 : 20) {
            ForEach(0..<4, id: \.self) { _ in
                StatisticCard(item: StatisticItem(
                    title: "Đang tải...",
                    value: "...",
                    icon: "clock",
                    color: .gray
                ))
            }
        }
        .padding(.horizontal)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: isIphone ? 16 : 20) {
            HStack {
                VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: isIphone ? 20 : 24))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(shop.isActive ? "Đang hoạt động" : "Tạm ngưng")
                                .font(.system(size: isIphone ? 16 : 18, weight: .medium))
                                .foregroundColor(shop.isActive ? .green : .secondary)
                            
                            Text("Được tạo ngày \(formatDate(shop.createdAt))")
                                .font(.system(size: isIphone ? 14 : 16))
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                // Active Toggle Button
                Button {
                    Task {
                        await viewModel.toggleShopStatus(shop)
                    }
                } label: {
                    HStack(spacing: 8) {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(shop.isActive ? .green : .blue)
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: shop.isActive ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: isIphone ? 16 : 18))
                        }
                        Text(shop.isActive ? "Đang hoạt động" : "Kích hoạt")
                            .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(shop.isActive ? .green.opacity(0.1) : .blue.opacity(0.1))
                    )
                    .foregroundColor(shop.isActive ? .green : .blue)
                }
                .disabled(viewModel.isLoading)
            }
            
            // Decorative divider
            HStack {
                ModernDivider(tabThemeColors: appState.currentTabThemeColors)
                
                Spacer()
            }
        }
        .padding(.horizontal, isIphone ? 20 : 24)
        .padding(.vertical, isIphone ? 16 : 20)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .padding(.horizontal)
    }
    
    private var shopInfoSection: some View {
        VStack(spacing: isIphone ? 20 : 24) {
            InfoCard(title: "Thông tin cơ bản", items: [
                InfoItem(icon: "building.2", title: "Tên cửa hàng", value: shop.shopName),
                InfoItem(icon: "location", title: "Địa chỉ", value: shop.address),
                InfoItem(icon: "clock", title: "Giờ hoạt động", value: shop.businessHours.businessHoursFormat)
            ])
            
            InfoCard(title: "Thông tin tài chính", items: [
                InfoItem(icon: "banknote", title: "Chi phí mặt bằng", value: shop.formattedGroundRent)
            ])
        }
        .padding(.horizontal)
    }
    
    private var actionButtonsSection: some View {
        VStack(spacing: isIphone ? 16 : 20) {
            Button {
                print("tapped")
                appState.coordinator.navigateTo(.menuSection(shop))
            } label: {
                ActionButton(
                    title: "Quản lý thực đơn",
                    icon: "list.bullet.rectangle",
                    color: .blue
                )
            }
            
            Button {
                appState.coordinator.navigateTo(.staff(shop))
            } label: {
                ActionButton(
                    title: "Quản lý nhân viên",
                    icon: "person.2",
                    color: .purple
                )
            }
            
            Button {
                appState.coordinator.navigateTo(.revenue(shop))
            } label: {
                ActionButton(
                    title: "Thống kê doanh thu",
                    icon: "chart.bar",
                    color: .orange
                )
            }
        }
        .padding(.horizontal)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
}

// MARK: - Supporting Views
private struct StatisticCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    let item: StatisticItem
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: isIphone ? 16 : 20) {
            // Icon với gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                item.color.opacity(0.2),
                                item.color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isIphone ? 50 : 60, height: isIphone ? 50 : 60)
                
                Image(systemName: item.icon)
                    .font(.system(size: isIphone ? 24 : 28, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [item.color, item.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                Text(item.value)
                    .font(.system(size: isIphone ? 28 : 32, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [item.color, item.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(item.title)
                    .font(.system(size: isIphone ? 14 : 16))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            }
        }
        .padding(isIphone ? 20 : 24)
        .frame(maxWidth: .infinity, alignment: .leading)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct InfoItem: Equatable {
    let icon: String
    let title: String
    let value: String
}

private struct InfoCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    
    let title: String
    let items: [InfoItem]
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: isIphone ? 20 : 24) {
            // Header
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                appState.sourceModel.currentThemeColors.settings.primaryColor.opacity(0.2),
                                appState.sourceModel.currentThemeColors.settings.secondaryColor.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isIphone ? 40 : 48, height: isIphone ? 40 : 48)
                    .overlay(
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: isIphone ? 20 : 24, weight: .medium))
                            .foregroundStyle(
                                appState.sourceModel.currentThemeColors.settings.gradient(for: colorScheme)
                            )
                    )
                
                Text(title)
                    .font(.system(size: isIphone ? 18 : 22, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .primary,
                                .primary.opacity(0.8)
                            ],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
            }
            
            // Content
            VStack(spacing: isIphone ? 16 : 20) {
                ForEach(items, id: \.title) { item in
                    HStack(spacing: isIphone ? 16 : 20) {
                        // Icon
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [
                                            appState.sourceModel.currentThemeColors.settings.primaryColor.opacity(0.15),
                                            appState.sourceModel.currentThemeColors.settings.secondaryColor.opacity(0.1)
                                        ],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: isIphone ? 32 : 40, height: isIphone ? 32 : 40)
                            
                            Image(systemName: item.icon)
                                .font(.system(size: isIphone ? 14 : 16))
                                .foregroundStyle(
                                    appState.sourceModel.currentThemeColors.settings.gradient(for: colorScheme)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(item.value)
                                .font(.system(size: isIphone ? 16 : 18, weight: .semibold))
                                .foregroundColor(.primary)
                                .lineLimit(3)
                                .multilineTextAlignment(.leading)
                        }
                        
                        Spacer()
                    }
                    
                    if item != items.last {
                        Divider()
                            .background(
                                LinearGradient(
                                    colors: [
                                        appState.sourceModel.currentThemeColors.settings.primaryColor.opacity(0.2),
                                        .clear,
                                        appState.sourceModel.currentThemeColors.settings.secondaryColor.opacity(0.1)
                                    ],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
        }
        .padding(isIphone ? 24 : 28)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
        .scaleEffect(isHovered ? 1.01 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

private struct ActionButton: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    @State private var isHovered = false
    @State private var isPressed = false
    
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: isIphone ? 16 : 20) {
            // Icon với gradient background
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [
                                color.opacity(0.2),
                                color.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: isIphone ? 36 : 44, height: isIphone ? 36 : 44)
                
                Image(systemName: "\(icon).fill")
                    .font(.system(size: isIphone ? 16 : 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(title)
                .font(.system(size: isIphone ? 16 : 18, weight: .semibold))
                .foregroundColor(color)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: isIphone ? 14 : 16, weight: .semibold))
                .foregroundStyle(color.opacity(0.8))
                .opacity(isHovered ? 1 : 0.6)
                .offset(x: isHovered ? 4 : 0)
        }
        .padding(.horizontal, isIphone ? 20 : 24)
        .padding(.vertical, isIphone ? 16 : 20)
        .middleLayer(tabThemeColors: appState.currentTabThemeColors)
        .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
//        .onHover { hovering in
//            isHovered = hovering
//        }
//        .simultaneousGesture(
//            DragGesture(minimumDistance: 0)
//                .onChanged { _ in
//                    isPressed = true
//                }
//                .onEnded { _ in
//                    isPressed = false
//                }
//        )
    }
}
