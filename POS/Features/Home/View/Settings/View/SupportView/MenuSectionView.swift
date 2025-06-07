//
//  UpdateMenuView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct MenuSectionView: View {
    @ObservedObject var viewModel: MenuViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showingAddEditSheet = false
    @State private var selectedItem: MenuItem?
    @State private var selectedAction: ActionType?
    
    var body: some View {
        VStack(spacing: 16) {
            // Search & Filter
            HStack {
                SearchBar(text: $searchText, placeholder: "Tìm kiếm thực đơn...")
            }
            .padding()
            
            // Menu Grid
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(viewModel.menuList) { menu in
                        Button {
                            viewModel.selectMenu(menu)
                            appState.coordinator.navigateTo(.menuDetail)
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
        .navigationTitle("Quản lý thực đơn")
        .onAppear(perform: {
            Task {
                appState.sourceModel.setupMenuListListener(shopId: appState.sourceModel.activatedShop?.id ?? "")
        }
        })
        .onDisappear {
            Task {
                appState.sourceModel.removeMenuListListener(shopId: appState.sourceModel.activatedShop?.id ?? "")
            }
        }
    }
    
    private var bottomToolbar: some View {
        HStack {
            Menu {
                Button(action: { selectedAction = .import }) {
                    Label("Nhập từ Excel/CSV", systemImage: "square.and.arrow.down")
                }
                
                Button(action: { selectedAction = .export }) {
                    Label("Xuất dữ liệu", systemImage: "square.and.arrow.up")
                }
                
                Button(action: { selectedAction = .history }) {
                    Label("Lịch sử thay đổi", systemImage: "clock.arrow.circlepath")
                }
            } label: {
                Label("Thao tác", systemImage: "ellipsis.circle")
                    .font(.body.bold())
            }
            .buttonStyle(.bordered)
            
            Spacer()
            
            Button(action: {
                selectedItem = nil
                appState.coordinator.navigateTo(.menuForm(nil), using: .present, with: .present)
            }) {
                Label("Thêm thực đơn mới", systemImage: "plus.circle.fill")
                    .font(.body.bold())
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
}

// MARK: - Supporting Views

struct MenuFormView: View {
    @State private var menuName = ""
    @State private var description = ""
    
    @ObservedObject var viewModel: MenuViewModel
    @EnvironmentObject private var appState: AppState
    
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
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
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
            .shadow(
                color: isFormValid ? .blue.opacity(0.3) : .clear,
                radius: 8,
                x: 0,
                y: 4
            )
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
                    
                    await viewModel.updateMenu(updatedMenu)
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
                    
                    await viewModel.createNewMenu(newMenu) { result in
                        if result {
                            appState.sourceModel.showSuccess("Tạo thực đơn thành công!")
                            appState.coordinator.dismiss(style: .present)
                        } else {
                            appState.sourceModel.showError("Có lỗi xảy ra khi tạo thực đơn. Vui lòng thử lại.")
                        }
                    }
                }
            }
        } catch {
            appState.sourceModel.showError(error.localizedDescription)
        }
    }
}

struct MenuRow: View {
    let menu: AppMenu
    
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
            .background(cardBackground)
            .overlay(cardBorder)
            .cornerRadius(16)
            .shadow(
                color: menu.isActive ? .blue.opacity(0.1) : .black.opacity(0.05),
                radius: 8,
                x: 0,
                y: 2
        )
    }
    
    // MARK: - Icon Section
    private var iconSection: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue.opacity(0.8), .purple.opacity(0.8)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
            
            Image(systemName: "menucard.fill")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
        }
        .shadow(color: .blue.opacity(0.3), radius: 4, x: 0, y: 2)
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
            .foregroundStyle(.tertiary)
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
    
    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    colors: [
                        menu.isActive ? Color(.systemBackground) : Color(.systemBackground),
                        menu.isActive ? Color.blue.opacity(0.02) : Color(.systemBackground).opacity(0.95)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
    }
    
    private var cardBorder: some View {
        RoundedRectangle(cornerRadius: 16)
            .strokeBorder(
                LinearGradient(
                    colors: menu.isActive ? 
                        [Color.blue.opacity(0.3), Color.purple.opacity(0.3)] :
                        [Color(.systemGray5), Color(.systemGray6)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                ),
                lineWidth: 1
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
    @ObservedObject var viewModel: MenuViewModel
    @EnvironmentObject private var appState: AppState
    
    @State private var selectedItem: MenuItem?
    @State private var searchText = ""
    @State private var selectedCategory: String? = "All"
    @State private var showingSearchBar = false
    @State private var animateHeader = false
    @State private var isPressed = false
    @State private var hasAppeared = false
    
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
        if let currentMenu = viewModel.currentMenu {
        GeometryReader { geometry in
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
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
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemBackground))
                                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
                        )
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
                                            .background(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .fill(Color(.systemBackground))
                                                    .shadow(
                                                        color: .black.opacity(isPressed ? 0.15 : 0.08),
                                                        radius: isPressed ? 4 : 8,
                                                        x: 0,
                                                        y: isPressed ? 2 : 4
                                                    )
                                            )
                                            .scaleEffect(isPressed ? 0.95 : 1.0)
                                            .opacity(hasAppeared ? 1 : 0)
                                            .offset(y: hasAppeared ? 0 : 20)
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
                                //showingDeleteAlert = true
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
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
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
        else {
            EmptyView()
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
                        if viewModel.currentMenu!.isActive {
                            await viewModel.deActivateMenu()
                        } else {
                            await viewModel.activateMenu()
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: viewModel.currentMenu!.isActive ? "checkmark.circle.fill" : "circle")
                                .font(.title3)
                        Text(viewModel.currentMenu!.isActive ? "Đang sử dụng" : "Chọn sử dụng")
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(viewModel.currentMenu!.isActive ? .green.opacity(0.1) : .blue.opacity(0.1))
                    )
                    .foregroundColor(viewModel.currentMenu!.isActive ? .green : .blue)
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
                
                        Button {
                            appState.coordinator.navigateTo(.updateMenuForm, using: .present, with: .present)
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "pencil.circle.fill")
                        .font(.title2)
                                Text("Chỉnh sửa")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                            }
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        }
                    }
                    
                    if let description = viewModel.currentMenu?.description {
                        Text(description)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .lineLimit(2)
                    }
                }
            }
            
            // Decorative divider
            HStack {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [.blue.opacity(0.6), .purple.opacity(0.6)],
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
                .shadow(color: .black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
        .padding(.horizontal)
        .padding(.bottom, 16)
    }
    
//    private func updateMenu() async {
//        guard var menu = viewModel.currentMenu else { return }
//        
//        menu.menuName = editedMenuName.trimmingCharacters(in: .whitespacesAndNewlines)
//        menu.description = editedMenuDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : editedMenuDescription.trimmingCharacters(in: .whitespacesAndNewlines)
//        menu.updatedAt = Date()
//        
//        await viewModel.updateMenu(menu)
//        appState.sourceModel.showSuccess("Cập nhật thực đơn thành công!")
//    }
//    
//    private func deleteMenu() async {
//        guard let menu = viewModel.currentMenu else { return }
//        
//        await viewModel.deleteMenu(menu)
//        appState.sourceModel.showSuccess("Đã xóa thực đơn thành công!")
//    }
    
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
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 16)
    }
    
    private func enhancedCategoryButton(_ category: String) -> some View {
        let isSelected = selectedCategory == category
        let title = category
        let icon = category == "All" ? "square.grid.2x2.fill" : getCategoryIcon(category)

        return Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                selectedCategory = category
            }
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                    .fontWeight(.semibold)
                
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Group {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
                    } else {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(Color(.systemGray6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 25)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            )
                    }
                }
            )
            .foregroundColor(isSelected ? .white : .primary)
            .scaleEffect(isSelected ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
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
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
                .font(.system(size: 16, weight: .medium))
            
            TextField(placeholder, text: $text)
                .focused($isFocused)
                .textFieldStyle(PlainTextFieldStyle())
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
                        .stroke(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            ),
                            lineWidth: 2
                        )
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
    @ObservedObject var viewModel: MenuViewModel
    
    let item: MenuItem
    
    var body: some View {
            VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topTrailing) {
                // Image placeholder with gradient
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.blue.opacity(0.3),
                                Color.purple.opacity(0.3)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
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
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.green, .blue],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                }
                .padding(.horizontal, 4)
            }
    }
}

