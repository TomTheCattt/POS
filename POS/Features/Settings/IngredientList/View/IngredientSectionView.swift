//
//  UpdateIngredientView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct IngredientSectionView: View {
    @ObservedObject private var viewModel: IngredientViewModel
    @EnvironmentObject private var appState: AppState
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isMultiSelectMode = false
    @State private var selectedItems: Set<IngredientUsage> = []
    @State private var showingBatchUpdateSheet = false
    @State private var showingImportSheet = false
    @State private var showingHistorySheet = false
    @State private var selectedAction: ActionType?
    @State private var showingSearchBar = false
    @State private var animateHeader = false
    
    private var shop: Shop?
    
    var totalInventoryValue: Double {
        viewModel.filteredAndSortedItems.reduce(0) { total, item in
            total + (item.costPrice * item.quantity)
        }
    }
    
    var lowStockItemsCount: Int {
        viewModel.filteredAndSortedItems.filter { $0.stockStatus == .lowStock }.count
    }
    
    var outOfStockItemsCount: Int {
        viewModel.filteredAndSortedItems.filter { $0.stockStatus == .outOfStock }.count
    }
    
    init(viewModel: IngredientViewModel, shop: Shop?) {
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
    }
    
    // MARK: - Empty State View
    private var emptyStateView: some View {
        VStack(spacing: isIphone ? 20 : 32) {
            Spacer()
            
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: isIphone ? 60 : 80))
                .foregroundStyle(
                    appState.currentTabThemeColors.gradient(for: colorScheme)
                )
            
            VStack(spacing: isIphone ? 12 : 16) {
                Text("Chưa có cửa hàng nào")
                    .font(.system(size: isIphone ? 20 : 28, weight: .semibold))
                
                Text("Bạn cần tạo cửa hàng trước khi quản lý kho")
                    .font(.system(size: isIphone ? 16 : 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, isIphone ? 40 : 60)
            }
            
            VStack {
                Label("Tạo cửa hàng mới", systemImage: "plus.circle.fill")
                    .font(.system(size: isIphone ? 16 : 18, weight: .semibold))
                    .padding()
                    .frame(maxWidth: isIphone ? .infinity : 300)
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
                        appState.coordinator.navigateTo(.addShop(nil), using: .present, with: .present)
                    }
            }
            .padding(.horizontal, isIphone ? 40 : 60)
            .padding(.top, 10)
            
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
            
            // Quick Stats
            quickStatsSection
                .opacity(animateHeader ? 1 : 0)
                .offset(y: animateHeader ? 0 : -20)
            
            if viewModel.filteredAndSortedItems.isEmpty {
                emptyInventoryStateView
            } else {
                // Search Bar
                if showingSearchBar {
                    EnhancedSearchBar(
                        text: Binding(
                            get: { viewModel.searchKey },
                            set: { viewModel.updateSearchKey($0) }
                        ),
                        placeholder: "Tìm kiếm sản phẩm..."
                    )
                    .transition(.asymmetric(
                        insertion: .scale.combined(with: .opacity),
                        removal: .scale.combined(with: .opacity)
                    ))
                    .padding(.horizontal)
                    .padding(.bottom, 8)
                }
                
                // Filters
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: isIphone ? 12 : 16) {
                        // Stock status filter
                        Menu {
                            Picker("Trạng thái", selection: Binding(
                                get: { viewModel.selectedStockStatus },
                                set: { viewModel.updateSelectedStockStatus($0) }
                            )) {
                                Text("Tất cả").tag(Optional<IngredientUsage.StockStatus>.none)
                                Text("Còn hàng").tag(Optional<IngredientUsage.StockStatus>.some(.inStock))
                                Text("Sắp hết").tag(Optional<IngredientUsage.StockStatus>.some(.lowStock))
                                Text("Hết hàng").tag(Optional<IngredientUsage.StockStatus>.some(.outOfStock))
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                    .font(.system(size: isIphone ? 14 : 16))
                                Text(viewModel.selectedStockStatus?.description ?? "Tất cả")
                                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                            }
                            .padding(.horizontal, isIphone ? 12 : 16)
                            .padding(.vertical, isIphone ? 8 : 12)
                            .background(
                                Capsule()
                                    .fill(Color(.systemBackground))
                            )
                            .foregroundColor(.primary)
                        }
                        
                        // Sort order
                        Menu {
                            Picker("Sắp xếp", selection: $viewModel.sortOrder) {
                                Text("Tên A-Z").tag(IngredientViewModel.SortOrder.name)
                                Text("Số lượng").tag(IngredientViewModel.SortOrder.quantity)
                                Text("Cập nhật").tag(IngredientViewModel.SortOrder.lastUpdated)
                            }
                        } label: {
                            HStack(spacing: 6) {
                                Image(systemName: "arrow.up.arrow.down.circle.fill")
                                    .font(.system(size: isIphone ? 14 : 16))
                                Text("Sắp xếp")
                                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                            }
                            .padding(.horizontal, isIphone ? 12 : 16)
                            .padding(.vertical, isIphone ? 8 : 12)
                            .background(
                                Capsule()
                                    .fill(Color(.systemBackground))
                            )
                            .foregroundColor(.primary)
                        }
                        
                        // Low stock filter
                        Button(action: { viewModel.showLowStockOnly.toggle() }) {
                            HStack(spacing: 6) {
                                Image(systemName: viewModel.showLowStockOnly ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                                    .font(.system(size: isIphone ? 14 : 16))
                                Text("Sắp hết hàng")
                                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                            }
                            .padding(.horizontal, isIphone ? 12 : 16)
                            .padding(.vertical, isIphone ? 8 : 12)
                            .background(
                                Capsule()
                                    .fill(Color(.systemBackground))
                            )
                            .foregroundColor(viewModel.showLowStockOnly ? .orange : .primary)
                        }
                        
                        // Multi-select mode
                        Button(action: { isMultiSelectMode.toggle() }) {
                            HStack(spacing: 6) {
                                Image(systemName: isMultiSelectMode ? "checkmark.circle.fill" : "checkmark.circle")
                                    .font(.system(size: isIphone ? 14 : 16))
                                Text("Chọn nhiều")
                                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                            }
                            .padding(.horizontal, isIphone ? 12 : 16)
                            .padding(.vertical, isIphone ? 8 : 12)
                            .background(
                                Capsule()
                                    .fill(Color(.systemBackground))
                            )
                            .foregroundColor(isMultiSelectMode ? .blue : .primary)
                        }
                    }
                    .padding(.horizontal, isIphone ? 16 : 24)
                }
                .padding(.vertical, isIphone ? 8 : 12)
                
                // Action Buttons when in multi-select mode
                if isMultiSelectMode && !selectedItems.isEmpty {
                    multiSelectActionView
                }
                
                // Inventory List
                ScrollView(showsIndicators: false) {
                    LazyVStack(spacing: isIphone ? 12 : 16) {
                        ForEach(viewModel.filteredAndSortedItems) { item in
                            IngredientUsageItem(
                                item: item,
                                isSelected: selectedItems.contains(item),
                                isMultiSelectMode: isMultiSelectMode
                            ) { item in
                                if isMultiSelectMode {
                                    toggleItemSelection(item)
                                } else {
                                    viewModel.selectedItem = item
                                    appState.coordinator.navigateTo(.ingredientForm(viewModel.selectedItem), using: .present, with: .present)
                                }
                            }
                            .padding(.horizontal, isIphone ? 16 : 24)
                        }
                    }
                }
                .padding(.vertical)
                
                // Bottom Toolbar
                bottomToolbarView
                    .background(
                        Rectangle()
                            .fill(.ultraThinMaterial)
                            .edgesIgnoringSafeArea(.bottom)
                    )
            }
        }
        .navigationTitle("Quản lý kho")
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
                        viewModel.selectedItem = nil
                        appState.coordinator.navigateTo(.ingredientForm(viewModel.selectedItem), using: .present, with: .present)
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: isIphone ? 18 : 20))
                            .foregroundStyle(
                                appState.currentTabThemeColors.gradient(for: colorScheme)
                            )
                    }
                }
            }
        }
        .background(
            appState.currentTabThemeColors.softGradient(for: colorScheme)
        )
        .sheet(isPresented: $showingBatchUpdateSheet) {
            BatchUpdateView(items: Array(selectedItems))
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDataView()
        }
        .sheet(isPresented: $showingHistorySheet) {
            InventoryHistoryView()
        }
        .overlay {
            if viewModel.isLoading {
                ProgressView()
                    .scaleEffect(1.5)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.2))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateHeader = true
            }
            appState.sourceModel.setupIngredientsListener(shopId: shop?.id ?? "")
        }
        .onDisappear {
            appState.sourceModel.removeIngredientsListener(shopId: shop?.id ?? "")
        }
    }
    
    // MARK: - Empty Inventory State View
    private var emptyInventoryStateView: some View {
        VStack(spacing: isIphone ? 20 : 32) {
            Spacer()
            
            Image(systemName: "cube.box.fill")
                .font(.system(size: isIphone ? 60 : 80))
                .foregroundStyle(
                    appState.currentTabThemeColors.gradient(for: colorScheme)
                )
            
            VStack(spacing: isIphone ? 12 : 16) {
                Text("Chưa có sản phẩm nào trong kho")
                    .font(.system(size: isIphone ? 20 : 28, weight: .semibold))
                
                Text("Hãy thêm sản phẩm đầu tiên vào kho của bạn")
                    .font(.system(size: isIphone ? 16 : 18))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, isIphone ? 40 : 60)
            }
            
            VStack(spacing: isIphone ? 12 : 16) {
                VStack {
                    Label("Thêm sản phẩm mới", systemImage: "plus.circle.fill")
                        .font(.system(size: isIphone ? 16 : 18, weight: .semibold))
                        .padding()
                        .frame(maxWidth: isIphone ? .infinity : 300)
                        .foregroundColor(.white)
                        .cornerRadius(16)
                        .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
                            viewModel.selectedItem = nil
                            appState.coordinator.navigateTo(.ingredientForm(viewModel.selectedItem), using: .present, with: .present)
                        }
                }
                .padding(.horizontal, isIphone ? 40 : 60)
                .padding(.top, 10)
                
                // Suggestion for importing data
                Button {
                    showingImportSheet = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.and.arrow.down.fill")
                            .font(.system(size: isIphone ? 14 : 16))
                        Text("Hoặc nhập từ Excel/CSV")
                            .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                    }
                    .foregroundColor(.blue)
                }
                .padding(.top, 5)
            }
            
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
                        Image(systemName: "cube.box.fill")
                            .font(.system(size: isIphone ? 20 : 24))
                            .foregroundStyle(
                                appState.currentTabThemeColors.gradient(for: colorScheme)
                            )
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(viewModel.filteredAndSortedItems.count) sản phẩm")
                                .font(.system(size: isIphone ? 16 : 18, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            if !viewModel.searchKey.isEmpty {
                                Text("Kết quả tìm kiếm cho \"\(viewModel.searchKey)\"")
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
    
    private var quickStatsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: isIphone ? 16 : 20) {
                // Tổng giá trị kho
                statsCard(
                    title: "Tổng giá trị",
                    value: totalInventoryValue.formatted(.currency(code: "VND")),
                    icon: "dollarsign.circle.fill",
                    color: appState.currentTabThemeColors.primaryColor
                )
                
                // Số lượng sắp hết
                statsCard(
                    title: "Sắp hết",
                    value: "\(lowStockItemsCount) sản phẩm",
                    icon: "exclamationmark.triangle.fill",
                    color: .orange
                )
                
                // Số lượng hết hàng
                statsCard(
                    title: "Hết hàng",
                    value: "\(outOfStockItemsCount) sản phẩm",
                    icon: "xmark.circle.fill",
                    color: .red
                )
            }
            .padding(.horizontal, isIphone ? 16 : 24)
        }
    }
    
    private func statsCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: isIphone ? 12 : 16) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: isIphone ? 18 : 20))
                    .foregroundColor(color)
                
                Text(title)
                    .font(.system(size: isIphone ? 12 : 14, weight: .medium))
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.system(size: isIphone ? 16 : 18, weight: .semibold))
                .foregroundColor(.primary)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(isIphone ? 16 : 20)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    private var multiSelectActionView: some View {
        HStack(spacing: isIphone ? 16 : 20) {
            Button(action: {
                showingBatchUpdateSheet = true
            }) {
                Label("Cập nhật hàng loạt", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, isIphone ? 16 : 20)
                    .padding(.vertical, isIphone ? 8 : 12)
                    .background(
                        appState.currentTabThemeColors.gradient(for: colorScheme)
                    )
                    .cornerRadius(20)
            }
            
            Spacer()
            
            Button(action: {
                selectedItems.removeAll()
                isMultiSelectMode = false
            }) {
                Label("Hủy", systemImage: "xmark.circle.fill")
                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, isIphone ? 16 : 20)
                    .padding(.vertical, isIphone ? 8 : 12)
                    .background(Color.red.gradient)
                    .cornerRadius(20)
            }
        }
        .padding(isIphone ? 16 : 20)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    private var bottomToolbarView: some View {
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
                .foregroundStyle(
                    appState.currentTabThemeColors.gradient(for: colorScheme)
                )
                .padding(.horizontal, isIphone ? 16 : 20)
                .padding(.vertical, isIphone ? 8 : 12)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
            }
            
            Spacer()
            
            Button(action: {
                viewModel.selectedItem = nil
                appState.coordinator.navigateTo(.ingredientForm(viewModel.selectedItem), using: .present, with: .present)
            }) {
                Label("Thêm sản phẩm", systemImage: "plus.circle.fill")
                    .font(.system(size: isIphone ? 16 : 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, isIphone ? 16 : 20)
                    .padding(.vertical, isIphone ? 8 : 12)
                    .background(
                        appState.currentTabThemeColors.gradient(for: colorScheme)
                    )
                    .cornerRadius(20)
            }
        }
        .padding(isIphone ? 16 : 20)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    private func toggleItemSelection(_ item: IngredientUsage) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
    
    private func handleSaveItem(_ item: IngredientUsage) {
        Task {
            do {
                if let existingItem = viewModel.selectedItem {
                    try await viewModel.updateIngredientUsage(existingItem)
                } else {
                    try await viewModel.createIngredientUsage(item)
                }
                
                // Only dismiss if no validation errors
                if viewModel.getValidationErrors().isEmpty {
                    viewModel.showEditItemSheet = false
                }
            } catch {
                // Error is already handled in the view model
            }
        }
    }
}

