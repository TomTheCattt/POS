//
//  UpdateMenuView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct UpdateMenuView: View {
    @ObservedObject var viewModel: MenuViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var searchText = ""
    @State private var selectedCategory: String?
    @State private var showingAddEditSheet = false
    @State private var selectedItem: MenuItem?
    @State private var showingHistorySheet = false
    @State private var showingImportSheet = false
    @State private var selectedAction: ActionType?
    
    var body: some View {
        VStack(spacing: 16) {
            // Search & Filter
            HStack {
                TextField("Tìm kiếm món...", text: $searchText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Picker("", selection: $selectedCategory) {
                    Text("Tất cả").tag(Optional<String>.none)
                    ForEach(viewModel.categories, id: \.self) { category in
                        Text(category).tag(Optional<String>.some(category))
                    }
                }
                .pickerStyle(MenuPickerStyle())
            }
            .padding()
            
            // Menu Grid
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.adaptive(minimum: 160), spacing: 16)
                ], spacing: 16) {
                    ForEach(filteredItems) { item in
                        MenuItemCard(item: item) {
                            selectedItem = item
                            showingAddEditSheet = true
                        }
                    }
                }
                .padding()
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
                    Label("Thêm món mới", systemImage: "plus.circle.fill")
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
        .navigationTitle("Quản lý thực đơn")
        .sheet(isPresented: $showingAddEditSheet) {
            MenuItemFormView(
                item: selectedItem,
                inventoryItems: [],
                onSave: { newItem in
                    if let existingItem = selectedItem {
                        //viewModel.updateItem(existingItem, with: newItem)
                    } else {
                        //viewModel.addItem(newItem)
                    }
                    showingAddEditSheet = false
                },
                onAddNewIngredient: {
                    // Show add new ingredient form
                    //viewModel.showAddIngredientForm()
                }
            )
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDataView()
        }
        .sheet(isPresented: $showingHistorySheet) {
            InventoryHistoryView()
        }
    }
    
    private var filteredItems: [MenuItem] {
        var items = [MenuItem(name: "", price: 0, category: "", createdAt: Date(), updatedAt: Date())]
        
        if !searchText.isEmpty {
            items = items.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
        
        if let category = selectedCategory {
            items = items.filter { $0.category == category }
        }
        
        return items
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
struct MenuItemCard: View {
    let item: MenuItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack {
                // Image
                if let imageURL = item.imageURL {
                    AsyncImage(url: imageURL) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Color.gray.opacity(0.2)
                    }
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    Text(String(format: "%.0f₫", item.price))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    // Availability Badge
                    if let isAvailable = item.isAvailable {
                        Text(isAvailable ? "Còn món" : "Hết món")
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(isAvailable ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
                            .foregroundColor(isAvailable ? .green : .red)
                            .clipShape(Capsule())
                    }
                }
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
}

struct MenuItemFormView: View {
    let item: MenuItem?
    let inventoryItems: [InventoryItem]
    let onSave: (MenuItem) -> Void
    let onAddNewIngredient: () -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var price = 0.0
    @State private var category = ""
    @State private var isAvailable = true
    @State private var ingredients: [IngredientUsage] = []
    @State private var showingImagePicker = false
    @State private var selectedImage: UIImage?
    @State private var showingAddIngredientSheet = false
    
    var body: some View {
        NavigationView {
            Form {
                Section("Thông tin món") {
                    TextField("Tên món", text: $name)
                    TextField("Giá", value: $price, format: .currency(code: "VND"))
                    TextField("Danh mục", text: $category)
                    Toggle("Còn món", isOn: $isAvailable)
                }
                
                Section("Hình ảnh") {
                    if let image = selectedImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(height: 200)
                    }
                    
                    Button("Chọn ảnh") {
                        showingImagePicker = true
                    }
                }
                
                Section("Nguyên liệu") {
                    ForEach(ingredients, id: \.inventoryItemID) { ingredient in
                        HStack {
                            if let item = inventoryItems.first(where: { $0.id == ingredient.inventoryItemID }) {
                                Text(item.name)
                            }
                            Spacer()
                            Text("\(ingredient.quantity, specifier: "%.1f") \(ingredient.unit)")
                        }
                    }
                    .onDelete { indexSet in
                        ingredients.remove(atOffsets: indexSet)
                    }
                    
                    Button("Thêm nguyên liệu") {
                        showingAddIngredientSheet = true
                    }
                }
            }
            .navigationTitle(item == nil ? "Thêm món mới" : "Cập nhật món")
            .navigationBarItems(
                leading: Button("Hủy") { dismiss() },
                trailing: Button("Lưu") {
                    // Create new menu item
                    // Upload image if selected
                    // Save ingredients
                    dismiss()
                }
            )
            .sheet(isPresented: $showingImagePicker) {
                // Image picker view
            }
            .sheet(isPresented: $showingAddIngredientSheet) {
                AddIngredientView(
                    inventoryItems: inventoryItems,
                    onAddNewIngredient: onAddNewIngredient,
                    onSelect: { ingredient in
                        ingredients.append(ingredient)
                        showingAddIngredientSheet = false
                    }
                )
            }
        }
    }
}

struct AddIngredientView: View {
    let inventoryItems: [InventoryItem]
    let onAddNewIngredient: () -> Void
    let onSelect: (IngredientUsage) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var selectedItem: InventoryItem?
    @State private var quantity: Double = 0
    @State private var unit = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Search bar for inventory items
                SearchBar(text: $searchText, placeholder: "Tìm kiếm nguyên liệu...")
                    .padding()
                
                if filteredItems.isEmpty {
                    VStack {
                        Text("Không tìm thấy nguyên liệu")
                            .foregroundColor(.secondary)
                        
                        Button("Thêm nguyên liệu mới") {
                            onAddNewIngredient()
                        }
                        .padding()
                    }
                } else {
                    List(filteredItems) { item in
                        Button {
                            selectedItem = item
                        } label: {
                            HStack {
                                Text(item.name)
                                Spacer()
                                if selectedItem == item {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                }
                
                if let item = selectedItem {
                    VStack {
                        HStack {
                            Text("Số lượng:")
                            TextField("0", value: $quantity, format: .number)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            Text(item.unit)
                        }
                        .padding()
                        
                        Button("Thêm") {
                            onSelect(IngredientUsage(
                                inventoryItemID: item.id ?? "",
                                quantity: quantity,
                                unit: item.unit
                            ))
                        }
                        .disabled(quantity <= 0)
                        .buttonStyle(.borderedProminent)
                        .padding()
                    }
                }
            }
            .navigationTitle("Thêm nguyên liệu")
            .navigationBarItems(leading: Button("Hủy") { dismiss() })
        }
    }
    
    private var filteredItems: [InventoryItem] {
        if searchText.isEmpty {
            return inventoryItems
        }
        return inventoryItems.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
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

//#Preview {
//    UpdateMenuView(viewModel: MenuViewModel(source: SourceModel()))
//        .environmentObject(AppState())
//}

enum ActionType {
    case `import`
    case export
    case history
}
