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
    
    private var shop: Shop?
    
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
                VStack(spacing: 20) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(gradient)
                    
                    Text("Chưa có cửa hàng nào")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Bạn cần tạo cửa hàng trước khi quản lý thực đơn")
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
                            .background(gradient)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                    }
                    .padding(.horizontal, 40)
                    .padding(.top, 10)
                }
                .padding()
            } else {
                VStack(spacing: 16) {
                    // Enhanced Header
                    headerSection
                        .opacity(animateHeader ? 1 : 0)
                        .offset(y: animateHeader ? 0 : -20)
                    
                    if viewModel.menuList.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "menucard.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(gradient)
                            
                            Text("Chưa có thực đơn nào")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Hãy tạo thực đơn đầu tiên cho cửa hàng của bạn")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            Button {
                                selectedItem = nil
                                appState.coordinator.navigateTo(.menuForm(nil), using: .present, with: .present)
                            } label: {
                                Label("Tạo thực đơn mới", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(gradient)
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 10)
                        }
                        .padding()
                        .frame(maxHeight: .infinity)
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
                            .padding()
                        }
                        
                        // Menu Grid
                        ScrollView {
                            VStack(spacing: 16) {
                                ForEach(viewModel.menuList) { menu in
                                    Button {
                                        appState.coordinator.navigateTo(.menuDetail(menu))
                                    } label: {
                                        appState.coordinator.makeView(for: .menuRow(menu))
                                    }
                                }
                            }
                            .padding()
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
                                    .font(.title2)
                                    .foregroundStyle(.primary)
                            }
                            
                            Button {
                                selectedItem = nil
                                appState.coordinator.navigateTo(.menuForm(nil), using: .present, with: .present)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
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
        }
        .background(softGradient)
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                appState.currentTabThemeColors.gradient(for: colorScheme)
                            )
                        
                        Text("\(viewModel.filteredMenuItems.count) món ăn")
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
                    .fill(
                        appState.currentTabThemeColors.softGradient(for: colorScheme)
                    )
                    .frame(height: 2)
                    .frame(maxWidth: 100)
                
                Spacer()
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .padding(.horizontal)
    }
    
    private var bottomToolbar: some View {
        HStack {
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
                HStack {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.title3)
                    Text("Thao tác")
                        .font(.headline)
                }
                .foregroundStyle(appState.currentTabThemeColors.softGradient(for: colorScheme))
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                        //.shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
                )
            }
            
            Spacer()
            
            Button(action: {
                selectedItem = nil
                appState.coordinator.navigateTo(.menuForm(nil), using: .present, with: .present)
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                    Text("Thêm thực đơn mới")
                        .font(.headline)
                }
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(appState.currentTabThemeColors.gradient(for: colorScheme))
                .clipShape(Capsule())
                //.shadow(color: .blue.opacity(0.3), radius: 5, x: 0, y: 2)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
    }
}

// MARK: - Supporting Views

struct MenuFormView: View {
    @State private var menuName = ""
    @State private var description = ""
    
    @ObservedObject var viewModel: MenuViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    let menu: AppMenu?
    
