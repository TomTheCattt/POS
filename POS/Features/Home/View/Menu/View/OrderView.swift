import SwiftUI

struct OrderView: View {
    
    @ObservedObject var viewModel: OrderViewModel
    @EnvironmentObject var appState: AppState
    @Namespace private var animation
    @State private var showOrderSummary = false
    @State private var selectedCategory: String?
    @State private var searchText = ""
    @State private var isSearching = false
    
    private let isIphone = UIDevice.current.userInterfaceIdiom == .phone
    
    var body: some View {
        Group {
            if isIphone {
                iphoneLayout
            } else {
                ipadLayout
            }
            }
            .onAppear {
                appState.sourceModel.setupMenuItemsListener(shopId: appState.sourceModel.activatedShop?.id ?? "", menuId: nil)
            }
            .onDisappear {
                appState.sourceModel.removeMenuItemsListener(shopId: appState.sourceModel.activatedShop?.id ?? "", menuId: nil)
            }
        }
    
    // MARK: - iPhone Layout
    private var iphoneLayout: some View {
        ZStack {
            // Main content
            VStack(spacing: 0) {
                // Enhanced Search Bar
                searchBar
        .padding(.horizontal)
                
                // Category Scroll
                categoryScrollView()
                    .padding(.top, 8)
                
                // Menu Items Grid
                ScrollView {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(viewModel.filteredMenuItems) { item in
                            CompactMenuItemCard(viewModel: viewModel, item: item)
                                .matchedGeometryEffect(id: item.id, in: animation)
                        }
                    }
                    .padding(16)
                }
                
                // Cart Button
                cartButton
            }
            
            // Order Summary Sheet
            if showOrderSummary {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3)) {
                            showOrderSummary = false
                        }
                    }
                
                OrderSummarySheet(
                    viewModel: viewModel,
                    isPresented: $showOrderSummary
                )
                .transition(.move(edge: .bottom))
            }
        }
        .background(Color(.systemGray6))
    }
    
    // MARK: - iPad Layout (Existing)
    private var ipadLayout: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 20) {
                leftSideMenu(geometry: geometry)
                rightSideOrder(geometry: geometry)
            }
        }
        .padding(.horizontal, 24)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [Color(.systemGray6), Color(.systemGray5)]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
    }
    
    // MARK: - iPhone Components
    private var searchBar: some View {
        HStack(spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                
                TextField("Tìm món...", text: $searchText)
                    .textFieldStyle(PlainTextFieldStyle())
                    .onTapGesture {
                        withAnimation {
                            isSearching = true
                        }
                    }
                
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .shadow(color: .black.opacity(0.05), radius: 5)
            
            if isSearching {
                Button("Hủy") {
                    withAnimation {
                        isSearching = false
                        searchText = ""
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }
                .foregroundColor(.blue)
            }
        }
    }
    
    private var cartButton: some View {
        Button {
            withAnimation(.spring(response: 0.3)) {
                showOrderSummary = true
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
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .blue.opacity(0.3), radius: 10, y: 5)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
    }
    
    // MARK: - Left side containing categories and menu items
    private func leftSideMenu(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            menuHeader(width: (geometry.size.width - 44) * 0.65)
            categoryScrollView()
            menuItemsGrid()
        }
        .frame(maxWidth: max((geometry.size.width) * 0.65, 0))
        .frame(maxHeight: .infinity)
        .background(Color.white.opacity(0.7))
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.vertical, 12)
    }
    
    private func menuHeader(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 12) {
        HStack {
                VStack(alignment: .leading) {
                    Text("Menu")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                    Text("Choose your favorite items")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            Spacer()
                
                // Shop info badge
                HStack {
                    Image(systemName: "storefront.fill")
                        .foregroundColor(.blue)
                    Text(appState.sourceModel.activatedShop?.shopName ?? "Shop")
                        .font(.caption.weight(.medium))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
            }
            
            searchField(width: width)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 8)
    }
    
    private func searchField(width: CGFloat) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .font(.system(size: 16, weight: .medium))
            
            TextField("Search for delicious items...", text: Binding(
                get: { viewModel.searchKey },
                set: { viewModel.updateSearchKey($0) }
            ))
            .font(.system(size: 16))
            .padding(.vertical, 12)
            .disableAutocorrection(true)
            
            if !viewModel.searchKey.isEmpty {
                Button {
                    viewModel.updateSearchKey("")
                } label: {
                    Image(systemName: "xmark.circle.fill")
                .foregroundColor(.gray)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemGray6))
                .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
    
    private func categoryScrollView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(viewModel.categories, id: \.self) { category in
                    ModernOptionButton(
                        title: category,
                        isSelected: viewModel.selectedCategory == category,
                        icon: categoryIcon(for: category)
                    ) {
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
    
    private func categoryIcon(for category: String) -> String {
        switch category.lowercased() {
        case "coffee": return "cup.and.saucer.fill"
        case "tea": return "leaf.fill"
        case "dessert": return "birthday.cake.fill"
        case "snack": return "takeoutbag.and.cup.and.straw.fill"
        default: return "circle.fill"
        }
    }
    
    private func menuItemsGrid() -> some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 20), count: 2),
                spacing: 24
            ) {
                ForEach(viewModel.filteredMenuItems) { item in
                    appState.coordinator.makeView(for: .orderMenuItemCard(item))
                    .matchedGeometryEffect(id: item.id, in: animation)
                    }
                }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
    }
    
    // MARK: - Right side containing order details
    private func rightSideOrder(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            userProfileHeader()
            orderHeader()
            orderItemsList(geometry: geometry)
            orderSummarySection()
            paymentMethodSection()
            paymentButton()
        }
        .padding(24)
        .frame(maxWidth: max((geometry.size.width) * 0.35, 300))
        .frame(maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white)
                .shadow(color: .black.opacity(0.1), radius: 15, x: 0, y: 5)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.blue.opacity(0.1), lineWidth: 1)
        )
        .padding(.vertical, 12)
    }
    
    private func userProfileHeader() -> some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                .frame(width: 60, height: 60)
                
                Text(String(appState.sourceModel.currentUser?.displayName.prefix(1) ?? "U"))
                    .font(.title2.bold())
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Good morning! ☀️")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(appState.sourceModel.currentUser?.displayName ?? "Welcome")
                    .font(.headline.weight(.semibold))
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Notification badge
            Button(action: {}) {
                Image(systemName: "bell.fill")
                    .foregroundColor(.blue)
                    .font(.system(size: 18))
            }
        }
        .padding(.bottom, 8)
    }
    
    private func orderHeader() -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Your Order")
                    .font(.title2.weight(.bold))
                HStack {
                    Text("\(viewModel.selectedItems.count) items")
                        .font(.caption)
                    .foregroundColor(.secondary)
                    if !viewModel.selectedItems.isEmpty {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 6, height: 6)
                    }
                }
            }
            
            Spacer()
            
            if !viewModel.selectedItems.isEmpty {
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.clearOrder()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                        Text("Clear")
                    }
                    .font(.caption.weight(.medium))
                    .foregroundColor(.red)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.1))
                    .clipShape(Capsule())
                }
            }
        }
    }
    
    private func orderItemsList(geometry: GeometryProxy) -> some View {
        ScrollView {
            if viewModel.selectedItems.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "cart")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("Your cart is empty")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Add some delicious items!")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 40)
            } else {
                LazyVStack(spacing: 16) {
                ForEach(viewModel.selectedItems) { item in
                        appState.coordinator.makeView(for: .orderItem(item))
                            .transition(
                                .asymmetric(
                                    insertion: .move(edge: .leading)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.8)),
                                    removal: .move(edge: .trailing)
                                        .combined(with: .opacity)
                                        .combined(with: .scale(scale: 0.8))
                                )
                            )
                            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: item)
                    }
                }
            }
        }
        .frame(height: geometry.size.height * 0.4)
    }
    
    private func orderSummarySection() -> some View {
        VStack(spacing: 12) {
            Divider()
            
            HStack {
                Text("Subtotal")
                    .font(.subheadline)
                Spacer()
                Text("\(viewModel.totalPrice)")
                    .font(.subheadline.weight(.medium))
    }
    
            Divider()
            
        HStack {
                Text("Total")
                    .font(.title3.weight(.bold))
            Spacer()
            Text(viewModel.totalPrice)
                    .font(.title3.weight(.bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
        }
        }
        .padding(.vertical, 8)
    }
    
    private func paymentMethodSection() -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Payment Method")
                .font(.headline.weight(.semibold))
            
            HStack(spacing: 12) {
                ForEach(PaymentMethod.allCases, id: \.self) { method in
                    PaymentMethodButton(method: method, isSelected: viewModel.paymentMethod == method) {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            viewModel.updatePaymentMethod(method)
                        }
                    }
                }
            }
        }
    }
    
    private func paymentButton() -> some View {
        Button {
            Task {
                do {
                    try await viewModel.createOrder()
                }
            }
        } label: {
            HStack {
                if viewModel.selectedItems.isEmpty {
                    Image(systemName: "cart.badge.plus")
                } else {
                    Image(systemName: "creditcard.fill")
                }
                
                Text(viewModel.selectedItems.isEmpty ? "Add Items First" : "Place Order")
                    .font(.headline.weight(.semibold))
            }
                .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
                .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        viewModel.selectedItems.isEmpty
                        ? AnyShapeStyle(Color.gray.opacity(0.3))
                        : AnyShapeStyle(LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        ))
                    )
                )
                .foregroundColor(.white)
            .shadow(color: viewModel.selectedItems.isEmpty ? .clear : .blue.opacity(0.3), radius: 8, x: 0, y: 4)
        }
        .disabled(viewModel.selectedItems.isEmpty)
        .scaleEffect(viewModel.selectedItems.isEmpty ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: viewModel.selectedItems.isEmpty)
        .padding(.top, 12)
    }
}

