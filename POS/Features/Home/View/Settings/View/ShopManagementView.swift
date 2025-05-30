import SwiftUI

extension View {
    func optimizedShadow() -> some View {
        self.background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 1,
                    x: 0,
                    y: 1
                )
        )
    }
}

struct ShopManagementView: View {
    @StateObject var viewModel: ShopManagementViewModel
    @EnvironmentObject private var appState: AppState
    @State private var isShowingShopList = false
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                // Top Bar
                shopSelectorView
                
                // Content Area
                contentView
            }
            
            // Shop List Overlay
            if isShowingShopList {
                shopListOverlay
            }
        }
    }
    
    private var shopSelectorView: some View {
        VStack(spacing: 16) {
            // Shop Selector
            HStack(spacing: 16) {
                Button {
                    withAnimation(.spring()) {
                        isShowingShopList.toggle()
                    }
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Cửa hàng hiện tại")
                                .font(.caption)
                                .foregroundColor(.gray)
                            
                            HStack {
                                Text(viewModel.selectedShop?.shopName ?? "Chọn cửa hàng")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                Image(systemName: "chevron.down")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .rotationEffect(.degrees(isShowingShopList ? 180 : 0))
                            }
                        }
                        
                        Spacer()
                        
                        Circle()
                            .fill(viewModel.selectedShop != nil ? Color.green : Color.gray)
                            .frame(width: 8, height: 8)
                    }
                    .padding()
                    .background(Color(.systemBackground))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                    )
                    .shadow(
                        color: Color.black.opacity(0.05),
                        radius: 2,
                        x: 0,
                        y: 1
                    )
                }
                
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
                .cornerRadius(12)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 2,
                    x: 0,
                    y: 1
                )
            }
        }
        .padding()
        .background(
            Color(.systemGroupedBackground)
                .cornerRadius(16)
                .shadow(
                    color: Color.black.opacity(0.05),
                    radius: 3,
                    x: 0,
                    y: 2
                )
        )
    }
    
    private var shopListOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring()) {
                        isShowingShopList = false
                    }
                }
            
            VStack(alignment: .leading, spacing: 0) {
                Text("Chọn cửa hàng")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemBackground))
                
                Divider()
                
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.shops) { shop in
                            Button {
                                Task {
                                    await viewModel.selectShop(shop)
                                    withAnimation(.spring()) {
                                        isShowingShopList = false
                                    }
                                }
                            } label: {
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(shop.shopName)
                                            .font(.body)
                                            .foregroundColor(.primary)
                                        
                                        Text("ID: \(shop.id)")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    
                                    Spacer()
                                    
                                    if shop.id == viewModel.selectedShop?.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                            .font(.system(size: 20))
                                    }
                                }
                                .padding()
                                .background(
                                    shop.id == viewModel.selectedShop?.id ?
                                        Color.blue.opacity(0.1) : Color.clear
                                )
                            }
                            
                            if shop.id != viewModel.shops.last?.id {
                                Divider()
                                    .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .background(Color(.systemBackground))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.1), lineWidth: 1)
            )
            .shadow(
                color: Color.black.opacity(0.1),
                radius: 10,
                x: 0,
                y: 5
            )
            .padding(.horizontal)
            .padding(.top, 70)
            .frame(maxHeight: UIScreen.main.bounds.height * 0.7)
        }
        .transition(.move(edge: .top).combined(with: .opacity))
    }
    
    private var contentView: some View {
        ZStack {
            if viewModel.currentView == .menu {
                UpdateMenuView(viewModel: MenuViewModel(source: appState.sourceModel))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            }
            
            if viewModel.currentView == .inventory {
                UpdateInventoryView(viewModel: InventoryViewModel(source: appState.sourceModel))
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing),
                        removal: .move(edge: .trailing)
                    ))
            }
        }
        .animation(.easeInOut, value: viewModel.currentView)
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
            if viewModel.inventoryItems.isEmpty {
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
            ForEach(viewModel.inventoryItems) { item in
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
