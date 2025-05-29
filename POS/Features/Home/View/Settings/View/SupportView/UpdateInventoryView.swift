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
    
    enum ActionType {
        case `import`
        case export
        case history
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Toolbar
            HStack {
                TextField("Tìm kiếm sản phẩm...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
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
            
            // Action Buttons when in multi-select mode
            if isMultiSelectMode && !selectedItems.isEmpty {
                HStack {
                    Text("\(selectedItems.count) items được chọn")
                    
                    Spacer()
                    
                    Button("Cập nhật hàng loạt") {
                        showingBatchUpdateSheet = true
                    }
                    
                    Button("Xóa", role: .destructive) {
                        // Show delete confirmation
                        //viewModel.showDeleteConfirmation(items: Array(selectedItems))
                    }
                }
                .padding(.horizontal)
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
            HStack {
                Picker("", selection: $selectedAction) {
                    Text("Thao tác").tag(Optional<ActionType>.none)
                    Text("Nhập từ Excel/CSV").tag(Optional<ActionType>.some(.import))
                    Text("Xuất dữ liệu").tag(Optional<ActionType>.some(.export))
                    Text("Lịch sử thay đổi").tag(Optional<ActionType>.some(.history))
                }
                .pickerStyle(MenuPickerStyle())
                .onChange(of: selectedAction) { newValue in
                    if let action = newValue {
                        handleAction(action)
                        selectedAction = nil
                    }
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
        .navigationTitle("Quản lý kho")
        .sheet(isPresented: $showingAddEditSheet) {
            InventoryItemFormView(
                item: selectedItem,
                onSave: { newItem in
                    if let existingItem = selectedItem {
                        //viewModel.updateItem(existingItem, with: newItem)
                    } else {
                        //viewModel.addItem(newItem)
                    }
                    showingAddEditSheet = false
                }
            )
        }
        .sheet(isPresented: $showingBatchUpdateSheet) {
            BatchUpdateView(items: Array(selectedItems))
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDataView()
        }
        .sheet(isPresented: $showingHistorySheet) {
            //HistoryView()
        }
    }
    
    private var filteredItems: [InventoryItem] {
        var items = [InventoryItem(name: "", quantity: 0, unit: "", minQuantity: 0, costPrice: 0)]
        
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
    
    private func handleAction(_ action: ActionType) {
        switch action {
        case .import:
            showingImportSheet = true
        case .export:
            //viewModel.exportData()
            Text("Export")
        case .history:
            showingHistorySheet = true
        }
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
                Text("\(item.quantity) \(item.unit)")
                    .font(.subheadline)
            }
            
            Spacer()
            
            // Stock Status Badge
            Text(item.stockStatus.description)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(item.stockStatus.color.opacity(0.2))
                .foregroundColor(item.stockStatus.color)
                .clipShape(Capsule())
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
        .onTapGesture {
            onTap(item)
        }
    }
}

struct InventoryItemFormView: View {
    let item: InventoryItem?
    let onSave: (InventoryItem) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var quantity = 0.0
    @State private var unit = ""
    @State private var minQuantity = 0.0
    @State private var costPrice = 0.0
    
    var body: some View {
        NavigationView {
            Form {
                Section("Thông tin sản phẩm") {
                    TextField("Tên sản phẩm", text: $name)
                    Stepper("Số lượng: \(quantity)", value: $quantity)
                    TextField("Đơn vị", text: $unit)
                    Stepper("Số lượng tối thiểu: \(minQuantity)", value: $minQuantity)
                }
            }
            .navigationTitle(item == nil ? "Thêm sản phẩm" : "Cập nhật sản phẩm")
            .navigationBarItems(
                leading: Button("Hủy") { dismiss() },
                trailing: Button("Lưu") {
                    let newItem = InventoryItem(
                        name: name,
                        quantity: quantity,
                        unit: unit,
                        minQuantity: minQuantity, costPrice: costPrice
                    )
                    onSave(newItem)
                    dismiss()
                }
            )
            .onAppear {
                if let item = item {
                    name = item.name
                    quantity = item.quantity
                    unit = item.unit
                    minQuantity = item.minQuantity
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

//struct SearchBar: View {
//    @Binding var text: String
//    let placeholder: String
//    
//    var body: some View {
//        HStack {
//            Image(systemName: "magnifyingglass")
//                .foregroundColor(.gray)
//            
//            TextField(placeholder, text: $text)
//                .textFieldStyle(RoundedBorderTextFieldStyle())
//        }
//    }
//}

//#Preview {
//    UpdateInventoryView(viewModel: InventoryViewModel(source: SourceModel()))
//}