// MARK: - Modern Components
    
struct MenuItemCard: View {
    @ObservedObject var viewModel: OrderViewModel
    let item: MenuItem
    
    @State private var temperature: TemperatureOption = .hot
    @State private var consumption: ConsumptionOption = .stay
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Item Image
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color(.systemGray6), Color(.systemGray5)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .aspectRatio(16/9, contentMode: .fit)
                
        Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 12) {
        HStack {
                    Text(item.name)
                        .font(.headline.weight(.semibold))
                        .lineLimit(2)
            Spacer()
                    Text("$\(String(format: "%.2f", item.price))")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
                
                // Options selector
                VStack(alignment: .leading, spacing: 12) {
                    // Temperature selector
            HStack {
                ForEach(TemperatureOption.allCases, id: \.self) { option in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                        temperature = option
                    }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: option == .hot ? "thermometer.sun.fill" : "thermometer.snowflake")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(option.rawValue)
                                        .font(.caption2.weight(.medium))
            }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(temperature == option ? 
                                            (option == .hot ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2)) :
                                            Color(.systemGray6))
                                )
                                .foregroundColor(temperature == option ?
                                    (option == .hot ? .orange : .blue) :
                                    .gray)
        }
    }
                    }
                    
                    // Consumption selector
            HStack {
                ForEach(ConsumptionOption.allCases, id: \.self) { option in
                            Button {
                                withAnimation(.spring(response: 0.3)) {
                        consumption = option
                    }
                            } label: {
                                VStack(spacing: 6) {
                                    Image(systemName: option == .stay ? "house.fill" : "takeoutbag.and.cup.and.straw.fill")
                                        .font(.system(size: 16, weight: .medium))
                                    Text(option.rawValue)
                                        .font(.caption2.weight(.medium))
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(consumption == option ?
                                            Color.purple.opacity(0.2) :
                                            Color(.systemGray6))
                                )
                                .foregroundColor(consumption == option ? .purple : .gray)
    }
                        }
                    }
                }
                
                // Add button
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        viewModel.addItemToOrder(item, temperature, consumption)
            temperature = .hot
            consumption = .stay
                    }
                } label: {
        HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add to Cart")
                    }
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                )
                .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.1), radius: isHovered ? 10 : 5, x: 0, y: isHovered ? 5 : 2)
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
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

