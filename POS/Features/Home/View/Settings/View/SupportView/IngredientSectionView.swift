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
    
    @State private var isMultiSelectMode = false
    @State private var selectedItems: Set<IngredientUsage> = []
    @State private var showingBatchUpdateSheet = false
    @State private var showingImportSheet = false
    @State private var showingHistorySheet = false
    @State private var selectedAction: ActionType?
    
    var body: some View {
        VStack(spacing: 16) {
            // Toolbar
            toolbarView
                .padding()
            
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
                .padding(.vertical)
            }
            
            // Bottom Toolbar
            bottomToolbarView
                .background(
                    Rectangle()
                        .fill(.ultraThinMaterial)
                        .edgesIgnoringSafeArea(.bottom)
                )
        }
        .navigationTitle("Quản lý kho")
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
        .onDisappear {
            Task {
                appState.sourceModel.removeIngredientsListener(shopId: appState.sourceModel.activatedShop?.id ?? "")
            }
        }
    }
    
    private var toolbarView: some View {
        VStack(spacing: 12) {
            // Search bar
            SearchBar(
                text: Binding(
                    get: { viewModel.searchKey },
                    set: { viewModel.updateSearchKey($0) }
                ),
                placeholder: "Tìm kiếm sản phẩm..."
            )
            .padding(.horizontal)
            
            // Filters
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
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
                        Label(
                            viewModel.selectedStockStatus?.description ?? "Tất cả",
                            systemImage: "line.3.horizontal.decrease.circle"
                        )
                    }
                    .buttonStyle(.bordered)
                    
                    // Sort order
                    Menu {
                        Picker("Sắp xếp", selection: $viewModel.sortOrder) {
                            Text("Tên A-Z").tag(IngredientViewModel.SortOrder.name)
                            Text("Số lượng").tag(IngredientViewModel.SortOrder.quantity)
                            Text("Cập nhật").tag(IngredientViewModel.SortOrder.lastUpdated)
                        }
                    } label: {
                        Label(
                            "Sắp xếp",
                            systemImage: "arrow.up.arrow.down"
                        )
                    }
                    .buttonStyle(.bordered)
                    
                    // Low stock filter
                    Button(action: { viewModel.showLowStockOnly.toggle() }) {
                        Label(
                            "Sắp hết hàng",
                            systemImage: "exclamationmark.triangle"
                        )
                    }
                    .buttonStyle(.bordered)
                    .tint(viewModel.showLowStockOnly ? .orange : nil)
                    
                    // Multi-select mode
                    Button(action: { isMultiSelectMode.toggle() }) {
                        Label(
                            "Chọn nhiều",
                            systemImage: isMultiSelectMode ? "checkmark.circle.fill" : "checkmark.circle"
                        )
                    }
                    .buttonStyle(.bordered)
                    .tint(isMultiSelectMode ? .accentColor : nil)
                }
                .padding(.horizontal)
            }
        }
    }
    
    private var multiSelectActionView: some View {
        HStack(spacing: 16) {
            Text("\(selectedItems.count) items được chọn")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Button(action: { showingBatchUpdateSheet = true }) {
                Label("Cập nhật", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.bordered)
            
            Button(role: .destructive, action: {
                // Show delete confirmation
            }) {
                Label("Xóa", systemImage: "trash")
            }
            .buttonStyle(.bordered)
        }
        .padding()
        .background(Color(UIColor.secondarySystemBackground))
    }
    
    private var bottomToolbarView: some View {
        HStack(spacing: 16) {
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
                viewModel.selectedItem = nil
                appState.coordinator.navigateTo(.ingredientForm(viewModel.selectedItem), using: .present, with: .present)
            }) {
                Label("Thêm sản phẩm", systemImage: "plus")
                    .font(.body.bold())
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 2)
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
                leading: Button("Hủy") { appState.coordinator.dismiss(style: .present) },
                trailing: Button("Lưu") {
                    let measurement = Measurement(
                        value: measurementValue,
                        unit: selectedMeasurementUnit
                    )
                    
                    let newItem = IngredientUsage(name: name, quantity: quantity, measurementPerUnit: measurement, used: 0, costPrice: costPrice, createdAt: Date(), updatedAt: Date())
                    Task {
                        do {
                            await viewModel.createIngredientUsage(newItem)
                            appState.coordinator.dismiss(style: .present)
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
