import SwiftUI

struct OrderView: View {
    
    @ObservedObject var viewModel: OrderViewModel
    @EnvironmentObject private var appState: AppState
    @Namespace private var animation
    @State private var showDiscounts = false
    @FocusState private var isMenuSearchFocused: Bool
    @FocusState private var isCustomerSearchFocused: Bool
    @Environment(\.colorScheme) var colorScheme
    @State private var appearAnimation = false
    
    var body: some View {
        Group {
            if isIphone {
                iphoneLayout
            } else {
                ipadLayout
            }
        }
        .opacity(appearAnimation ? 1 : 0)
        .offset(y: appearAnimation ? 0 : 20)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appearAnimation = true
                appState.coordinator.updateCurrentRoute(.order)
            }
            appState.sourceModel.setupMenuItemsListener(shopId: appState.sourceModel.activatedShop?.id ?? "", menuId: nil)
            appState.sourceModel.setupCustomersListener(shopId: appState.sourceModel.activatedShop?.id ?? "")
        }
        .onDisappear {
            appState.sourceModel.removeMenuItemsListener(shopId: appState.sourceModel.activatedShop?.id ?? "", menuId: nil)
            appState.sourceModel.removeCustomersListener(shopId: appState.sourceModel.activatedShop?.id ?? "")
        }
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                isMenuSearchFocused = false
                isCustomerSearchFocused = false
            }
        )
    }
}

// MARK: - iPhone Layout
private extension OrderView {
    
    // MARK: - Main Layout
    var iphoneLayout: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Enhanced Search Bar
                menuSearchBar
                    .padding(.horizontal)
                    .transition(.move(edge: .top).combined(with: .opacity))
                
                // Category Scroll
                categoryScrollView()
                    .padding(.vertical, 8)
                    .transition(.move(edge: .top).combined(with: .opacity))
                