struct ModernOrderItemView: View {
    @ObservedObject var viewModel: OrderViewModel
    let item: OrderItem
    @State private var offset: CGFloat = 0
    @State private var showingDeleteButton = false
    
    private let deleteButtonWidth: CGFloat = 80
    
    var body: some View {
        ZStack {
            // Delete button background
            HStack {
                Spacer()
                
                Button {
                    withAnimation(.spring()) {
                        viewModel.removeOrderItem(itemId: item.id)
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "trash.fill")
                            .font(.system(size: 20, weight: .semibold))
                        Text("Xóa")
                            .font(.caption.weight(.medium))
                    }
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .frame(width: deleteButtonWidth)
                    .background(
                        LinearGradient(
                            colors: [Color.red, Color.red.opacity(0.8)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .shadow(color: .red.opacity(0.3), radius: 4, x: 0, y: 2)
                }
                .opacity(showingDeleteButton ? 1 : 0)
                .animation(.easeInOut(duration: 0.2), value: showingDeleteButton)
            }
            
            // Main content
            HStack(spacing: 12) {
                // Item image
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color(.systemGray6), Color(.systemGray5)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "cup.and.saucer.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                // Item details
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        // Temperature badge
                        HStack(spacing: 4) {
                            Image(systemName: item.temperature == .hot ? "thermometer.sun.fill" : "thermometer.snowflake")
                                .font(.system(size: 10))
                            Text(item.temperature.rawValue)
                                .font(.caption2.weight(.medium))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(item.temperature == .hot ? Color.orange.opacity(0.2) : Color.blue.opacity(0.2))
                        .foregroundColor(item.temperature == .hot ? .orange : .blue)
                        .clipShape(Capsule())
                        
                        // Consumption badge
                        HStack(spacing: 4) {
                            Image(systemName: item.consumption == .stay ? "house.fill" : "takeoutbag.and.cup.and.straw.fill")
                                .font(.system(size: 10))
                            Text(item.consumption.rawValue)
                                .font(.caption2.weight(.medium))
                        }
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.purple.opacity(0.2))
                        .foregroundColor(.purple)
                        .clipShape(Capsule())
                    }
                }
                
                Spacer()
                
                // Quantity controls and price
                VStack(spacing: 8) {
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.spring()) {
                                if item.quantity > 1 {
                                    viewModel.updateOrderItemQuantity(for: item.id, increment: false)
                                } else {
                                    // Xóa item khi quantity sẽ < 1
                                    viewModel.removeOrderItem(itemId: item.id)
                                }
                            }
                        } label: {
                            Image(systemName: item.quantity > 1 ? "minus.circle.fill" : "trash.circle.fill")
                                .foregroundColor(item.quantity > 1 ? .red : .red)
                                .font(.system(size: 20))
                        }
                        
                        Text("\(item.quantity)")
                            .font(.subheadline.weight(.bold))
                            .frame(minWidth: 20)
                        
                        Button {
                            withAnimation(.spring()) {
                                viewModel.updateOrderItemQuantity(for: item.id, increment: true)
                            }
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 20))
                        }
                    }
                    
                    Text("$\(String(format: "%.2f", item.price))")
                        .font(.caption.weight(.bold))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                }
            }
            .padding(12)
            .background(Color(.systemGray6).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .offset(x: offset)
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let dragAmount = value.translation.width
                        if dragAmount < 0 {
                            offset = max(dragAmount, -deleteButtonWidth)
                        }
                    }
                    .onEnded { value in
                        let dragAmount = value.translation.width
                        withAnimation(.spring()) {
                            if dragAmount < -deleteButtonWidth / 2 {
                                // Mở hoàn toàn nút xóa
                                offset = -deleteButtonWidth
                                showingDeleteButton = true
                            } else {
                                // Quay về vị trí ban đầu
                                offset = 0
                                showingDeleteButton = false
                            }
                        }
                    }
            )
        }
        .clipped()
    }
}

