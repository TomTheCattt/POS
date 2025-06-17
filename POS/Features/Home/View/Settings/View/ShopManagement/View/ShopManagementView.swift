import SwiftUI

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
                VStack(spacing: 20) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(appState.sourceModel.currentThemeColors.settings.gradient(for: colorScheme))
                    
                    Text("Chưa có cửa hàng nào")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Bạn hiện chưa có cửa hàng nào, tạo cửa hàng ngay")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Button {
                        appState.coordinator.navigateTo(.addShop(nil), using: .present, with: .present)
                    } label: {
                        Label("Tạo cửa hàng mới", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(appState.sourceModel.currentThemeColors.settings.gradient(for: colorScheme))
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                }
                .padding()
            } else {
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
                        .padding()
                    }
                    
                    // Shops List
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredShops) { shop in
                                Button {
                                    appState.coordinator.navigateTo(.shopDetail(shop))
                                } label: {
                                    appState.coordinator.makeView(for: .shopRow(shop))
                                }
                            }
                        }
                        .padding()
                    }
                }
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
                                    .font(.title2)
                                    .foregroundStyle(.primary)
                            }
                            
                            Button {
                                appState.coordinator.navigateTo(.addShop(nil), using: .present, with: .present)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
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
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
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
        VStack(spacing: 20) {
            HStack(spacing: 16) {
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
                        .frame(width: 56, height: 56)
                        //.shadow(
//                            color: (shop.isActive ?
//                                   appState.sourceModel.currentThemeColors.settings.primaryColor :
//                                    Color.gray).opacity(0.3),
//                            radius: isHovered ? 8 : 6,
//                            x: 0,
//                            y: isHovered ? 4 : 3
//                        )
                    
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.white)
                }
                
                // Shop info
                VStack(alignment: .leading, spacing: 8) {
                    Text(shop.shopName)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.primary, .primary.opacity(0.8)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    
                    HStack(spacing: 16) {
                        // Ground Rent
                        Label {
                            Text(shop.formattedGroundRent)
                                .font(.system(size: 14, weight: .medium))
                        } icon: {
                            Image(systemName: "banknote.fill")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                        
                        // Created Date
                        Label {
                            Text(formatDate(shop.createdAt))
                                .font(.system(size: 14, weight: .medium))
                        } icon: {
                            Image(systemName: "calendar")
                                .font(.system(size: 12))
                        }
                        .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                // Status Badge
                if shop.isActive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        
                        Text("Đang hoạt động")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.green)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.1))
                    )
                }
                
                // Arrow indicator
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.tertiary)
                    .opacity(isHovered ? 1 : 0.6)
                    .offset(x: isHovered ? 4 : 0)
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 20)
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
    
    private let shop: Shop
    
    @State private var animateHeader = false
    
    init(viewModel: ShopManagementViewModel, shop: Shop) {
        self.viewModel = viewModel
        self.shop = shop
    }
    
    // Mock data cho thống kê (sau này sẽ được thay thế bằng dữ liệu thật)
    private let statistics = [
        StatisticItem(title: "Đơn hàng", value: "156", icon: "cart.fill", color: .blue),
        StatisticItem(title: "Doanh thu hôm nay", value: "2.5M", icon: "banknote.fill", color: .green),
        StatisticItem(title: "Nhân viên", value: "8", icon: "person.2.fill", color: .purple),
        StatisticItem(title: "Thực đơn", value: "45", icon: "fork.knife", color: .orange)
    ]
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Enhanced Header
                headerSection
                    .opacity(animateHeader ? 1 : 0)
                    .offset(y: animateHeader ? 0 : -20)
                
                // Quick Statistics
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(statistics) { stat in
                        StatisticCard(item: stat)
                    }
                }
                .padding(.horizontal)
                
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
                        .font(.title2)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "building.2.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(shop.isActive ? "Đang hoạt động" : "Tạm ngưng")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(shop.isActive ? .green : .secondary)
                    }
                    
                    Text("Được tạo ngày \(formatDate(shop.createdAt))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Active Toggle Button
                Button {
                    Task {
                        
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: shop.isActive ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                        Text(shop.isActive ? "Đang hoạt động" : "Kích hoạt")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(shop.isActive ? .green.opacity(0.1) : .blue.opacity(0.1))
                    )
                    .foregroundColor(shop.isActive ? .green : .blue)
                }
            }
            
            // Decorative divider
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.orange.opacity(0.6), .red.opacity(0.6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(height: 2)
                    .frame(maxWidth: 100)
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                //.shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
    
    private var shopInfoSection: some View {
        VStack(spacing: 20) {
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
        VStack(spacing: 16) {
            Button {
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
private struct StatisticItem: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let icon: String
    let color: Color
}

private struct StatisticCard: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var appState: AppState
    let item: StatisticItem
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
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
                    .frame(width: 50, height: 50)
                
                Image(systemName: item.icon)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [item.color, item.color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.value)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [item.color, item.color.opacity(0.8)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Text(item.title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(20)
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
        VStack(alignment: .leading, spacing: 20) {
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
                    .frame(width: 40, height: 40)
                    .overlay(
                        Image(systemName: "info.circle.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(
                                appState.sourceModel.currentThemeColors.settings.gradient(for: colorScheme)
                            )
                    )
                
                Text(title)
                    .font(.system(size: 18, weight: .bold))
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
            VStack(spacing: 16) {
                ForEach(items, id: \.title) { item in
                    HStack(spacing: 16) {
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
                                .frame(width: 32, height: 32)
                            
                            Image(systemName: item.icon)
                                .font(.system(size: 14))
                                .foregroundStyle(
                                    appState.sourceModel.currentThemeColors.settings.gradient(for: colorScheme)
                                )
                        }
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(item.title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            Text(item.value)
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.primary)
                        }
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
        .padding(24)
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
        HStack(spacing: 16) {
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
                    .frame(width: 36, height: 36)
                
                Image(systemName: "\(icon).fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color, color.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            Text(title)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(color.opacity(0.8))
                .opacity(isHovered ? 1 : 0.6)
                .offset(x: isHovered ? 4 : 0)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .middleLayer(tabThemeColors: appState.currentTabThemeColors)
        .scaleEffect(isPressed ? 0.98 : (isHovered ? 1.02 : 1.0))
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .animation(.spring(response: 0.2, dampingFraction: 0.5), value: isPressed)
        .onHover { hovering in
            isHovered = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    isPressed = true
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
    }
}