    private var isFormValid: Bool {
        !menuName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header với icon
                    headerSection
                    
                    // Form inputs
                    formSection
                    
                    // Action button
                    actionButton
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
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
        VStack(spacing: 12) {
            Image(systemName: menu == nil ? "plus.circle.fill" : "pencil.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
            
            Text(menu == nil ? "Tạo thực đơn mới" : "Chỉnh sửa thực đơn")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text("Điền thông tin để " + (menu == nil ? "tạo" : "cập nhật") + " thực đơn của bạn")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 10)
    }
    
    // MARK: - Form Section
    private var formSection: some View {
        VStack(spacing: 20) {
            // Menu name input
            VStack(alignment: .leading, spacing: 8) {
                Label("Tên thực đơn", systemImage: "doc.text")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Nhập tên thực đơn...", text: $menuName)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocorrectionDisabled()
            }
            
            // Description input
            VStack(alignment: .leading, spacing: 8) {
                Label("Mô tả", systemImage: "text.alignleft")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Mô tả chi tiết về thực đơn (tùy chọn)", text: $description, axis: .vertical)
                    .textFieldStyle(CustomTextFieldStyle(minHeight: 80))
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
                        .font(.system(size: 18, weight: .semibold))
                }
                
                Text(menu == nil ? "Tạo Thực Đơn" : "Lưu Thay Đổi")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: isFormValid ? [.blue, .purple] : [.gray.opacity(0.5), .gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
//            .shadow(
//                color: isFormValid ? .blue.opacity(0.3) : .clear,
//                radius: 8,
//                x: 0,
//                y: 4
//            )
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
    private let menu: AppMenu
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    init(menu: AppMenu) {
        self.menu = menu
    }
    
    var body: some View {
            HStack(spacing: 16) {
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
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .layeredCard(tabThemeColors: appState.currentTabThemeColors)
            .cornerRadius(16)
//            .shadow(
//                color: menu.isActive ? .blue.opacity(0.1) : .black.opacity(0.05),
//                radius: 8,
//                x: 0,
//                y: 2
//        )
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
                .frame(width: 50, height: 50)
            
            Image(systemName: "menucard.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
        }
        //.shadow(color: menu.isActive ? .blue.opacity(0.3) : .gray.opacity(0.3), radius: 4, x: 0, y: 2)
    }
    
    // MARK: - Content Section
    private var contentSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Menu name
            Text(menu.menuName)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            // Description
            if let description = menu.description, !description.isEmpty {
                Text(description)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
            } else {
                Text("Chưa có mô tả")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.tertiary)
                    .italic()
            }
            
            // Metadata section
            metadataSection
        }
    }
    
    // MARK: - Metadata Section
    private var metadataSection: some View {
        HStack(spacing: 8) {
            // Created date
            Label(formatDate(menu.createdAt), systemImage: "calendar")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Updated indicator: chỉ hiển thị nếu lệch nhau từ 5 giây trở lên
            if abs(menu.updatedAt.timeIntervalSince(menu.createdAt)) >= 5 {
                Label("Đã cập nhật", systemImage: "pencil")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            Spacer()
        }
    }
    
    // MARK: - Arrow Indicator
    private var arrowIndicator: some View {
        Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(appState.currentTabThemeColors.primaryColor)
    }
    
    private var activeStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(.green)
                .frame(width: 8, height: 8)
            
            Text("Đang hoạt động")
                .font(.caption)
                .fontWeight(.medium)
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
    
    private let currentMenu: AppMenu
    
    init(viewModel: MenuViewModel, currentMenu: AppMenu) {
        self.viewModel = viewModel
        self.currentMenu = currentMenu
    }
    
    private let columns = [
        GridItem(.adaptive(minimum: 180), spacing: 20)
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
//        VStack {
//            Text("")
//        }
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
                        .padding(.vertical, 12)
                    
                    // Search & Filter Section
                    searchAndFilterSection
                        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
                        .padding(.horizontal)
                        .padding(.bottom, 16)
                    
                    // Menu Items Grid
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 24) {
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
                                        .padding(16)
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
                                .pressEvents {
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        isPressed = true
                                    }
                                } onRelease: {
                                    withAnimation(.easeInOut(duration: 0.1)) {
                                        isPressed = false
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 16)
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
                                        await viewModel.deleteMenuItems(viewModel.selectedItems, in: currentMenu)
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
                            .font(.title2)
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
                            .font(.title2)
                    }
                    
                    Button {
                        selectedItem = nil
                        appState.coordinator.navigateTo(.menuItemForm(currentMenu, selectedItem), using: .present, with: .present)
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "plus.circle.fill")
                                .font(.title2)
                            Text("Thêm")
                                .font(.subheadline)
                                .fontWeight(.semibold)
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
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Trạng thái thực đơn")
                        .font(.headline)
                    Text("Chọn thực đơn này để sử dụng trong cửa hàng")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Active Toggle Button
                Button {
                    Task {
                        if currentMenu.isActive {
                            await viewModel.deActivateMenu(currentMenu)
                        } else {
                            await viewModel.activateMenu(currentMenu)
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: currentMenu.isActive ? "checkmark.circle.fill" : "circle")
                            .font(.title3)
                        Text(currentMenu.isActive ? "Đang sử dụng" : "Chọn sử dụng")
                            .font(.subheadline)
                            .fontWeight(.medium)
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
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "fork.knife.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("\(filteredItems.count) món")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        HStack(spacing: 4) {
                            Image(systemName: "pencil.circle.fill")
                                .font(.title2)
                            Text("Chỉnh sửa")
                                .font(.subheadline)
                                .fontWeight(.medium)
                        }
                        .foregroundStyle(.primary)
                        .padding(4)
                        .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
                            appState.coordinator.navigateTo(.menuForm(currentMenu), using: .present, with: .present)
                        }
                    }
                    
                    if let description = currentMenu.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            // Decorative divider
            ModernDivider(tabThemeColors: appState.currentTabThemeColors)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 16)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
    
    private var searchAndFilterSection: some View {
        VStack(spacing: 16) {
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
                HStack(spacing: 12) {
                    ForEach(viewModel.categories, id: \.self) { category in
                        enhancedCategoryButton(category)
                    }
                }
//                .layeredCard(tabThemeColors: appState.currentTabThemeColors)
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func enhancedCategoryButton(_ category: String) -> some View {
        Group {
            let isSelected = selectedCategory == category
            let title = category
            let icon = category == "All" ? "square.grid.2x2.fill" : getCategoryIcon(category)
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(title)
                    .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
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
                .font(.system(size: 16, weight: .medium))
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(CustomTextFieldStyle())
                .font(.subheadline)
                .keyboardType(.default)
            
            if !text.isEmpty {
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        text = ""
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.system(size: 16))
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
    
    private let item: MenuItem
    
    init(viewModel: MenuViewModel, item: MenuItem) {
        self.viewModel = viewModel
        self.item = item
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                // Image placeholder with gradient
                RoundedRectangle(cornerRadius: 12)
                    .fill(appState.currentTabThemeColors.softGradient(for: colorScheme))
                    .frame(height: 120)
                    .overlay(
                        Image(systemName: "fork.knife")
                            .font(.title)
                            .foregroundColor(.white)
                    )
                
                if viewModel.isSelectionMode {
                    ZStack {
                        Circle()
                            .fill(Color.white)
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: viewModel.selectedItems.contains(where: {$0 == item}) ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 22))
                            .foregroundColor(viewModel.selectedItems.contains(where: {$0 == item}) ? .blue : .gray)
                    }
                    .padding(8)
                }
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                
                HStack {
                    Image(systemName: "tag.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(item.category)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                
                HStack {
                    Spacer()
                    Text("\(item.price, specifier: "%.0f")đ")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundStyle(appState.currentTabThemeColors.textGradient(for: colorScheme))
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

//struct MenuItemForm: View {
//    @ObservedObject private var viewModel: MenuViewModel
//    @EnvironmentObject private var appState: AppState
//    @Environment(\.colorScheme) private var colorScheme
//    
//    private let menu: AppMenu
//    private let item: MenuItem?
//    
//    init(viewModel: MenuViewModel, menu: AppMenu, item: MenuItem?) {
//        self.viewModel = viewModel
//        self.menu = menu
//        self.item = item
//        
//        // Initialize state variables with existing item data
//        _name = State(initialValue: item?.name ?? "")
//        _price = State(initialValue: item?.price ?? 0.0)
//        _category = State(initialValue: item?.category ?? "")
//        _imageURL = State(initialValue: item?.imageURL?.absoluteString ?? "")
//        _isAvailable = State(initialValue: item?.isAvailable ?? true)
//        _recipes = State(initialValue: item?.recipe ?? [])
//    }
//    
//    // MARK: - State Variables
//    @State private var name = ""
//    @State private var price: Double = 0.0
//    @State private var category = ""
//    @State private var imageURL = ""
//    @State private var isAvailable = true
//    @State private var recipes: [Recipe] = []
//    
//    @State private var showingDeleteAlert = false
//    @State private var showingImagePicker = false
//    @State private var showingRecipeForm = false
//    @State private var isLoading = false
//    @State private var showingCategoryPicker = false
//    
//    // Pre-defined categories
//    private let categories = [
//        "Món chính", "Khai vị", "Tráng miệng", "Đồ uống",
//        "Món nướng", "Món chiên", "Món luộc", "Salad", "Soup"
//    ]
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(spacing: 32) {
//                    // Header Image Section
//                    headerImageSection
//                    
//                    // Basic Information Section
//                    basicInfoSection
//                    
//                    // Pricing Section
//                    pricingSection
//                    
//                    // Category Section
//                    categorySection
//                    
//                    // Availability Section
//                    availabilitySection
//                    
//                    // Recipe Section
//                    recipeSection
//                    
//                    // Action Button
//                    actionButton
//                    
//                    Spacer(minLength: 20)
//                }
//                .padding(.horizontal, 20)
//                .padding(.top, 20)
//            }
//            .navigationTitle(item == nil ? "Thêm món mới" : "Chỉnh sửa món")
//            .navigationBarTitleDisplayMode(.large)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Hủy") {
//                        appState.coordinator.dismiss()
//                    }
//                    .foregroundColor(.secondary)
//                }
//                
//                if item != nil {
//                    ToolbarItem(placement: .navigationBarTrailing) {
//                        Button(action: {
//                            showingDeleteAlert = true
//                        }) {
//                            Image(systemName: "trash")
//                                .foregroundColor(.red)
//                        }
//                    }
//                }
//            }
//            .alert("Xóa món ăn", isPresented: $showingDeleteAlert) {
//                Button("Hủy", role: .cancel) {}
//                Button("Xóa", role: .destructive) {
//                    Task {
//                        await deleteMenuItem()
//                    }
//                }
//            } message: {
//                Text("Bạn có chắc chắn muốn xóa món ăn này?")
//            }
//            .sheet(isPresented: $showingRecipeForm) {
//                RecipeFormView(recipes: $recipes)
//            }
//        }
//        .disabled(isLoading)
//        .overlay(
//            Group {
//                if isLoading {
//                    Color.black.opacity(0.3)
//                        .ignoresSafeArea()
//                    
//                    ProgressView("Đang xử lý...")
//                        .padding()
//                        .background(Color(.systemBackground))
//                        .cornerRadius(12)
//                        .shadow(radius: 5)
//                }
//            }
//        )
//    }
//    
//    // MARK: - Header Image Section
//    private var headerImageSection: some View {
//        VStack(spacing: 16) {
//            Text("Hình ảnh món ăn")
//                .font(.headline)
//                .foregroundColor(.primary)
//                .frame(maxWidth: .infinity, alignment: .leading)
//            
//            Button(action: { showingImagePicker = true }) {
//                ZStack {
//                    RoundedRectangle(cornerRadius: 16)
//                        .fill(colorScheme == .dark ? Color(.systemGray5) : Color(.systemGray6))
//                        .frame(height: 200)
//                    
//                    if !imageURL.isEmpty {
//                        AsyncImage(url: URL(string: imageURL)) { image in
//                            image
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                        } placeholder: {
//                            ProgressView()
//                        }
//                        .frame(height: 200)
//                        .clipShape(RoundedRectangle(cornerRadius: 16))
//                    } else {
//                        VStack(spacing: 12) {
//                            Image(systemName: "photo.badge.plus")
//                                .font(.system(size: 32))
//                                .foregroundColor(.secondary)
//                            
//                            Text("Chọn hình ảnh")
//                                .font(.subheadline)
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                }
//            }
//            .buttonStyle(PlainButtonStyle())
//            
//            // Image URL Input
//            VStack(alignment: .leading, spacing: 8) {
//                Text("URL hình ảnh")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                TextField("https://example.com/image.jpg", text: $imageURL)
//                    .textFieldStyle(RoundedBorderTextFieldStyle())
//                    .keyboardType(.URL)
//                    .autocapitalization(.none)
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//        )
//    }
//    
//    // MARK: - Basic Information Section
//    private var basicInfoSection: some View {
//        VStack(spacing: 20) {
//            Text("Thông tin cơ bản")
//                .font(.headline)
//                .foregroundColor(.primary)
//                .frame(maxWidth: .infinity, alignment: .leading)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Tên món ăn")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                TextField("Nhập tên món ăn", text: $name)
//                    .textFieldStyle(CustomTextFieldStyle())
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//        )
//    }
//    
//    // MARK: - Pricing Section
//    private var pricingSection: some View {
//        VStack(spacing: 20) {
//            Text("Giá cả")
//                .font(.headline)
//                .foregroundColor(.primary)
//                .frame(maxWidth: .infinity, alignment: .leading)
//            
//            VStack(alignment: .leading, spacing: 8) {
//                Text("Giá (VNĐ)")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                HStack {
//                    TextField("0", value: $price, format: .number)
//                        .textFieldStyle(CustomTextFieldStyle())
//                        .keyboardType(.decimalPad)
//                    
//                    Text("VNĐ")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                        .padding(.trailing, 8)
//                }
//                
//                if price > 0 {
//                    Text("Giá hiển thị: \(String(format: "%.0f VNĐ", price))")
//                        .font(.caption)
//                        .foregroundColor(.green)
//                        .padding(.top, 4)
//                }
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//        )
//    }
//    
//    // MARK: - Category Section
//    private var categorySection: some View {
//        VStack(spacing: 20) {
//            Text("Danh mục")
//                .font(.headline)
//                .foregroundColor(.primary)
//                .frame(maxWidth: .infinity, alignment: .leading)
//            
//            VStack(alignment: .leading, spacing: 12) {
//                Text("Chọn danh mục")
//                    .font(.subheadline)
//                    .foregroundColor(.secondary)
//                
//                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
//                    ForEach(categories, id: \.self) { cat in
//                        Button(action: {
//                            category = cat
//                        }) {
//                            Text(cat)
//                                .font(.caption)
//                                .padding(.horizontal, 12)
//                                .padding(.vertical, 8)
//                                .background(
//                                    RoundedRectangle(cornerRadius: 8)
//                                        .fill(category == cat ? Color.blue : Color(.systemGray5))
//                                )
//                                .foregroundColor(category == cat ? .white : .primary)
//                        }
//                        .buttonStyle(PlainButtonStyle())
//                    }
//                }
//                
//                Text("Hoặc nhập danh mục tùy chỉnh")
//                    .font(.caption)
//                    .foregroundColor(.secondary)
//                    .padding(.top, 8)
//                
//                TextField("Nhập danh mục", text: $category)
//                    .textFieldStyle(CustomTextFieldStyle())
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//        )
//    }
//    
//    // MARK: - Availability Section
//    private var availabilitySection: some View {
//        VStack(spacing: 20) {
//            Text("Trạng thái")
//                .font(.headline)
//                .foregroundColor(.primary)
//                .frame(maxWidth: .infinity, alignment: .leading)
//            
//            HStack {
//                VStack(alignment: .leading, spacing: 4) {
//                    Text("Trạng thái phục vụ")
//                        .font(.subheadline)
//                        .foregroundColor(.primary)
//                    
//                    Text(isAvailable ? "Đang phục vụ" : "Tạm ngưng")
//                        .font(.caption)
//                        .foregroundColor(isAvailable ? .green : .red)
//                }
//                
//                Spacer()
//                
//                Toggle("", isOn: $isAvailable)
//                    .scaleEffect(1.2)
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//        )
//    }
//    
//    // MARK: - Recipe Section
//    private var recipeSection: some View {
//        VStack(spacing: 20) {
//            HStack {
//                Text("Công thức")
//                    .font(.headline)
//                    .foregroundColor(.primary)
//                
//                Spacer()
//                
//                Button(action: {
//                    showingRecipeForm = true
//                }) {
//                    HStack(spacing: 6) {
//                        Image(systemName: "plus.circle.fill")
//                        Text("Thêm")
//                    }
//                    .font(.subheadline)
//                    .foregroundColor(.blue)
//                }
//            }
//            
//            if recipes.isEmpty {
//                VStack(spacing: 12) {
//                    Image(systemName: "doc.text.below.ecg")
//                        .font(.system(size: 32))
//                        .foregroundColor(.secondary)
//                    
//                    Text("Chưa có công thức")
//                        .font(.subheadline)
//                        .foregroundColor(.secondary)
//                    
//                    Text("Thêm công thức để quản lý nguyên liệu")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
//                }
//                .padding(.vertical, 20)
//            } else {
//                LazyVStack(spacing: 12) {
//                    ForEach(Array(recipes.enumerated()), id: \.offset) { index, recipe in
//                        RecipeItemRow(recipe: recipe) {
//                            recipes.remove(at: index)
//                        }
//                    }
//                }
//            }
//        }
//        .padding()
//        .background(
//            RoundedRectangle(cornerRadius: 16)
//                .fill(Color(.systemBackground))
//                .shadow(color: .black.opacity(0.1), radius: 2, x: 0, y: 1)
//        )
//    }
//    
//    // MARK: - Action Button
//    private var actionButton: some View {
//        Button(action: {
//            Task {
//                await saveMenuItem()
//            }
//        }) {
//            HStack {
//                if isLoading {
//                    ProgressView()
//                        .scaleEffect(0.8)
//                        .tint(.white)
//                } else {
//                    Image(systemName: item == nil ? "plus.circle.fill" : "checkmark.circle.fill")
//                        .font(.system(size: 18))
//                }
//                
//                Text(item == nil ? "Thêm món ăn" : "Cập nhật món ăn")
//                    .font(.headline)
//            }
//            .foregroundColor(.white)
//            .frame(maxWidth: .infinity)
//            .padding()
//            .background(
//                RoundedRectangle(cornerRadius: 16)
//                    .fill(isFormValid ? Color.blue : Color.gray)
//            )
//        }
//        .disabled(!isFormValid || isLoading)
//        .buttonStyle(PlainButtonStyle())
//    }
//    
//    // MARK: - Computed Properties
//    private var isFormValid: Bool {
//        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
//        price > 0 &&
//        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
//    }
//    
//    // MARK: - Methods
//    private func saveMenuItem() async {
//        isLoading = true
//        defer { isLoading = false }
//        
//        let menuItem = MenuItem(
//            id: item?.id,
//            menuId: menu.id ?? "",
//            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
//            price: price,
//            category: category.trimmingCharacters(in: .whitespacesAndNewlines),
//            recipe: recipes,
//            isAvailable: isAvailable,
//            imageURL: imageURL.isEmpty ? nil : URL(string: imageURL),
//            createdAt: item?.createdAt ?? Date(),
//            updatedAt: Date()
//        )
//        
//        if item == nil {
//            await viewModel.createMenuItem(menuItem, in: menu, imageData: nil)
//            appState.sourceModel.showSuccess("Đã thêm món ăn thành công!")
//        } else {
//            await viewModel.updateMenuItem(menuItem, in: menu, imageData: nil)
//            appState.sourceModel.showSuccess("Đã cập nhật món ăn thành công!")
//        }
//        
//        appState.coordinator.dismiss()
//    }
//    
//    private func deleteMenuItem() async {
//        if let item = item {
//            await viewModel.deleteMenuItem(item, in: menu)
//            appState.sourceModel.showSuccess("Đã xóa món ăn thành công!")
//            appState.coordinator.dismiss()
//        }
//    }
//}

// MARK: - Recipe Item Row
struct RecipeItemRow: View {
    let recipe: Recipe
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.ingredientName ?? "Nguyên liệu")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("Số lượng: \(recipe.requiredAmount.displayString)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: onDelete) {
                Image(systemName: "minus.circle.fill")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - Recipe Form View (Placeholder)
//struct RecipeFormView: View {
//    @Binding var recipes: [Recipe]
//    @Environment(\.dismiss) private var dismiss
//    
//    var body: some View {
//        NavigationView {
//            VStack {
//                Text("Recipe Form")
//                    .font(.title)
//                
//                Text("This would be a detailed recipe form")
//                    .foregroundColor(.secondary)
//                
//                Spacer()
//            }
//            .navigationTitle("Thêm công thức")
//            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItem(placement: .navigationBarLeading) {
//                    Button("Hủy") {
//                        dismiss()
//                    }
//                }
//                
//                ToolbarItem(placement: .navigationBarTrailing) {
//                    Button("Lưu") {
//                        // Save logic here
//                        dismiss()
//                    }
//                }
//            }
//        }
//    }
//}