                // Menu Items Grid
                ScrollView(showsIndicators: false) {
                    if viewModel.menuItems.isEmpty {
                        EmptyStateView(
                            icon: "tray.fill",
                            title: "Menu trống",
                            message: "Chưa có món nào được thêm vào thực đơn",
                            action: {
                                // TODO: Thêm action để điều hướng đến trang quản lý menu nếu user có quyền
                            },
                            actionTitle: "Quản lý menu"
                        )
                        .padding(.top, 100)
                        .transition(.scale.combined(with: .opacity))
                    } else if viewModel.menuSearchKey.isEmpty && viewModel.selectedCategory != "All" && viewModel.filteredMenuItems.isEmpty {
                        EmptyStateView(
                            icon: "tag.fill",
                            title: "Danh mục trống",
                            message: "Không có món nào trong danh mục \(viewModel.selectedCategory)",
                            action: {
                                withAnimation {
                                    viewModel.updateSelectedCategory("All")
                                }
                            },
                            actionTitle: "Xem tất cả món"
                        )
                        .padding(.top, 100)
                        .transition(.scale.combined(with: .opacity))
                    } else if !viewModel.menuSearchKey.isEmpty && viewModel.filteredMenuItems.isEmpty {
                        EmptyStateView(
                            icon: "magnifyingglass",
                            title: "Không tìm thấy",
                            message: "Không tìm thấy món nào phù hợp với từ khóa '\(viewModel.menuSearchKey)'",
                            action: {
                                viewModel.clearMenuSearch()
                            }, 
                            actionTitle: "Xóa tìm kiếm"
                        )
                        .padding(.top, 100)
                        .transition(.scale.combined(with: .opacity))
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            ForEach(viewModel.filteredMenuItems) { item in
                                appState.coordinator.makeView(for: .orderMenuItemCardIphone(item))
                                EmptyView()
                                    .matchedGeometryEffect(id: item.id, in: animation)
                                    .transition(.asymmetric(
                                        insertion: .scale(scale: 0.8).combined(with: .opacity),
                                        removal: .scale(scale: 0.8).combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding(16)
                    }
                }
                
                // Cart Button
                cartButton
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: appearAnimation)
    }
    
    // MARK: - Components
    var menuSearchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Tìm món...", text: Binding(
                    get: { viewModel.menuSearchKey },
                    set: { viewModel.updateMenuSearchKey($0) }
                ))
                .focused($isMenuSearchFocused)
                
                if !viewModel.menuSearchKey.isEmpty {
                    Button {
                        viewModel.clearMenuSearch()
                        isMenuSearchFocused = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .layeredTextField(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 16)
        }
    }
    
    var cartButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                appState.coordinator.navigateTo(.orderSummary, using: .present, with: .present)
            }
        } label: {
            HStack {
                Image(systemName: "cart.fill")
                    .font(.system(size: 20, weight: .semibold))
                
                VStack(alignment: .leading) {
                    Text("\(viewModel.selectedItems.count) món")
                        .font(.system(size: 16, weight: .semibold))
                    Text(viewModel.totalPrice)
                        .font(.system(size: 14, weight: .medium))
                }
                
                Spacer()
                
                Text("Xem giỏ hàng")
                    .font(.system(size: 16, weight: .semibold))
                
                Image(systemName: "chevron.up")
                    .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .background(
                appState.currentTabThemeColors.gradient(for: colorScheme)
            )
            .cornerRadius(16)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
}

// MARK: - iPad Layout
private extension OrderView {
    
    // MARK: - Main Layout
    var ipadLayout: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 20) {
                leftSideMenu(geometry: geometry)
                rightSideOrder(geometry: geometry)
            }
        }
        .padding(.horizontal, 24)
        .simultaneousGesture(
            TapGesture().onEnded { _ in
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                isMenuSearchFocused = false
                isCustomerSearchFocused = false
                if viewModel.showingDeleteButton {
                    withAnimation(.spring()) {
                        viewModel.orderItemOffset = 0
                        viewModel.showingDeleteButton = false
                    }
                }
            }
        )
    }
    
    // MARK: - Left side containing categories and menu items
    func leftSideMenu(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            menuHeader(width: (geometry.size.width - 44) * 0.65)
            categoryScrollView()
            menuItemsGrid()
        }
        .frame(maxWidth: max((geometry.size.width) * 0.65, 0))
        .frame(maxHeight: geometry.size.height)
        .padding(.vertical, 12)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
    }
    
    func menuHeader(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Menu")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            appState.currentTabThemeColors.primaryColor
                        )
                    Text("Choose your favorite items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                Spacer()
                
                // Shop info badge
                HStack {
                    Image(systemName: "storefront.fill")
                        .foregroundColor(appState.currentTabThemeColors.primaryColor)
                    Text(appState.sourceModel.activatedShop?.shopName ?? "Shop")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(appState.currentTabThemeColors.primaryColor.opacity(0.1))
                .clipShape(Capsule())
            }
            
            searchField
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
    
    var searchField: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search for delicious items...", text: Binding(
                get: { viewModel.menuSearchKey },
                set: { viewModel.updateMenuSearchKey($0) }
            ))
            .focused($isMenuSearchFocused)
            .font(.system(size: 16))
            .padding(.vertical, 12)
            .disableAutocorrection(true)
            
            if !viewModel.menuSearchKey.isEmpty {
                Button {
                    viewModel.clearMenuSearch()
                    isMenuSearchFocused = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .layeredTextField(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 16)
    }
    
    func categoryScrollView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isIphone ? 8 : 16) {
                ForEach(viewModel.categories, id: \.self) { category in
                    categoryButton(for: category)
                        .layeredSelectionButton(tabThemeColors: appState.currentTabThemeColors, isCapsule: true, isSelected: viewModel.isCategorySelected(category), namespace: animation, geometryID: "selected_category") {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                viewModel.updateSelectedCategory(category)
                            }
                        }
                }
            }
            .padding(.horizontal, 20)
        }
        .padding(.vertical, 12)
    }
    
    func menuItemsGrid() -> some View {
        ScrollView(showsIndicators: false) {
            if viewModel.menuItems.isEmpty {
                // Trường hợp không có món nào trong menu
                EmptyStateView(
                    icon: "tray.fill",
                    title: "Menu trống",
                    message: "Chưa có món nào được thêm vào thực đơn",
                    action: {
                        // TODO: Thêm action để điều hướng đến trang quản lý menu nếu user có quyền
                    },
                    actionTitle: "Quản lý menu"
                )
                .padding(.top, 100)
            } else if viewModel.menuSearchKey.isEmpty && viewModel.selectedCategory != "All" && viewModel.filteredMenuItems.isEmpty {
                // Trường hợp category không có món nào
                EmptyStateView(
                    icon: "tag.fill",
                    title: "Danh mục trống",
                    message: "Không có món nào trong danh mục \(viewModel.selectedCategory)",
                    action: {
                        withAnimation {
                            viewModel.updateSelectedCategory("All")
                        }
                    },
                    actionTitle: "Xem tất cả món"
                )
                .padding(.top, 100)
            } else if !viewModel.menuSearchKey.isEmpty && viewModel.filteredMenuItems.isEmpty {
                // Trường hợp tìm kiếm không có kết quả
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Không tìm thấy",
                    message: "Không tìm thấy món nào phù hợp với từ khóa '\(viewModel.menuSearchKey)'",
                    action: {
                        viewModel.clearMenuSearch()
                    },
                    actionTitle: "Xóa tìm kiếm"
                )
                .padding(.top, 100)
            } else {
                LazyVGrid(
                    columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2),
                    spacing: 24
                ) {
                    ForEach(viewModel.filteredMenuItems) { item in
                        appState.coordinator.makeView(for: .orderMenuItemCardIpad(item))
                        EmptyView()
                            .matchedGeometryEffect(id: item.id, in: animation)
                    }
                }
                .padding(20)
            }
        }
    }
    
    // MARK: - Right side containing order details
    private func rightSideOrder(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            userProfileHeader()
            orderHeader()
            orderItemsList(geometry: geometry)
            
            if viewModel.selectedItems.isEmpty {
                Spacer()
                    .transition(.opacity.combined(with: .opacity))
            }

            if !viewModel.selectedItems.isEmpty {
                orderSummarySection()
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                CustomerSearchSection(viewModel: viewModel)
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                paymentMethodSection()
                    .transition(.move(edge: .bottom).combined(with: .opacity))

                paymentButton()
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: viewModel.selectedItems)
        .padding(24)
        .frame(maxWidth: max((geometry.size.width) * 0.35, 300))
        .frame(maxHeight: geometry.size.height)
        .padding(.vertical, 12)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
    }
    
    private func userProfileHeader() -> some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(appState.currentTabThemeColors.gradient(for: colorScheme))
                    .frame(width: 60, height: 60)
                
                Text(String(appState.sourceModel.currentUser?.displayName.prefix(1) ?? "☕"))
                    .font(.title.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text("Good morning! ☀️")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(appState.sourceModel.currentUser?.displayName ?? "Welcome")
                    .font(.title2.weight(.semibold))
                    .lineLimit(1)
                    .foregroundColor(.primary)
            }
            
            Spacer()
            
            // Notification badge with modern design
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .foregroundColor(appState.currentTabThemeColors.primaryColor)
                    .font(.system(size: 18))
            }
            .scaleEffect(1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: true)
        }
        .padding(.bottom, 16)
        .padding(.horizontal, 4)
    }

    private func orderHeader() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Text("Your Order")
                        .font(.title.weight(.bold))
                        .foregroundStyle(Color.primary)
                    
                    // Modern item count badge
                    if !viewModel.selectedItems.isEmpty {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 8, height: 8)
                            Text("\(viewModel.selectedItems.count)")
                                .font(.caption.weight(.semibold))
                                .foregroundColor(.green)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .clipShape(Capsule())
                    }
                }
                
                if !viewModel.selectedItems.isEmpty {
                    Text("\(viewModel.selectedItems.count > 1 ? "items" : "item") ready to order")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if !viewModel.selectedItems.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "trash.fill")
                    Text("Clear All")
                }
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .layeredAlertButton {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.clearOrder()
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func orderItemsList(geometry: GeometryProxy) -> some View {
        ScrollView(showsIndicators: false) {
            if viewModel.selectedItems.isEmpty {
                VStack(spacing: 20) {
                    ZStack {
                        Circle()
                            .fill(appState.currentTabThemeColors.accentColor)
                            .frame(width: 120, height: 120)
                        
                        Image(systemName: "cup.and.saucer.fill")
                            .font(.system(size: 50))
                            .foregroundColor(appState.currentTabThemeColors.primaryColor)
                    }
                    
                    VStack(spacing: 8) {
                        Text("Your order is brewing...")
                            .font(.title2.weight(.semibold))
                            .foregroundColor(.primary)
                        Text("Add some delicious coffee & treats!")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                }
                .frame(maxWidth: .infinity)
            } else {
                LazyVStack(spacing: 12) {
                    ForEach(viewModel.selectedItems) { item in
                        appState.coordinator.makeView(for: .orderItem(item))
                        EmptyView()
                            .padding(.horizontal, 4)
                            .middleLayer(tabThemeColors: appState.currentTabThemeColors)
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .leading)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.9)),
                                    removal: .move(edge: .trailing)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.9))
                                )
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: item)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(maxHeight: geometry.size.height * 0.4)
    }

    private func orderSummarySection() -> some View {
        VStack(alignment: .leading, spacing: 16) {
            // Modern divider
            ModernDivider(tabThemeColors: appState.currentTabThemeColors)
            
            discountSection
            
            orderSummary
        }
        .padding(.bottom, 12)
    }

    private var discountSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "gift.fill")
                        .foregroundColor(appState.currentTabThemeColors.primaryColor)
                        .font(.system(size: 16))
                    
                    Text("Offers & Discounts")
                        .font(.headline.weight(.semibold))
                        .foregroundStyle(Color.primary)
                }
                
                Spacer()
                
                // Discount availability indicator
                if let availableDiscounts = appState.sourceModel.activatedShop?.discountVouchers,
                   !availableDiscounts.isEmpty {
                    HStack(spacing: 6) {
                        Text("\(availableDiscounts.count) available")
                            .font(.caption.weight(.medium))
                            .foregroundColor(.primary)
                        
                        Image(systemName: showDiscounts ? "chevron.up" : "chevron.down")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.primary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .layeredButton(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 24) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            showDiscounts.toggle()
                        }
                    }
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        Text("No offers")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.gray.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
            
            // Expandable discount list
            if showDiscounts,
               let availableDiscounts = appState.sourceModel.activatedShop?.discountVouchers,
               !availableDiscounts.isEmpty {
                
                VStack(spacing: 12) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(availableDiscounts, id: \.name) { discount in
                                discountCard(discount)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .top).combined(with: .opacity),
                    removal: .move(edge: .top).combined(with: .opacity)
                ))
            }
            
            // Selected discount summary
            if let selectedDiscount = viewModel.selectedDiscount {
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Applied Discount")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.secondary)
                            Text(selectedDiscount.name)
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("-\(selectedDiscount.value, specifier: "%.0f")%")
                                .font(.subheadline.weight(.bold))
                                .foregroundColor(.green)
                            Text("-\(viewModel.discount, specifier: "%.0f")đ")
                                .font(.caption.weight(.medium))
                                .foregroundColor(.green)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.green.opacity(0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.green.opacity(0.8), lineWidth: 1)
                            )
                    )
                }
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .padding(.horizontal, 16)
    }

    private func discountCard(_ discount: DiscountVoucher) -> some View {
        HStack(spacing: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text(discount.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text("Save \(discount.value, specifier: "%.0f")%")
                    .font(.caption.weight(.medium))
                    .foregroundColor(.secondary)
            }
            
            if viewModel.selectedDiscount?.name == discount.name {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedDiscount?.name == discount.name)
        .padding(16)
        .layeredSelectionButton(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 12, isSelected: viewModel.selectedDiscount?.name == discount.name, namespace: animation, geometryID: "selected_discount") {
            withAnimation(.spring(response: 0.3)) {
                viewModel.selectDiscount(discount)
            }
        }
    }

    private var orderSummary: some View {
        VStack(spacing: 16) {
            VStack(spacing: 12) {
                HStack {
                    Text("Subtotal:")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("\(viewModel.subtotal, specifier: "%.0f")đ")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.primary)
                }
                
                if viewModel.selectedDiscount != nil {
                    HStack {
                        Text("Discount:")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("-\(viewModel.discount, specifier: "%.0f")đ")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.green)
                    }
                }
            }
            
            // Modern divider
            ModernDivider(tabThemeColors: appState.currentTabThemeColors)
            
            HStack {
                Text("Total:")
                    .font(.title2.weight(.bold))
                    .foregroundColor(.primary)
                Spacer()
                Text("\(viewModel.total, specifier: "%.0f")đ")
                    .font(.title2.weight(.bold))
                    .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
            }
        }
        .padding(20)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
        .padding(.horizontal, 16)
    }

    private func paymentMethodSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "creditcard.fill")
                    .foregroundColor(appState.currentTabThemeColors.primaryColor)
                    .font(.system(size: 16))
                
                Text("Payment Method")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
            }
            
            HStack(spacing: 12) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    paymentMethodButton(method, isSelected: viewModel.paymentMethod == method)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.horizontal, 16)
    }

    private func paymentButton() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20, weight: .semibold))
            
            Text("Place Order • \(viewModel.total, specifier: "%.0f")đ")
                .font(.title3.weight(.semibold))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 18)
        .layeredButton(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 16, action: {
            Task {
                do {
                    try await viewModel.createOrder()
                }
            }
        })
        .foregroundColor(.white)
        .padding(.horizontal, 16)
        .padding(.top, 20)
    }
    
    // MARK: - Components
    func categoryButton(for category: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: viewModel.getCategoryIcon(for: category))
                .font(.system(size: 14, weight: .medium))
            Text(category)
                .font(.subheadline.weight(.medium))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .foregroundColor(viewModel.isCategorySelected(category) ? .white : .primary)
    }
    
    func paymentMethodButton(_ method: PaymentMethod, isSelected: Bool) -> some View {
        VStack(spacing: 8) {
            Image(systemName: method.icon)
                .font(.system(size: 20))
                .foregroundColor(isSelected ? .white : .primary)
            
            Text(method.rawValue)
                .font(.caption.weight(.medium))
                .foregroundColor(isSelected ? .white : .primary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .layeredSelectionButton(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 12, isSelected: isSelected, namespace: animation, geometryID: "selected_payment_method") {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                viewModel.updatePaymentMethod(method)
            }
        }
    }
}

