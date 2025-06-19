//
//  UpdateMenuView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct MenuSectionView: View {
    @ObservedObject private var viewModel: MenuViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showingAddEditSheet = false
    @State private var selectedItem: MenuItem?
    @State private var selectedAction: ActionType?
    @State private var showingSearchBar = false
    @State private var animateHeader = false
    
    @State private var shop: Shop?
    
    private var softGradient: LinearGradient {
        appState.currentTabThemeColors.softGradient(for: colorScheme)
    }
    
    private var gradient: LinearGradient {
        appState.currentTabThemeColors.gradient(for: colorScheme)
    }
    
    private var textGradient: LinearGradient {
        appState.currentTabThemeColors.textGradient(for: colorScheme)
    }
    
    init(viewModel: MenuViewModel, shop: Shop?) {
        self.viewModel = viewModel
        self.shop = shop
    }
    
    var body: some View {
        Group {
            if let shops = appState.sourceModel.shops, shops.isEmpty {
                emptyStateView
            } else {
                mainContentView
            }
        }
        .background(softGradient)
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: isIphone ? 20 : 32) {
            Spacer()
            
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: isIphone ? 60 : 80))
                .foregroundStyle(gradient)
            
            VStack(spacing: isIphone ? 12 : 16) {
                Text("Chưa có cửa hàng nào")
                    .font(.system(size: isIphone ? 20 : 28, weight: .semibold))
                
                Text("Bạn cần tạo cửa hàng trước khi quản lý thực đơn")
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
                .background(gradient)
                .cornerRadius(16)
            }
            .padding(.horizontal, isIphone ? 40 : 60)
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Main Content View
    private var mainContentView: some View {
        VStack(spacing: isIphone ? 16 : 24) {
            // Enhanced Header
            headerSection
                .opacity(animateHeader ? 1 : 0)
                .offset(y: animateHeader ? 0 : -20)
            
            if viewModel.menuList.isEmpty {
                emptyMenuStateView
            } else {
                // Search Bar
                if showingSearchBar {
                    EnhancedSearchBar(
                        text: $searchText,
                        placeholder: "Tìm kiếm thực đơn..."
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Menu Grid
                ScrollView(showsIndicators: false){
                    LazyVStack(spacing: isIphone ? 16 : 20) {
                        ForEach(viewModel.menuList) { menu in
                            Button {
                                appState.coordinator.navigateTo(.menuDetail(menu))
                            } label: {
                                appState.coordinator.makeView(for: .menuRow(menu))
                            }
                        }
                    }
                    .padding(.horizontal, isIphone ? 16 : 24)
                    .padding(.bottom, 20)
                }
                
                // Bottom Toolbar
                bottomToolbar
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .edgesIgnoringSafeArea(.bottom)
                    )
            }
        }
        .navigationTitle("Quản lý thực đơn")
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
                        selectedItem = nil
                        appState.coordinator.navigateTo(.menuForm(nil), using: .present, with: .present)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: isIphone ? 18 : 20))
                            .foregroundStyle(gradient)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            Task {
                appState.sourceModel.setupMenuListListener(shopId: shop?.id ?? "")
            }
        }
        .onDisappear {
            Task {
                appState.sourceModel.removeMenuListListener(shopId: shop?.id ?? "")
            }
        }
    }
    
    // MARK: - Empty Menu State View
    private var emptyMenuStateView: some View {
        VStack(spacing: isIphone ? 20 : 32) {
            Spacer()
            
            Image(systemName: "menucard.fill")
                .font(.system(size: isIphone ? 60 : 80))
                .foregroundStyle(gradient)
            
            VStack(spacing: isIphone ? 12 : 16) {
                Text("Chưa có thực đơn nào")
                    .font(.system(size: isIphone ? 20 : 28, weight: .semibold))
                
                Text("Hãy tạo thực đơn đầu tiên cho cửa hàng của bạn")
                    .font(.system(size: isIphone ? 16 : 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, isIphone ? 40 : 60)
            }
            
            Button {
                selectedItem = nil
                appState.coordinator.navigateTo(.menuForm(nil), using: .present, with: .present)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: isIphone ? 18 : 20))
                    Text("Tạo thực đơn mới")
                        .font(.system(size: isIphone ? 16 : 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .frame(maxWidth: isIphone ? .infinity : 300)
                .padding(.vertical, isIphone ? 16 : 20)
                .background(gradient)
                .cornerRadius(16)
            }
            .padding(.horizontal, isIphone ? 40 : 60)
            
            Spacer()
        }
        .padding()
        .frame(maxHeight: .infinity)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: isIphone ? 16 : 20) {
            HStack {
                VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: isIphone ? 20 : 24))
                            .foregroundStyle(
                                appState.currentTabThemeColors.gradient(for: colorScheme)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(viewModel.filteredMenuItems.count) món ăn")
                                .font(.system(size: isIphone ? 16 : 18, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if !searchText.isEmpty {
                                Text("Kết quả tìm kiếm cho \"\(searchText)\"")
                                    .font(.system(size: isIphone ? 14 : 16))
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            
            // Decorative divider
            HStack {
                Rectangle()
                    .fill(
                        appState.currentTabThemeColors.softGradient(for: colorScheme)
                    )
                    .frame(height: 2)
                    .frame(maxWidth: isIphone ? 100 : 150)
                
                Spacer()
            }
        }
        .padding(.horizontal, isIphone ? 20 : 24)
        .padding(.vertical, isIphone ? 16 : 20)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .padding(.horizontal)
    }
    
    private var bottomToolbar: some View {
        HStack(spacing: isIphone ? 16 : 20) {
            Menu {
                Button(action: { selectedAction = .import }) {
                    Label("Nhập từ Excel/CSV", systemImage: "square.and.arrow.down")
                        .foregroundColor(.primary)
                }
                
                Button(action: { selectedAction = .export }) {
                    Label("Xuất dữ liệu", systemImage: "square.and.arrow.up")
                        .foregroundColor(.primary)
                }
                
                Button(action: { selectedAction = .history }) {
                    Label("Lịch sử thay đổi", systemImage: "clock.arrow.circlepath")
                        .foregroundColor(.primary)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: isIphone ? 16 : 18))
                    Text("Thao tác")
                        .font(.system(size: isIphone ? 16 : 18, weight: .semibold))
                }
                .foregroundStyle(appState.currentTabThemeColors.softGradient(for: colorScheme))
                .padding(.horizontal, isIphone ? 16 : 20)
                .padding(.vertical, isIphone ? 8 : 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
            }
            
            Spacer()
            
            Button(action: {
                selectedItem = nil
                appState.coordinator.navigateTo(.menuForm(nil), using: .present, with: .present)
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: isIphone ? 16 : 18))
                    Text("Thêm thực đơn mới")
                        .font(.system(size: isIphone ? 16 : 18, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, isIphone ? 16 : 20)
                .padding(.vertical, isIphone ? 8 : 12)
                .background(appState.currentTabThemeColors.gradient(for: colorScheme))
                .clipShape(Capsule())
            }
        }
        .padding(.horizontal, isIphone ? 16 : 24)
        .padding(.vertical, isIphone ? 12 : 16)
    }
}

// MARK: - Supporting Views

struct MenuFormView: View {
    @State private var menuName = ""
    @State private var description = ""
    
    @ObservedObject var viewModel: MenuViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    @State var menu: AppMenu?
    
    private var isFormValid: Bool {
        !menuName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false){
                VStack(spacing: isIphone ? 24 : 32) {
                    // Header với icon
                    headerSection
                    
                    // Form inputs
                    formSection
                    
                    // Action button
                    actionButton
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, isIphone ? 20 : 24)
                .padding(.top, 10)
            }
            .background(
                LinearGradient(
                    colors: [Color(.systemBackground), Color(.systemGroupedBackground)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .navigationTitle(menu == nil ? "Thêm Thực Đơn" : "Cập Nhật Thực Đơn")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        appState.coordinator.dismiss()
                    }
                    .foregroundColor(.secondary)
                }
            }
        }
        .onAppear {
            setupInitialData()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: isIphone ? 12 : 16) {
            Image(systemName: menu == nil ? "plus.circle.fill" : "pencil.circle.fill")
                .font(.system(size: isIphone ? 50 : 60))
                .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
            
            Text(menu == nil ? "Tạo thực đơn mới" : "Chỉnh sửa thực đơn")
                .font(.system(size: isIphone ? 20 : 24, weight: .semibold))
                .foregroundColor(.primary)
            
            Text("Điền thông tin để " + (menu == nil ? "tạo" : "cập nhật") + " thực đơn của bạn")
                .font(.system(size: isIphone ? 16 : 18))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: isIphone ? 20 : 24) {
            // Menu name input
            VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                Label("Tên thực đơn", systemImage: "doc.text")
                    .font(.system(size: isIphone ? 18 : 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextField("Nhập tên thực đơn...", text: $menuName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocorrectionDisabled()
            }
            
            // Description input
            VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                Label("Mô tả", systemImage: "text.alignleft")
                    .font(.system(size: isIphone ? 18 : 20, weight: .semibold))
                    .foregroundColor(.primary)
                
                TextField("Mô tả chi tiết về thực đơn (tùy chọn)", text: $description, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle(minHeight: isIphone ? 80 : 100))
                    .lineLimit(3...6)
                    .autocorrectionDisabled()
            }
        }
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button(action: {
            Task {
                do {
                    await handleSubmit()
                }
            }
        }) {
            HStack(spacing: 12) {
                if appState.sourceModel.isLoading {
                    ProgressView()
                        .scaleEffect(0.9)
                        .tint(.white)
                } else {
                    Image(systemName: menu == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                        .font(.system(size: isIphone ? 18 : 20, weight: .semibold))
                }
                
                Text(menu == nil ? "Tạo Thực Đơn" : "Lưu Thay Đổi")
                    .font(.system(size: isIphone ? 18 : 20, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: isIphone ? 56 : 64)
            .background(
                LinearGradient(
                    colors: isFormValid ? [appState.currentTabThemeColors.primaryColor, appState.currentTabThemeColors.secondaryColor] : [.gray.opacity(0.5), .gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .scaleEffect(isFormValid ? 1.0 : 0.98)
            .animation(.easeInOut(duration: 0.2), value: isFormValid)
        }
        .disabled(!isFormValid || appState.sourceModel.isLoading)
        .padding(.horizontal, 4)
    }
    
    // MARK: - Helper Functions
    private func setupInitialData() {
        if let menu = menu {
            menuName = menu.menuName
            description = menu.description ?? ""
        }
    }
    
    private func handleSubmit() async {
        guard isFormValid else { return }
        guard let activatedShop = appState.sourceModel.activatedShop, let shopId = activatedShop.id else {
            appState.sourceModel.showError(AppError.shop(.notFound).localizedDescription)
            return
        }
        do {
            try await appState.sourceModel.withLoading {
                if let menu = menu {
                    // Update existing menu
                    var updatedMenu = menu
                    updatedMenu.menuName = menuName.trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedMenu.description = description.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : description.trimmingCharacters(in: .whitespacesAndNewlines)
                    updatedMenu.updatedAt = Date()
                    
                    try await viewModel.updateMenu(updatedMenu)
                    appState.sourceModel.showSuccess("Cập nhật thực đơn thành công!")
                    appState.coordinator.dismiss(style: .present)
                } else {
                    // Create new menu
                    var newMenu = AppMenu(
                        shopId: shopId,
                        menuName: menuName.trimmingCharacters(in: .whitespacesAndNewlines),
                        isActive: viewModel.menuList.isEmpty,
                        createdAt: Date(),
                        updatedAt: Date()
                    )
                    
                    let trimmedDescription = description.trimmingCharacters(in: .whitespacesAndNewlines)
                    if !trimmedDescription.isEmpty {
                        newMenu.description = trimmedDescription
                    }
                    
                    try await viewModel.createNewMenu(newMenu)
                    appState.sourceModel.showSuccess("Tạo thực đơn thành công!")
                    appState.coordinator.dismiss(style: .present)
                }
            }
        } catch {
            appState.sourceModel.showError(error.localizedDescription)
        }
    }
}

struct MenuRow: View {
    @State private var menu: AppMenu
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    init(menu: AppMenu) {
        self.menu = menu
    }
    
    var body: some View {
        HStack(spacing: isIphone ? 16 : 20) {
            // Icon section với gradient background
            iconSection
            
            // Content section
            contentSection
            
            Spacer()
            
            // Active status
            if menu.isActive {
                activeStatusBadge
            }
            
            // Arrow indicator
            arrowIndicator
        }
        .padding(.horizontal, isIphone ? 20 : 24)
        .padding(.vertical, isIphone ? 16 : 20)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .cornerRadius(16)
    }
    
    // MARK: - Icon Section
    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: menu.isActive ?
                        [appState.currentTabThemeColors.primaryColor.opacity(0.5), appState.currentTabThemeColors.secondaryColor.opacity(0.3)] :
                            [.gray.opacity(0.5), .gray.opacity(0.3)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: isIphone ? 50 : 60, height: isIphone ? 50 : 60)
            
            Image(systemName: "menucard.fill")
                .font(.system(size: isIphone ? 22 : 26, weight: .medium))
                .foregroundColor(.white)
        }
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: isIphone ? 6 : 8) {
            // Menu name
            Text(menu.menuName)
                .font(.system(size: isIphone ? 17 : 20, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Description
            if let description = menu.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: isIphone ? 14 : 16, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            } else {
                Text("Chưa có mô tả")
                    .font(.system(size: isIphone ? 14 : 16, weight: .regular))
                    .foregroundStyle(.tertiary)
                    .italic()
            }
            
            // Metadata section
            metadataSection
        }
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        HStack(spacing: isIphone ? 8 : 12) {
            // Created date
            Label(formatDate(menu.createdAt), systemImage: "calendar")
                .font(.system(size: isIphone ? 12 : 14))
                .foregroundColor(.secondary)
            
            // Updated indicator: chỉ hiển thị nếu lệch nhau từ 5 giây trở lên
            if abs(menu.updatedAt.timeIntervalSince(menu.createdAt)) >= 5 {
                Label("Đã cập nhật", systemImage: "pencil")
                    .font(.system(size: isIphone ? 12 : 14))
                    .foregroundColor(.orange)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Arrow Indicator
    private var arrowIndicator: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: isIphone ? 14 : 16, weight: .semibold))
            .foregroundStyle(appState.currentTabThemeColors.primaryColor)
    }
    
    private var activeStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
            
            Text("Đang hoạt động")
                .font(.system(size: isIphone ? 12 : 14, weight: .medium))
                .foregroundColor(.green)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(.green.opacity(0.1))
        )
    }
    
    // MARK: - Helper Functions
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.locale = Locale(identifier: "vi_VN")
        return formatter.string(from: date)
    }
}

struct MenuDetailView: View {
    @ObservedObject private var viewModel: MenuViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var selectedItem: MenuItem?
    @State private var searchText = ""
    @State private var selectedCategory: String? = "All"
    @State private var showingSearchBar = false
    @State private var animateHeader = false
    @State private var isPressed = false
    @State private var hasAppeared = false
    @Namespace private var animation
    
    @State private var currentMenu: AppMenu
    
    init(viewModel: MenuViewModel, currentMenu: AppMenu) {
        self.viewModel = viewModel
        self.currentMenu = currentMenu
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: isIphone ? 180 : 220), spacing: isIphone ? 20 : 24)
    ]
    
    var filteredItems: [MenuItem] {
        var items = viewModel.menuItems
        
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if let category = selectedCategory, category != "All" {
            items = items.filter { $0.category == category }
        }
        
        return items
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                VStack(spacing: 0) {
                    // Enhanced Header
                    enhancedHeaderSection
                        .opacity(animateHeader ? 1 : 0)
                        .offset(y: animateHeader ? 0 : -20)
                    
                    // Menu Status Section
                    menuStatusSection
                        .padding(.horizontal)
                        .padding(.vertical, isIphone ? 12 : 16)
                    
                    // Search & Filter Section
                    searchAndFilterSection
                        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
                        .padding(.horizontal)
                        .padding(.bottom, isIphone ? 16 : 20)
                    
                    // Menu Items Grid
                    ScrollView(showsIndicators: false){
                        LazyVGrid(columns: columns, spacing: isIphone ? 24 : 32) {
                            ForEach(Array(filteredItems.enumerated()), id: \.element.id) { _, menuItem in
                                Button {
                                    if !viewModel.isSelectionMode {
                                        appState.coordinator.navigateTo(.menuItemForm(currentMenu, menuItem), using: .present, with: .present)
                                    } else {
                                        if viewModel.selectedItems.contains(menuItem) {
                                            viewModel.selectedItems.remove(menuItem)
                                        } else {
                                            viewModel.selectedItems.insert(menuItem)
                                        }
                                    }
                                } label: {
                                    appState.coordinator.makeView(for: .menuItemCard(menuItem))
                                        .padding(isIphone ? 16 : 20)
                                        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .onReceive(
                                    Timer.publish(every: 0.1, on: .main, in: .common).autoconnect()
                                        .prefix(1)
                                ) { _ in
                                    withAnimation(
                                        .easeOut(duration: 0.6)
                                    ) {
                                        hasAppeared = true
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, isIphone ? 16 : 24)
                        .padding(.bottom, 20)
                    }
                }
            }
        }
        .background(appState.currentTabThemeColors.softGradient(for: colorScheme))
        .navigationTitle(currentMenu.menuName)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                if viewModel.isSelectionMode {
                    Button {
                        withAnimation {
                            viewModel.isSelectionMode = false
                            viewModel.selectedItems.removeAll()
                        }
                    } label: {
                        Text("Hủy")
                            .foregroundColor(.red)
                    }
                    
                    if !viewModel.selectedItems.isEmpty {
                        Button {
                            appState.sourceModel.showAlert(
                                title: "Xoá món",
                                message: "Bạn có chắc chắn muốn xoá \(viewModel.selectedItems.count == 1 ? "" : "những") món này không? Thao tác này không thể hoàn tác",
                                primaryButton: AlertButton(title: "Xoá", role: .destructive, action: {
                                    Task {
                                        do {
                                            try await viewModel.deleteMenuItems(viewModel.selectedItems, in: currentMenu)
                                        } catch {
                                            appState.sourceModel.handleError(error)
                                        }
                                    }
                                }))
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                } else {
                    Button(action: {
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                            showingSearchBar.toggle()
                        }
                    }) {
                        Image(systemName: showingSearchBar ? "xmark.circle.fill" : "magnifyingglass")
                            .font(.system(size: isIphone ? 18 : 20))
                            .foregroundStyle(.primary)
                    }
                    
                    Menu {
                        Button {
                            withAnimation {
                                viewModel.isSelectionMode = true
                            }
                        } label: {
                            Label("Chọn nhiều", systemImage: "checkmark.circle")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .font(.system(size: isIphone ? 18 : 20))
                    }
                    
                    Button {
                        selectedItem = nil
                        appState.coordinator.navigateTo(.menuItemForm(currentMenu, selectedItem), using: .present, with: .present)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: isIphone ? 18 : 20))
                            Text("Thêm")
                                .font(.system(size: isIphone ? 14 : 16, weight: .semibold))
                        }
                        .foregroundStyle(appState.currentTabThemeColors.textColor(for: colorScheme))
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            appState.sourceModel.setupMenuItemsListener(shopId: appState.sourceModel.activatedShop?.id ?? "", menuId: currentMenu.id)
        }
        .onDisappear {
            appState.sourceModel.removeMenuItemsListener(shopId: appState.sourceModel.activatedShop?.id ?? "", menuId: currentMenu.id)
        }
    }
    
    private var menuStatusSection: some View {
        VStack(spacing: isIphone ? 16 : 20) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trạng thái thực đơn")
                        .font(.system(size: isIphone ? 18 : 20, weight: .semibold))
                    Text("Chọn thực đơn này để sử dụng trong cửa hàng")
                        .font(.system(size: isIphone ? 14 : 16))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Active Toggle Button
                Button {
                    Task {
                        if currentMenu.isActive {
                            await viewModel.deActivateMenu(currentMenu)
                            currentMenu.toggleActive()
                        } else {
                            await viewModel.activateMenu(currentMenu)
                            currentMenu.toggleActive()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: currentMenu.isActive ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: isIphone ? 16 : 18))
                        Text(currentMenu.isActive ? "Đang sử dụng" : "Chọn sử dụng")
                            .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(currentMenu.isActive ? .green.opacity(0.1) : .blue.opacity(0.1))
                    )
                    .foregroundColor(currentMenu.isActive ? .green : .blue)
                }
            }
            
            Divider()
        }
    }
    
    private var enhancedHeaderSection: some View {
        VStack(alignment: .leading, spacing: isIphone ? 16 : 20) {
            HStack {
                VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.system(size: isIphone ? 20 : 24))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(filteredItems.count) món")
                                .font(.system(size: isIphone ? 16 : 18, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if !searchText.isEmpty {
                                Text("Kết quả tìm kiếm cho \"\(searchText)\"")
                                    .font(.system(size: isIphone ? 14 : 16))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.system(size: isIphone ? 18 : 20))
                            Text("Chỉnh sửa")
                                .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                        }
                        .foregroundStyle(.primary)
                        .padding(4)
                        .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
                            appState.coordinator.navigateTo(.menuForm(currentMenu), using: .present, with: .present)
                        }
                    }
                    
                    if let description = currentMenu.description {
                        Text(description)
                            .font(.system(size: isIphone ? 14 : 16))
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            
            // Decorative divider
            ModernDivider(tabThemeColors: appState.currentTabThemeColors)
        }
        .padding(.horizontal, isIphone ? 20 : 24)
        .padding(.vertical, isIphone ? 16 : 20)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .padding(.horizontal)
        .padding(.bottom, isIphone ? 16 : 20)
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: isIphone ? 16 : 20) {
            // Animated search bar
            if showingSearchBar {
                EnhancedSearchBar(text: $searchText, placeholder: "Tìm kiếm món ăn...")
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
            }
            
            // Category filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isIphone ? 12 : 16) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        enhancedCategoryButton(category)
                    }
                }
                .padding(.horizontal, isIphone ? 20 : 24)
            }
        }
        .padding(.vertical, isIphone ? 16 : 20)
    }
    
    private func enhancedCategoryButton(_ category: String) -> some View {
        Group {
            let isSelected = selectedCategory == category
            let title = category
            let icon = category == "All" ? "square.grid.2x2.fill" : getCategoryIcon(category)
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                
                Text(title)
                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
            }
            .padding(.horizontal, isIphone ? 12 : 16)
            .padding(.vertical, isIphone ? 8 : 12)
            .layeredSelectionButton(tabThemeColors: appState.currentTabThemeColors, isSelected: isSelected, namespace: animation, geometryID: "MenuSectionSelector") {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                    selectedCategory = isSelected ? nil : category
                }
            }
        }
    }
    
    private func getCategoryIcon(_ category: String) -> String {
        let input = category.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        
        if let matched = SuggestedCategories.allCases.first(where: {
            $0.name.lowercased() == input || $0.rawValue.lowercased() == input
        }) {
            return matched.icon
        }
        
        return "square.grid.2x2"
    }
}