// MARK: - Supporting Views
struct IngredientUsageItem: View {
    let item: IngredientUsage
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: (IngredientUsage) -> Void
    
    private var availableAmount: Double {
        item.totalMeasurement - item.used
    }
    
    private var percentageUsed: Double {
        guard item.totalMeasurement > 0 else { return 0 }
        return (item.used / item.totalMeasurement) * 100
    }
    
    var body: some View {
        VStack(spacing: isIphone ? 12 : 16) {
            HStack(alignment: .top) {
                // Checkbox cho multi-select mode
                if isMultiSelectMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .foregroundColor(isSelected ? .accentColor : .gray)
                        .font(.system(size: isIphone ? 20 : 24))
                }
                
                // Thông tin chính
                VStack(alignment: .leading, spacing: isIphone ? 6 : 8) {
                    // Tên và trạng thái
                    HStack {
                        Text(item.name)
                            .font(.system(size: isIphone ? 18 : 20, weight: .semibold))
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        
                        Spacer()
                        
                        stockStatusBadge
                    }
                    
                    // Thông tin số lượng
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            // Số lượng đơn vị
                            HStack(spacing: 4) {
                                Image(systemName: "cube.box")
                                    .foregroundColor(.gray)
                                    .font(.system(size: isIphone ? 12 : 14))
                                Text("\(String(format: "%.1f", item.quantity)) \(item.measurementPerUnit.unit.shortDisplayName)")
                                    .font(.system(size: isIphone ? 14 : 16, weight: .medium))
                            }
                            
                            // Tổng định lượng
                            HStack(spacing: 4) {
                                Image(systemName: "sum")
                                    .foregroundColor(.gray)
                                    .font(.system(size: isIphone ? 12 : 14))
                                Text("\(String(format: "%.1f", availableAmount))/\(String(format: "%.1f", item.totalMeasurement)) \(item.measurementPerUnit.unit.shortDisplayName)")
                                    .font(.system(size: isIphone ? 14 : 16))
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Spacer()
                        
                        // Hiển thị phần trăm đã sử dụng
                        ZStack {
                            Circle()
                                .stroke(lineWidth: 4)
                                .opacity(0.3)
                                .foregroundColor(item.stockStatus.color)
                            
                            Circle()
                                .trim(from: 0.0, to: min(CGFloat(percentageUsed) / 100, 1.0))
                                .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
                                .foregroundColor(item.stockStatus.color)
                                .rotationEffect(Angle(degrees: 270.0))
                            
                            Text("\(Int(percentageUsed))%")
                                .font(.system(size: isIphone ? 12 : 14, weight: .bold))
                        }
                        .frame(width: isIphone ? 40 : 48, height: isIphone ? 40 : 48)
                    }
                    
                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            Rectangle()
                                .frame(width: geometry.size.width, height: 6)
                                .opacity(0.3)
                                .foregroundColor(item.stockStatus.color)
                            
                            Rectangle()
                                .frame(width: min(CGFloat(percentageUsed) / 100 * geometry.size.width, geometry.size.width), height: 6)
                                .foregroundColor(item.stockStatus.color)
                        }
                        .cornerRadius(3)
                    }
                    .frame(height: 6)
                    
                    // Thông tin bổ sung
                    HStack(spacing: isIphone ? 16 : 20) {
                        // Giá nhập
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle")
                                .foregroundColor(.gray)
                                .font(.system(size: isIphone ? 12 : 14))
                            Text("\(Int(item.costPrice))₫")
                                .font(.system(size: isIphone ? 12 : 14))
                                .foregroundColor(.secondary)
                        }
                        
                        // Số lượng tối thiểu
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.gray)
                                .font(.system(size: isIphone ? 12 : 14))
                            Text("Min: \(Int(item.minQuantity)) \(item.measurementPerUnit.unit.shortDisplayName)")
                                .font(.system(size: isIphone ? 12 : 14))
                                .foregroundColor(.secondary)
                        }
                        
                        // Thời gian cập nhật
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.gray)
                                .font(.system(size: isIphone ? 12 : 14))
                            Text(item.updatedAt.formatted(.relative(presentation: .named)))
                                .font(.system(size: isIphone ? 12 : 14))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(isIphone ? 16 : 20)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(item)
        }
    }
    
    private var stockStatusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: item.stockStatus.systemImage)
                .font(.system(size: isIphone ? 12 : 14))
            Text(item.stockStatus.description)
                .font(.system(size: isIphone ? 12 : 14, weight: .medium))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(item.stockStatus.color.opacity(0.2))
        .foregroundColor(item.stockStatus.color)
        .clipShape(Capsule())
    }
}

