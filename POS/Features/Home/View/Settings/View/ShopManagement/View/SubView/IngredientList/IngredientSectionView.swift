//
//  UpdateIngredientView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct IngredientSectionView: View {
    @ObservedObject var viewModel: IngredientViewModel 
    @EnvironmentObject var appState: AppState
    
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var isMultiSelectMode = false
    @State private var selectedItems: Set<IngredientUsage> = []
    @State private var showingBatchUpdateSheet = false
    @State private var showingImportSheet = false
    @State private var showingHistorySheet = false
    @State private var selectedAction: ActionType?
    @State private var showingSearchBar = false
    @State private var animateHeader = false
    
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
    
    var shop: Shop?
    
    var body: some View {
        Group {
            if let shops = appState.sourceModel.shops, shops.isEmpty {
                VStack(spacing: 20) {
                    Image(systemName: "building.2.crop.circle")
                        .font(.system(size: 60))
                        .foregroundStyle(
                            appState.currentTabThemeColors.gradient(for: colorScheme)
                        )
                    
                    Text("Chưa có cửa hàng nào")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("Bạn cần tạo cửa hàng trước khi quản lý kho")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    VStack {
                        Label("Tạo cửa hàng mới", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                            .cornerRadius(15)
                            .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
                                appState.coordinator.navigateTo(.addShop(nil), using: .present, with: .present)
                            }
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
                    
                    // Quick Stats
                    quickStatsSection
                        .opacity(animateHeader ? 1 : 0)
                        .offset(y: animateHeader ? 0 : -20)
                    
                    if viewModel.filteredAndSortedItems.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "cube.box.fill")
                                .font(.system(size: 60))
                                .foregroundStyle(
                                    appState.currentTabThemeColors.gradient(for: colorScheme)
                                )
                            
                            Text("Chưa có sản phẩm nào trong kho")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Hãy thêm sản phẩm đầu tiên vào kho của bạn")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 40)
                            
                            VStack {
                                Label("Thêm sản phẩm mới", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .foregroundColor(.white)
                                    .cornerRadius(15)
                                    .layeredButton(tabThemeColors: appState.currentTabThemeColors) {
                                        viewModel.selectedItem = nil
                                        appState.coordinator.navigateTo(.ingredientForm(viewModel.selectedItem), using: .present, with: .present)
                                    }
                            }
                            .padding(.horizontal, 40)
                            .padding(.top, 10)
                            
                            // Suggestion for importing data
                            Button {
                                showingImportSheet = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.and.arrow.down.fill")
                                    Text("Hoặc nhập từ Excel/CSV")
                                }
                                .font(.subheadline)
                                .foregroundColor(.blue)
                            }
                            .padding(.top, 5)
                        }
                        .padding()
                        .frame(maxHeight: .infinity)
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
                            .padding()
                        }
                        
                        // Filters
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
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
                                    HStack {
                                        Image(systemName: "line.3.horizontal.decrease.circle.fill")
                                        Text(viewModel.selectedStockStatus?.description ?? "Tất cả")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemBackground))
                                            //.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
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
                                    HStack {
                                        Image(systemName: "arrow.up.arrow.down.circle.fill")
                                        Text("Sắp xếp")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemBackground))
                                            //.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                    .foregroundColor(.primary)
                                }
                                
                                // Low stock filter
                                Button(action: { viewModel.showLowStockOnly.toggle() }) {
                                    HStack {
                                        Image(systemName: viewModel.showLowStockOnly ? "exclamationmark.triangle.fill" : "exclamationmark.triangle")
                                        Text("Sắp hết hàng")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemBackground))
                                            //.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                    .foregroundColor(viewModel.showLowStockOnly ? .orange : .primary)
                                }
                                
                                // Multi-select mode
                                Button(action: { isMultiSelectMode.toggle() }) {
                                    HStack {
                                        Image(systemName: isMultiSelectMode ? "checkmark.circle.fill" : "checkmark.circle")
                                        Text("Chọn nhiều")
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule()
                                            .fill(Color(.systemBackground))
                                            //.shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                    )
                                    .foregroundColor(isMultiSelectMode ? .blue : .primary)
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.vertical, 8)
                        
                        // Action Buttons when in multi-select mode
                        if isMultiSelectMode && !selectedItems.isEmpty {
                            multiSelectActionView
                        }
                        
                        // Inventory List
                        ScrollView {
                            LazyVStack(spacing: 12) {
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
                                    .padding(.horizontal)
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
                                    .font(.title2)
                                    .foregroundStyle(.primary)
                            }
                            
                            Button {
                                viewModel.selectedItem = nil
                                appState.coordinator.navigateTo(.ingredientForm(viewModel.selectedItem), using: .present, with: .present)
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
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
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: "cube.box.fill")
                            .font(.title2)
                            .foregroundStyle(
                                appState.currentTabThemeColors.gradient(for: colorScheme)
                            )
                        
                        Text("\(viewModel.filteredAndSortedItems.count) sản phẩm")
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
    
    private var quickStatsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
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
            .padding(.horizontal)
        }
    }
    
    private func statsCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Text(value)
                .font(.headline)
                .foregroundColor(.primary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
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
        HStack(spacing: 16) {
            Button(action: {
                showingBatchUpdateSheet = true
            }) {
                Label("Cập nhật hàng loạt", systemImage: "arrow.triangle.2.circlepath")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.red.gradient)
                    .cornerRadius(20)
            }
        }
        .padding()
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .edgesIgnoringSafeArea(.bottom)
        )
    }
    
    private var bottomToolbarView: some View {
        HStack(spacing: 16) {
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
                .foregroundStyle(
                    appState.currentTabThemeColors.gradient(for: colorScheme)
                )
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
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
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        appState.currentTabThemeColors.gradient(for: colorScheme)
                    )
                    .cornerRadius(20)
            }
        }
        .padding()
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
            if let existingItem = viewModel.selectedItem {
                await viewModel.updateIngredientUsage(existingItem)
            } else {
                await viewModel.createIngredientUsage(item)
            }
        }
        viewModel.showEditItemSheet = false
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
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                // Checkbox cho multi-select mode
            if isMultiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray)
                        .font(.system(size: 20))
            }
            
                // Thông tin chính
                VStack(alignment: .leading, spacing: 6) {
                    // Tên và trạng thái
                    HStack {
                Text(item.name)
                    .font(.headline)
                        
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
                                Text("\(String(format: "%.1f", item.quantity)) \(item.measurementPerUnit.unit.shortDisplayName)")
                                    .font(.subheadline)
                            }
                            
                            // Tổng định lượng
                            HStack(spacing: 4) {
                                Image(systemName: "sum")
                                    .foregroundColor(.gray)
                                Text("\(String(format: "%.1f", availableAmount))/\(String(format: "%.1f", item.totalMeasurement)) \(item.measurementPerUnit.unit.shortDisplayName)")
                        .font(.subheadline)
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
                                .font(.caption)
                                .bold()
                        }
                        .frame(width: 40, height: 40)
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
                    HStack(spacing: 16) {
                        // Giá nhập
                        HStack(spacing: 4) {
                            Image(systemName: "dollarsign.circle")
                                .foregroundColor(.gray)
                            Text("\(Int(item.costPrice))₫")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Số lượng tối thiểu
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle")
                                .foregroundColor(.gray)
                            Text("Min: \(Int(item.minQuantity)) \(item.measurementPerUnit.unit.shortDisplayName)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        // Thời gian cập nhật
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .foregroundColor(.gray)
                            Text(item.updatedAt.formatted(.relative(presentation: .named)))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        //.shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(item)
        }
    }
    
    private var stockStatusBadge: some View {
        HStack(spacing: 4) {
            Image(systemName: item.stockStatus.systemImage)
        Text(item.stockStatus.description)
        }
            .font(.caption)
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
    @State private var name = ""
    @State private var quantity = 0.0
    @State private var selectedUnit: MeasurementUnit = .gram
    @State private var measurementValue = 1.0
    @State private var selectedMeasurementUnit: MeasurementUnit = .gram
    @State private var minQuantity = 0.0
    @State private var costPrice = 0.0
    
    var body: some View {
        NavigationView {
            Form {
                Section("Thông tin sản phẩm") {
                    TextField("Tên sản phẩm", text: $name)
                        .keyboardType(.default)
                    
                    HStack {
                        Text("Số lượng:")
                        TextField("0", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
                
                Section("Định lượng cho 1 đơn vị") {
                    HStack {
                        Text("Giá trị:")
                        TextField("1", value: $measurementValue, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Đơn vị đo", selection: $selectedMeasurementUnit) {
                        ForEach(MeasurementUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                }
                
                Section("Thông tin bổ sung") {
                    HStack {
                        Text("Giá nhập:")
                        TextField("0", value: $costPrice, format: .number)
                            .keyboardType(.decimalPad)
                        Text("₫")
                    }
                    
                    HStack {
                        Text("Số lượng tối thiểu:")
                        TextField("1", value: $minQuantity, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle(item == nil ? "Thêm sản phẩm" : "Cập nhật sản phẩm")
            .navigationBarItems(
                leading: Button("Hủy") {
//                    appState.coordinator.dismiss(style: .present)
                },
                trailing: Button("Lưu") {
                    let measurement = Measurement(
                        value: measurementValue,
                        unit: selectedMeasurementUnit
                    )
                    
                    let newItem = IngredientUsage(name: name, quantity: quantity, measurementPerUnit: measurement, used: 0, minQuantity: minQuantity, costPrice: costPrice, createdAt: Date(), updatedAt: Date())
                    Task {
                        do {
                            await viewModel.createIngredientUsage(newItem)
                            //appState.coordinator.dismiss(style: .present)
                        }
                    }
                }
            )
            .onAppear {
                if let item = item {
                    name = item.name
                    quantity = item.quantity
                    selectedUnit = item.measurementPerUnit.unit
                    measurementValue = item.measurementPerUnit.value
                    selectedMeasurementUnit = item.measurementPerUnit.unit
                    minQuantity = item.minQuantity
                    costPrice = item.costPrice
                }
            }
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