// Enhanced Search Bar Component
struct EnhancedSearchBar: View {
    @Binding var text: String
    let placeholder: String
    @FocusState private var isFocused: Bool
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: isIphone ? 16 : 18, weight: .medium))
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(CustomTextFieldStyle())
                .font(.system(size: isIphone ? 14 : 16))
                .keyboardType(.default)
            
            if !text.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: isIphone ? 16 : 18))
                }
            }
        }
        .padding(.horizontal, isIphone ? 16 : 20)
        .padding(.vertical, isIphone ? 12 : 16)
        .background(
            ZStack {
                // Nền xám nhạt
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                
                // Viền gradient nếu isFocused
                if isFocused {
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(appState.currentTabThemeColors.gradient(for: colorScheme), lineWidth: 2)
                }
            }
        )
        .onAppear {
            isFocused = true
        }
    }
}

// Enhanced Menu Item Card
struct EnhancedMenuItemCard: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: MenuViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var item: MenuItem
    
    init(viewModel: MenuViewModel, item: MenuItem) {
        self.viewModel = viewModel
        self.item = item
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: isIphone ? 12 : 16) {
            ZStack(alignment: .topTrailing) {
                // Image placeholder with gradient
                RoundedRectangle(cornerRadius: 12)
                    .fill(appState.currentTabThemeColors.softGradient(for: colorScheme))
                    .frame(height: isIphone ? 120 : 140)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.system(size: isIphone ? 24 : 28))
                            .foregroundColor(.white)
                    )
                
                if viewModel.isSelectionMode {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: isIphone ? 24 : 28, height: isIphone ? 24 : 28)
                        
                        Image(systemName: viewModel.selectedItems.contains(where: {$0 == item}) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: isIphone ? 22 : 26))
                            .foregroundColor(viewModel.selectedItems.contains(where: {$0 == item}) ? .blue : .gray)
                    }
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: isIphone ? 8 : 12) {
                Text(item.name)
                    .font(.system(size: isIphone ? 18 : 20, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.system(size: isIphone ? 12 : 14))
                        .foregroundColor(.secondary)
                    Text(item.category)
                        .font(.system(size: isIphone ? 12 : 14))
                        .foregroundColor(.secondary)
                }
                
                HStack {
                    Spacer()
                    Text("\(item.price, specifier: "%.0f")đ")
                        .font(.system(size: isIphone ? 16 : 18, weight: .bold))
                        .foregroundStyle(appState.currentTabThemeColors.textGradient(for: colorScheme))
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Recipe Item Row
struct RecipeItemRow: View {
    let recipe: Recipe
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.ingredientName)
                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                
                Text("Số lượng: \(recipe.requiredAmount.displayString)")
                    .font(.system(size: isIphone ? 12 : 14))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: isIphone ? 20 : 24))
            }
        }
        .padding(isIphone ? 12 : 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}