// MARK: - Empty State Views
struct EmptyStateView: View {
    
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    let icon: String
    let title: String
    let message: String
    let action: (() -> Void)?
    let actionTitle: String?
    
    init(
        icon: String,
        title: String,
        message: String,
        action: (() -> Void)? = nil,
        actionTitle: String? = nil
    ) {
        self.icon = icon
        self.title = title
        self.message = message
        self.action = action
        self.actionTitle = actionTitle
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.gray.opacity(0.6))
            
            Text(title)
                .font(.title2)
                .fontWeight(.medium)
                .foregroundColor(.primary)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if let action = action, let actionTitle = actionTitle {
                Button(action: action) {
                    HStack(spacing: 8) {
                        Text(actionTitle)
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 12)
                    .background(
                        appState.currentTabThemeColors.gradient(for: colorScheme)
                    )
                    .clipShape(Capsule())
                }
                .padding(.top, 8)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal, 40)
    }
}

struct OrderSummarySheet: View {
    
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var viewModel: OrderViewModel
    @FocusState private var appTextField: AppTextField?
    @Environment(\.colorScheme) private var colorScheme
    
    init(viewModel: OrderViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 20) {
                    customerSearchBar
                    
                    ForEach(viewModel.selectedItems) { item in
                        appState.coordinator.makeView(for: .orderItem(item))
                        EmptyView()
                    }
                    
                    if viewModel.selectedItems.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "cart")
                                .font(.system(size: 40))
                                .foregroundColor(.gray)
                            Text("Giỏ hàng trống")
                                .font(.headline)
                            Text("Hãy thêm món bạn yêu thích")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 40)
                    }
                }
                .padding()
            }
            if !viewModel.selectedItems.isEmpty {
                VStack(spacing: 16) {
                    // Order Summary
                    VStack(spacing: 8) {
                        HStack {
                            Text("Tạm tính")
                            Spacer()
                            Text(viewModel.totalPrice)
                        }
                        .font(.subheadline)
                        
                        HStack {
                            Text("Tổng cộng")
                                .fontWeight(.bold)
                            Spacer()
                            Text(viewModel.totalPrice)
                                .fontWeight(.bold)
                                .foregroundStyle(
                                    appState.currentTabThemeColors.gradient(for: colorScheme)
                                )
                        }
                    }
                    .padding()
                    .cornerRadius(12)
                    
                    // Payment Method Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Phương thức thanh toán")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(PaymentMethod.allCases, id: \.self) { method in
                                    Button {
                                        withAnimation(.spring(response: 0.3)) {
                                            viewModel.updatePaymentMethod(method)
                                        }
                                    } label: {
                                        paymentOptionCard(method)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical, 8)
                    
                    // Place Order Button
                    Button {
                        Task {
                            do {
                                try await viewModel.createOrder()
                                withAnimation {
//                                    appState.coordinator.dismiss(style: .present)
                                }
                            }
                        }
                    } label: {
                        Text("Đặt hàng")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                appState.currentTabThemeColors.gradient(for: colorScheme)
                            )
                            .cornerRadius(16)
                    }
                }
                .layeredCard(tabThemeColors: appState.currentTabThemeColors)
                .padding()
            }
        }
        .frame(maxWidth: .infinity)
        .background(
            appState.currentTabThemeColors.animatedGradient(for: colorScheme)
        )
    }
    
    private var customerSearchBar: some View {
        VStack(spacing: 12) {
            HStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Tìm theo số điện thoại", text: Binding(
                        get: { viewModel.customerSearchKey },
                        set: { viewModel.updateCustomerSearchKey($0) }
                    ))
                    .keyboardType(.numberPad)
                    .focused($appTextField, equals: .searchBar(.customer))
                    
                    if !viewModel.customerSearchKey.isEmpty {
                        Button {
                            viewModel.clearCustomerSearch()
                            appTextField = nil
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemGray6)
                        //.shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appState.sourceModel.currentThemeColors.order.primaryColor.opacity(0.3), lineWidth: 1)
                )
                
                // Add customer button
                Button {
                    appState.coordinator.navigateTo(.addCustomer, using: .present, with: .present)
                } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            appState.sourceModel.currentThemeColors.order.gradient(for: colorScheme)
                        )
                        .clipShape(Circle())
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .cornerRadius(12)
            
            // Search results
            if !viewModel.customerSearchKey.isEmpty && !viewModel.searchedCustomers.isEmpty {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.searchedCustomers) { customer in
                            CustomerRow(customer: customer) {
                                withAnimation(.spring(response: 0.3)) {
                                    viewModel.selectCustomer(customer)
                                    viewModel.clearCustomerSearch()
                                    appTextField = nil
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 150)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Selected customer info
            if let customer = viewModel.selectedCustomer {
                HStack {
                    VStack(alignment: .leading) {
                        Text(customer.displayName)
                            .font(.subheadline.bold())
                        Text(customer.phoneNumber)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.clearSelectedCustomer()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.searchedCustomers)
    }
    
    private func paymentOptionCard(_ method: PaymentMethod) -> some View {
        HStack(spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(viewModel.paymentMethod == method ? method.color.opacity(0.15) : Color(.systemGray5))
                    .frame(width: 40, height: 40)
                
                Image(systemName: method.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(viewModel.paymentMethod == method ? method.color : .gray)
            }
            
            // Title and Description
            VStack(alignment: .leading, spacing: 2) {
                Text(method.title)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.primary)
                
                Text(method.description)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            // Selection Indicator
            ZStack {
                Circle()
                    .stroke(viewModel.paymentMethod == method ? method.color : Color(.systemGray4), lineWidth: 2)
                    .frame(width: 20, height: 20)
                
                if viewModel.paymentMethod == method {
                    Circle()
                        .fill(method.color)
                        .frame(width: 12, height: 12)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 16)
    }
}

struct QuickOptionRow<T: CaseIterable & RawRepresentable & Hashable>: View where T.RawValue == String {
    let title: String
    let options: T.AllCases
    @Binding var selection: T
    
    var body: some View {
        HStack(spacing: 8) {
            Text(title)
                .font(.caption.weight(.medium))
                .foregroundColor(.secondary)
                .frame(width: 35, alignment: .leading)
            
            HStack(spacing: 6) {
                ForEach(Array(options), id: \.self) { option in
                    Button {
                        selection = option
                    } label: {
                        Text(option.rawValue)
                            .font(.caption.weight(.medium))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(selection == option ? Color.blue : Color(.systemGray5))
                            )
                            .foregroundColor(selection == option ? .white : .primary)
                    }
                }
            }
        }
    }
}

// MARK: - Payment Method Extensions
extension PaymentMethod {
    var icon: String {
        switch self {
        case .cash:
            return "banknote.fill"
        case .card:
            return "creditcard.fill"
        case .bankTransfer:
            return "iphone"
        }
    }
    
    var title: String {
        switch self {
        case .cash:
            return "Tiền mặt"
        case .card:
            return "Thẻ"
        case .bankTransfer:
            return "Chuyển khoản"
        }
    }
    
    var description: String {
        switch self {
        case .cash:
            return "Thanh toán khi nhận hàng"
        case .card:
            return "Thẻ tín dụng/ghi nợ"
        case .bankTransfer:
            return "Chuyển khoản ngân hàng"
        }
    }
    
    var color: Color {
        SettingsService.shared.currentThemeColors.order.primaryColor
    }
}







