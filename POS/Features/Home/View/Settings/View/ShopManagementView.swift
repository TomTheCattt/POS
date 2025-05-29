import SwiftUI

struct ShopManagementView: View {
    @StateObject var viewModel: ShopManagementViewModel
    @EnvironmentObject private var appState: AppState
    @State private var isShowingShopList = false
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Top Bar
                VStack(spacing: 16) {
                    // Shop Selector
                    Button {
                        withAnimation(.spring()) {
                            isShowingShopList.toggle()
                        }
                    } label: {
                        HStack {
                            Text(viewModel.selectedShop?.shopName ?? "Chọn cửa hàng")
                                .font(.headline)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 14, weight: .semibold))
                                .rotationEffect(.degrees(isShowingShopList ? 180 : 0))
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 1)
                    }
                    
                    // Search Bar
                    HStack(spacing: 16) {
                        // Search Field
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.gray)
                            TextField(viewModel.searchPlaceholder, text: $viewModel.searchText)
                        }
                        .padding()
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 1)
                        
                        // Toggle Buttons
                        HStack(spacing: 0) {
                            toggleButton(
                                title: "Menu",
                                systemImage: "list.bullet",
                                isSelected: viewModel.currentView == .menu
                            ) {
                                if viewModel.currentView != .menu {
                                    viewModel.toggleView()
                                }
                            }
                            
                            toggleButton(
                                title: "Kho",
                                systemImage: "cube.box",
                                isSelected: viewModel.currentView == .inventory
                            ) {
                                if viewModel.currentView != .inventory {
                                    viewModel.toggleView()
                                }
                            }
                        }
                        .background(Color(.systemBackground))
                        .cornerRadius(10)
                        .shadow(radius: 1)
                    }
                }
                .padding()
                .background(
                    Color(.systemGroupedBackground)
                        .cornerRadius(16)
                        .shadow(radius: 2)
                )
                
                // Content Area
                ZStack {
                    // Menu View
                    if viewModel.currentView == .menu {
                        MenuContentView(
                            viewModel: MenuViewModel(source: appState.sourceModel),
                            searchText: $viewModel.searchText
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                    }
                    
                    // Inventory View
                    if viewModel.currentView == .inventory {
                        InventoryContentView(
                            viewModel: InventoryViewModel(source: appState.sourceModel),
                            searchText: $viewModel.searchText
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .trailing),
                            removal: .move(edge: .trailing)
                        ))
                    }
                }
                .animation(.easeInOut, value: viewModel.currentView)
            }
            
            // Shop List Overlay
            if isShowingShopList {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        withAnimation(.spring()) {
                            isShowingShopList = false
                        }
                    }
                
                VStack(spacing: 0) {
                    ForEach(viewModel.shops) { shop in
                        Button {
                            Task {
                                await viewModel.selectShop(shop)
                                withAnimation(.spring()) {
                                    isShowingShopList = false
                                }
                            }
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(shop.shopName)
                                        .font(.headline)
                                }
                                
                                Spacer()
                                
                                if shop.id == viewModel.selectedShop?.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding()
                            .background(
                                shop.id == viewModel.selectedShop?.id ? 
                                    Color.blue.opacity(0.1) : Color.clear
                            )
                        }
                        .foregroundColor(.primary)
                        
                        if shop.id != viewModel.shops.last?.id {
                            Divider()
                        }
                    }
                }
                .background(Color(.systemBackground))
                .cornerRadius(12)
                .shadow(radius: 5)
                .padding(.horizontal)
                .padding(.top, 70)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
    
    private func toggleButton(
        title: String,
        systemImage: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Image(systemName: systemImage)
                Text(title)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(isSelected ? Color.blue : Color.clear)
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Supporting Views
struct MenuContentView: View {
    @ObservedObject var viewModel: MenuViewModel
    @Binding var searchText: String
    @State private var showingAddItemSheet = false
    @State private var selectedItem: MenuItem?
    @State private var showingItemDetail = false
    
    var body: some View {
        VStack {
            if viewModel.filteredMenuItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    menuGrid
                }
            }
        }
        .sheet(isPresented: $showingAddItemSheet) {
            AddMenuItemView(viewModel: viewModel)
        }
        .sheet(item: $selectedItem) { item in
            MenuItemDetailView(item: item, viewModel: viewModel)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tray.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Chưa có món nào trong menu")
                .font(.title2)
                .foregroundColor(.gray)
            
            Button {
                showingAddItemSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Thêm món mới")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var menuGrid: some View {
        LazyVGrid(columns: [
            GridItem(.adaptive(minimum: 160), spacing: 16)
        ], spacing: 16) {
            ForEach(viewModel.filteredMenuItems) { item in
                MenuItemCard(item: item) {
                    selectedItem = item
                    showingItemDetail = true
                }
            }
            
            addButton
        }
        .padding()
    }
    
    private var addButton: some View {
        Button {
            showingAddItemSheet = true
        } label: {
            VStack {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 40))
                Text("Thêm món mới")
                    .font(.headline)
            }
            .frame(height: 200)
            .frame(maxWidth: .infinity)
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(12)
        }
    }
}

struct InventoryContentView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @Binding var searchText: String
    @State private var showingAddItemSheet = false
    @State private var selectedItem: InventoryItem?
    @State private var showingItemDetail = false
    
    var body: some View {
        VStack {
            if viewModel.filteredItems.isEmpty {
                emptyStateView
            } else {
                ScrollView {
                    inventoryList
                }
            }
        }
        .sheet(isPresented: $showingAddItemSheet) {
            AddInventoryItemView(viewModel: viewModel)
        }
        .sheet(item: $selectedItem) { item in
            InventoryItemDetailView(item: item, viewModel: viewModel)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "cube.box.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("Chưa có sản phẩm nào trong kho")
                .font(.title2)
                .foregroundColor(.gray)
            
            Button {
                showingAddItemSheet = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Thêm sản phẩm mới")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var inventoryList: some View {
        List {
            ForEach(viewModel.filteredItems) { item in
                InventoryItemRow(
                    item: item,
                    isSelected: false,
                    isMultiSelectMode: false
                ) { _ in
                    selectedItem = item
                    showingItemDetail = true
                }
            }
            
            addButton
        }
    }
    
    private var addButton: some View {
        Button {
            showingAddItemSheet = true
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Thêm sản phẩm mới")
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue.opacity(0.1))
            .foregroundColor(.blue)
            .cornerRadius(8)
        }
        .listRowInsets(EdgeInsets())
        .padding(.vertical, 8)
    }
} 