struct ModernOptionButton: View {
    let title: String
    let isSelected: Bool
    let icon: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
            Text(title)
                    .font(.subheadline.weight(.medium))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(
                        isSelected
                        ? LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        : LinearGradient(
                            colors: [Color(.systemGray5), Color(.systemGray5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
            )
                .foregroundColor(isSelected ? .white : .primary)
        }
        .scaleEffect(isSelected ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
    }
}

struct PaymentMethodButton: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.blue : Color(.systemGray5))
                    .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 4, x: 0, y: 2)
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
        }
    
//    private func paymentIcon(for method: PaymentMethod) -> String {
//        switch method {
//        case .cash: return "banknote.fill"
//        case .card: return "creditcard.fill"
//        case .bankTransfer: return "iphone"
//        }
//    }
}

// MARK: - Compact Menu Item Card for iPhone
struct CompactMenuItemCard: View {
    @ObservedObject var viewModel: OrderViewModel
    let item: MenuItem
    @State private var isExpanded = false
    @State private var selectedTemperature: TemperatureOption = .hot
    @State private var selectedConsumption: ConsumptionOption = .stay
    
    var body: some View {
        VStack(spacing: 12) {
            // Item Image
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .aspectRatio(1, contentMode: .fit)
                
                Image(systemName: "cup.and.saucer.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Text(item.name)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)
                
                Text("$\(String(format: "%.2f", item.price))")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        isExpanded.toggle()
                    }
                } label: {
                    Text(isExpanded ? "Thu gọn" : "Tùy chọn")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.blue)
                }
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        QuickOptionRow(
                            title: "Nhiệt:",
                            options: TemperatureOption.allCases,
                            selection: $selectedTemperature
                        )
                        