struct MenuItemForm: View {
    @ObservedObject var viewModel: MenuViewModel
    @EnvironmentObject private var appState: AppState
    
    let menu: AppMenu
    let item: MenuItem?
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Form fields here
                }
            }
            .navigationTitle(item == nil ? "Thêm món mới" : "Chỉnh sửa món")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        appState.coordinator.dismiss()
                    }
                    .foregroundColor(.secondary)
                }
                
                if item != nil {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(action: {
                            showingDeleteAlert = true
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(.red)
                        }
                    }
                }
            }
            .alert("Xóa món ăn", isPresented: $showingDeleteAlert) {
                Button("Hủy", role: .cancel) {}
                Button("Xóa", role: .destructive) {
                    Task {
                        await deleteMenuItem()
                    }
                }
            } message: {
                Text("Bạn có chắc chắn muốn xóa món ăn này?")
            }
        }
    }
    
    private func deleteMenuItem() async {
        if let item = item {
            await viewModel.deleteMenuItem(item, in: menu)
            appState.sourceModel.showSuccess("Đã xóa món ăn thành công!")
            appState.coordinator.dismiss()
        }
    }
}

struct UpdateMenuForm: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject var viewModel: MenuViewModel
    @State private var editedMenuName = ""
    @State private var editedMenuDescription = ""
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "pencil.circle.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Chỉnh sửa thực đơn")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                .padding(.top, 20)
                
                // Form
                VStack(alignment: .leading, spacing: 20) {
                    // Menu name
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tên thực đơn", systemImage: "text.alignleft")
                            .font(.headline)
                        TextField("Nhập tên thực đơn", text: $editedMenuName)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Mô tả", systemImage: "text.quote")
                            .font(.headline)
                        TextField("Mô tả thực đơn (tùy chọn)", text: $editedMenuDescription, axis: .vertical)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .lineLimit(3...6)
                            .autocorrectionDisabled()
                    }
                    
                    // Delete button
                    Button {
                        guard let currentMenu = viewModel.currentMenu else { return }
                        appState.sourceModel.showConfirmation(title: "Xoá", message: "Bạn có chắc chắn muốn xoá thực đơn này ?") {
                            Task {
                                await viewModel.deleteMenu(currentMenu)
                            }
                        }
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Xóa thực đơn")
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.red)
                        )
                    }
                    .padding(.top, 20)
                }
                .padding(.horizontal)
            }
            .navigationTitle("Chỉnh sửa thực đơn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        appState.coordinator.dismiss(style: .present)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Lưu") {
                        Task {
                            if let currentMenu = viewModel.currentMenu {
                                var updateMenu = currentMenu
                                updateMenu.menuName = editedMenuName.trimmingCharacters(in: .whitespacesAndNewlines)
                                updateMenu.description = editedMenuDescription.trimmingCharacters(in: .whitespacesAndNewlines)
                                updateMenu.updatedAt = Date()
                                await viewModel.updateMenu(updateMenu)
                                appState.coordinator.dismiss(style: .present)
                            }
                        }
                    }
                    .disabled(editedMenuName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onAppear {
                editedMenuName = viewModel.currentMenu?.menuName ?? ""
                editedMenuDescription = viewModel.currentMenu?.description ?? ""
            }
        }
    }
}