struct SearchBar: View {
    @Binding var text: String
    let placeholder: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
            
            TextField(placeholder, text: $text)
                .keyboardType(.default)
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

enum ActionType {
    case `import`
    case export
    case history
}

struct IngredientUsageFormView: View {
    @ObservedObject var viewModel: IngredientViewModel
    @EnvironmentObject private var appState: AppState
    let item: IngredientUsage?
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, quantity, costPrice, minQuantity
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header Section
                    headerSection
                    
                    // Form Section
                    VStack(spacing: 24) {
                        // Basic Info Section
                        basicInfoSection
                        
                        // Measurement Section
                        measurementSection
                        
                        // Financial Info Section
                        financialInfoSection
                    }
                    .padding(.horizontal)
                    
                    // Validation Errors
                    if !viewModel.getValidationErrors().isEmpty {
                        validationErrorsView
                    }
                    
                    // Action Button
                    actionButton
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Hủy") {
                        dismiss()
                    }
                    .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
                }
            }
            .onAppear {
                if let item = item {
                    viewModel.loadIngredientData(item)
                } else {
                    viewModel.resetForm()
                }
            }
            .onChange(of: viewModel.name) { _ in
                viewModel.clearValidationErrors()
            }
            .onChange(of: viewModel.quantity) { _ in
                viewModel.clearValidationErrors()
            }
            .onChange(of: viewModel.costPrice) { _ in
                viewModel.clearValidationErrors()
            }
            .onChange(of: viewModel.minQuantity) { _ in
                viewModel.clearValidationErrors()
            }
            .onChange(of: viewModel.measurementUnit) { _ in
                viewModel.clearValidationErrors()
            }
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            Image(systemName: item == nil ? "plus.circle.fill" : "pencil.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
            
            Text(item == nil ? "Thêm nguyên liệu mới" : "Cập nhật nguyên liệu")
                .font(.title2)
                .fontWeight(.bold)
            
            Text(item == nil ? "Điền thông tin để thêm nguyên liệu mới" : "Cập nhật thông tin nguyên liệu")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 20)
    }
    
    // MARK: - Basic Info Section
    private var basicInfoSection: some View {
        formSection(title: "Thông tin cơ bản", systemImage: "info.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Label("Tên nguyên liệu", systemImage: "tag.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                TextField("Nhập tên nguyên liệu", text: $viewModel.name)
                    .focused($focusedField, equals: .name)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.body)
            }
        }
    }
    
    // MARK: - Measurement Section
    private var measurementSection: some View {
        formSection(title: "Thông tin định lượng", systemImage: "ruler.fill") {
            VStack(alignment: .leading, spacing: 16) {
                // Quantity
                VStack(alignment: .leading, spacing: 8) {
                    Label("Số lượng", systemImage: "cube.box.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    HStack {
                        TextField("0", text: $viewModel.quantity)
                            .focused($focusedField, equals: .quantity)
                            .keyboardType(.decimalPad)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                        
                        Picker("Đơn vị", selection: $viewModel.measurementUnit) {
                            ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                        .pickerStyle(.menu)
                        .frame(width: 120)
                    }
                }
                
                // Min Quantity
                VStack(alignment: .leading, spacing: 8) {
                    Label("Số lượng tối thiểu", systemImage: "arrow.down.circle.fill")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("1", text: $viewModel.minQuantity)
                        .focused($focusedField, equals: .minQuantity)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
            }
        }
    }
    
    // MARK: - Financial Info Section
    private var financialInfoSection: some View {
        formSection(title: "Thông tin tài chính", systemImage: "dollarsign.circle.fill") {
            VStack(alignment: .leading, spacing: 12) {
                Label("Giá vốn", systemImage: "creditcard.fill")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                HStack {
                    TextField("0", text: $viewModel.costPrice)
                        .focused($focusedField, equals: .costPrice)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    
                    Text("VNĐ")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
                
                if let costPriceValue = Double(viewModel.costPrice), costPriceValue > 0 {
                    Text("≈ \(viewModel.formatCurrency(costPriceValue))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
        }
    }
    
    // MARK: - Validation Errors View
    private var validationErrorsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.getValidationErrors(), id: \.errorDescription) { error in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(error.errorDescription ?? "")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Action Button
    private var actionButton: some View {
        Button {
            Task {
                focusedField = nil
                await saveIngredient()
                if viewModel.getValidationErrors().isEmpty {
                    dismiss()
                }
            }
        } label: {
            HStack {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Image(systemName: item == nil ? "plus.circle.fill" : "checkmark.circle.fill")
                        .font(.title3)
                    Text(item == nil ? "Thêm nguyên liệu" : "Cập nhật")
                        .font(.headline)
                }
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: viewModel.isFormValid ? [appState.currentTabThemeColors.primaryColor, appState.currentTabThemeColors.secondaryColor] : [.gray.opacity(0.3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(15)
        }
        .disabled(!viewModel.isFormValid || viewModel.isLoading)
        .padding()
    }
    
    // MARK: - Helper Methods
    private func saveIngredient() async {
        guard let quantityValue = Double(viewModel.quantity),
              let costPriceValue = Double(viewModel.costPrice),
              let minQuantityValue = Double(viewModel.minQuantity) else { return }
        
        let measurement = Measurement(value: 1.0, unit: viewModel.measurementUnit)
        
        let newItem = IngredientUsage(
            shopId: item == nil ? (appState.sourceModel.activatedShop?.id ?? "") : item?.shopId ?? "",
            name: viewModel.name,
            quantity: quantityValue,
            measurementPerUnit: measurement,
            used: 0,
            minQuantity: minQuantityValue,
            costPrice: costPriceValue,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        do {
            if let existingItem = item {
                try await viewModel.updateIngredientUsage(existingItem)
            } else {
                try await viewModel.createIngredientUsage(newItem)
            }
        } catch {
            // Error is already handled in the view model
        }
    }
    
    private func formSection<Content: View>(title: String, systemImage: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundColor(.primary)
            
            content()
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
        }
    }
}

struct BatchUpdateView: View {
    let items: [IngredientUsage]
    @Environment(\.dismiss) private var dismiss
    @State private var updateType: UpdateType = .percentage
    @State private var value: Double = 0
    
    enum UpdateType {
        case percentage
        case absolute
        case minQuantity
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Kiểu cập nhật") {
                    Picker("Chọn kiểu", selection: $updateType) {
                        Text("Theo phần trăm").tag(UpdateType.percentage)
                        Text("Giá trị tuyệt đối").tag(UpdateType.absolute)
                        Text("Số lượng tối thiểu").tag(UpdateType.minQuantity)
                    }
                }
                
                Section("Giá trị") {
                    switch updateType {
                    case .percentage:
                        Stepper("Thay đổi \(Int(value))%", value: $value)
                    case .absolute:
                        Stepper("Số lượng: \(Int(value))", value: $value)
                    case .minQuantity:
                        Stepper("Số lượng tối thiểu: \(Int(value))", value: $value)
                    }
                }
            }
            .navigationTitle("Cập nhật \(items.count) sản phẩm")
            .navigationBarItems(
                leading: Button("Hủy") { dismiss() },
                trailing: Button("Cập nhật") {
                    // Implement batch update logic
                    dismiss()
                }
            )
        }
    }
}

struct ImportDataView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var selectedFile: URL?
    
    var body: some View {
        NavigationView {
            VStack {
                if let url = selectedFile {
                    Text("File được chọn: \(url.lastPathComponent)")
                } else {
                    Text("Chưa chọn file")
                }
                
                Button("Chọn file") {
                    // Implement file picker
                }
                
                Button("Nhập dữ liệu") {
                    // Implement import logic
                    dismiss()
                }
                .disabled(selectedFile == nil)
            }
            .navigationTitle("Nhập dữ liệu")
            .navigationBarItems(leading: Button("Hủy") { dismiss() })
        }
    }
}

struct InventoryHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            List {
                // Implement history items
            }
            .navigationTitle("Lịch sử thay đổi")
            .navigationBarItems(leading: Button("Đóng") { dismiss() })
        }
    }
}

//#Preview {
//    UpdateInventoryView(viewModel: InventoryViewModel(source: SourceModel()))
//}
