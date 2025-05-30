//
//  UpdateInventoryView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct UpdateInventoryView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var searchText = ""
    @State private var selectedFilter: InventoryItem.StockStatus?
    @State private var showingAddEditSheet = false
    @State private var selectedItem: InventoryItem?
    @State private var isMultiSelectMode = false
    @State private var selectedItems: Set<InventoryItem> = []
    @State private var showingBatchUpdateSheet = false
    @State private var showingImportSheet = false
    @State private var showingHistorySheet = false
    @State private var selectedAction: ActionType?
    
    var body: some View {
        VStack(spacing: 16) {
            // Toolbar
            toolbarView
            
            // Action Buttons when in multi-select mode
            if isMultiSelectMode && !selectedItems.isEmpty {
                multiSelectActionView
            }
            
            // Inventory List
            List {
                ForEach(filteredItems) { item in
                    InventoryItemRow(
                        item: item,
                        isSelected: selectedItems.contains(item),
                        isMultiSelectMode: isMultiSelectMode
                    ) { item in
                        if isMultiSelectMode {
                            toggleItemSelection(item)
                        } else {
                            selectedItem = item
                            showingAddEditSheet = true
                        }
                    }
                }
            }
            
            // Bottom Toolbar
            bottomToolbarView
        }
        .navigationTitle("Quản lý kho")
        .sheet(isPresented: $showingAddEditSheet) {
            InventoryItemFormView(
                item: selectedItem,
                onSave: handleSaveItem
            )
        }
        .sheet(isPresented: $showingBatchUpdateSheet) {
            BatchUpdateView(items: Array(selectedItems))
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDataView()
        }
        .sheet(isPresented: $showingHistorySheet) {
            InventoryHistoryView()
        }
    }
    
    private var toolbarView: some View {
        HStack {
            SearchBar(text: $searchText, placeholder: "Tìm kiếm sản phẩm...")
            
            Picker("", selection: $selectedFilter) {
                Text("Tất cả").tag(Optional<InventoryItem.StockStatus>.none)
                Text("Còn hàng").tag(Optional<InventoryItem.StockStatus>.some(.inStock))
                Text("Sắp hết").tag(Optional<InventoryItem.StockStatus>.some(.lowStock))
                Text("Hết hàng").tag(Optional<InventoryItem.StockStatus>.some(.outOfStock))
            }
            .pickerStyle(MenuPickerStyle())
            
            Button(action: { isMultiSelectMode.toggle() }) {
                Image(systemName: isMultiSelectMode ? "checkmark.circle.fill" : "checkmark.circle")
            }
        }
        .padding()
    }
    
    private var multiSelectActionView: some View {
        HStack {
            Text("\(selectedItems.count) items được chọn")
            
            Spacer()
            
            Button("Cập nhật hàng loạt") {
                showingBatchUpdateSheet = true
            }
            
            Button("Xóa", role: .destructive) {
                // Show delete confirmation
            }
        }
        .padding(.horizontal)
    }
    
    private var bottomToolbarView: some View {
        HStack {
            Menu {
                Button("Nhập từ Excel/CSV") { selectedAction = .import }
                Button("Xuất dữ liệu") { selectedAction = .export }
                Button("Lịch sử thay đổi") { selectedAction = .history }
            } label: {
                Text("Thao tác")
                Image(systemName: "chevron.down")
            }
            
            Spacer()
            
            Button(action: {
                selectedItem = nil
                showingAddEditSheet = true
            }) {
                Label("Thêm sản phẩm", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
    }
    
    private var filteredItems: [InventoryItem] {
        var items = [InventoryItem(name: "", quantity: 0, unit: MeasurementUnit.gram, measurement: Measurement(value: 0, unit: .gram), minQuantity: 0, costPrice: 0)]
        
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if let filter = selectedFilter {
            items = items.filter { $0.stockStatus == filter }
        }
        
        return items
    }
    
    private func toggleItemSelection(_ item: InventoryItem) {
        if selectedItems.contains(item) {
            selectedItems.remove(item)
        } else {
            selectedItems.insert(item)
        }
    }
    
    private func handleSaveItem(_ item: InventoryItem) {
        Task {
            if let existingItem = selectedItem {
                await viewModel.updateInventoryItem(existingItem)
            } else {
                await viewModel.createInventoryItem(item)
            }
        }
        showingAddEditSheet = false
    }
}

// MARK: - Supporting Views
struct InventoryItemRow: View {
    let item: InventoryItem
    let isSelected: Bool
    let isMultiSelectMode: Bool
    let onTap: (InventoryItem) -> Void
    
    var body: some View {
        HStack {
            if isMultiSelectMode {
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isSelected ? .accentColor : .gray)
            }
            
            VStack(alignment: .leading) {
                Text(item.name)
                    .font(.headline)
                HStack {
                    Text("\(String(format: "%.1f", item.quantity)) \(item.unit.displayName)")
                        .font(.subheadline)
                    Text("(\(String(format: "%.1f", item.totalMeasurement)) \(item.measurement.unit.displayName))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            stockStatusBadge
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(item)
        }
    }
    
    private var stockStatusBadge: some View {
        Text(item.stockStatus.description)
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
                .textFieldStyle(RoundedBorderTextFieldStyle())
        }
    }
}

enum ActionType {
    case `import`
    case export
    case history
}

struct InventoryItemFormView: View {
    let item: InventoryItem?
    let onSave: (InventoryItem) -> Void
    
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
                    
                    HStack {
                        Text("Số lượng:")
                        TextField("0", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    Picker("Đơn vị", selection: $selectedUnit) {
                        ForEach(MeasurementUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
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
                        TextField("0", value: $minQuantity, format: .number)
                            .keyboardType(.decimalPad)
                    }
                }
            }
            .navigationTitle(item == nil ? "Thêm sản phẩm" : "Cập nhật sản phẩm")
            .navigationBarItems(
                leading: Button("Hủy") { dismiss() },
                trailing: Button("Lưu") {
                    let measurement = Measurement(
                        value: measurementValue,
                        unit: selectedMeasurementUnit
                    )
                    
                    let newItem = InventoryItem(
                        name: name,
                        quantity: quantity,
                        unit: selectedUnit,
                        measurement: measurement,
                        minQuantity: minQuantity,
                        costPrice: costPrice
                    )
                    onSave(newItem)
                    dismiss()
                }
            )
            .onAppear {
                if let item = item {
                    name = item.name
                    quantity = item.quantity
                    selectedUnit = item.unit
                    measurementValue = item.measurement.value
                    selectedMeasurementUnit = item.measurement.unit
                    minQuantity = item.minQuantity
                    costPrice = item.costPrice
                }
            }
        }
    }
}

struct BatchUpdateView: View {
    let items: [InventoryItem]
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