                        QuickOptionRow(
                            title: "Loại:",
                            options: ConsumptionOption.allCases,
                            selection: $selectedConsumption
                        )
                    }
                    .transition(.scale.combined(with: .opacity))
                }
                
                Button {
                    withAnimation(.spring(response: 0.3)) {
                        viewModel.addItemToOrder(item, selectedTemperature, selectedConsumption)
                        // Reset về giá trị mặc định sau khi thêm
                        selectedTemperature = .hot
                        selectedConsumption = .stay
                        isExpanded = false
                    }
                } label: {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Thêm")
                    }
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                    .background(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 12)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 5)
    }
}

// MARK: - Order Summary Sheet
struct OrderSummarySheet: View {
    @ObservedObject var viewModel: OrderViewModel
    @Binding var isPresented: Bool
    @State private var dragOffset: CGFloat = 0
    @State private var selectedPaymentMethod: PaymentMethod = .cash
    
    var body: some View {
        VStack(spacing: 0) {
            // Drag Indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray3))
                .frame(width: 40, height: 5)
                .padding(.top, 8)
            
            ScrollView {
                VStack(spacing: 20) {
                    // Order Items
                    ForEach(viewModel.selectedItems) { item in
                        ModernOrderItemView(viewModel: viewModel, item: item)
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
                                    LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                        }
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    
                    // Payment Method Selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Phương thức thanh toán")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(PaymentMethod.allCases, id: \.self) { method in
                                    PaymentOptionCard(
                                        method: method,
                                        isSelected: method == selectedPaymentMethod
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            selectedPaymentMethod = method
                                            viewModel.updatePaymentMethod(method)
                                        }
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
                            try await viewModel.createOrder()
                            withAnimation {
                                isPresented = false
                            }
                        }
                    } label: {
                        Text("Đặt hàng")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(16)
                    }
                }
                .padding()
                .background(Color(.systemBackground))
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(24)
        .offset(y: dragOffset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    let translation = value.translation.height
                    if translation > 0 {
                        dragOffset = translation
                    }
                }
                .onEnded { value in
                    let translation = value.translation.height
                    withAnimation(.spring(response: 0.3)) {
                        if translation > 100 {
                            isPresented = false
                        } else {
                            dragOffset = 0
                        }
                    }
                }
        )
        .frame(maxHeight: UIScreen.main.bounds.height * 0.85)
        .frame(maxWidth: .infinity)
        .transition(.move(edge: .bottom))
    }
}

// MARK: - Payment Option Card
struct PaymentOptionCard: View {
    let method: PaymentMethod
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                // Icon
                ZStack {
                    Circle()
                        .fill(isSelected ? method.color.opacity(0.15) : Color(.systemGray5))
                        .frame(width: 40, height: 40)
                    
                    Image(systemName: method.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isSelected ? method.color : .gray)
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
                        .stroke(isSelected ? method.color : Color(.systemGray4), lineWidth: 2)
                        .frame(width: 20, height: 20)
                    
                    if isSelected {
                        Circle()
                            .fill(method.color)
                            .frame(width: 12, height: 12)
                    }
                }
            }
                .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: isSelected ? method.color.opacity(0.3) : .black.opacity(0.05),
                           radius: isSelected ? 8 : 4,
                           x: 0,
                           y: isSelected ? 4 : 2)
            )
        }
        .scaleEffect(isSelected ? 1.02 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
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
        switch self {
        case .cash:
            return .green
        case .card:
            return .blue
        case .bankTransfer:
            return .purple
        }
    }
}
