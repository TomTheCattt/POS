import SwiftUI
import PhotosUI

struct AddMenuItemView: View {
    @ObservedObject var viewModel: MenuViewModel
    @EnvironmentObject private var appState: AppState
    let editingItem: MenuItem? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var price = 0.0
    @State private var category = ""
    @State private var isAvailable = true
    @State private var selectedImage: PhotosPickerItem?
    @State private var imageData: Data?
    @State private var ingredients: [IngredientUsage] = []
    @State private var showingIngredientSheet = false
    @State private var showingImportSheet = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin cơ bản")) {
                    TextField("Tên món", text: $name)
                    
                    HStack {
                        Text("Giá:")
                        TextField("0", value: $price, format: .number)
                            .keyboardType(.decimalPad)
                        Text("₫")
                    }
                    
                    TextField("Danh mục", text: $category)
                    
                    Toggle("Còn món", isOn: $isAvailable)
                }
                
                Section(header: Text("Hình ảnh")) {
                    PhotosPicker(selection: $selectedImage, matching: .images) {
                        if let imageData = imageData, let uiImage = UIImage(data: imageData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .scaledToFit()
                                .frame(height: 200)
                        } else {
                            HStack {
                                Image(systemName: "photo")
                                Text("Chọn ảnh")
                            }
                        }
                    }
                }
                
                Section(header: Text("Nguyên liệu")) {
                    ForEach(ingredients, id: \.inventoryItemID) { ingredient in
                        HStack {
//                            if let item = try await viewModel.getInventoryItem(by: ingredient.inventoryItemID) {
//                                Text(item.name)
//                            }
                            Spacer()
                            Text("\(ingredient.quantity) \(ingredient.unit)")
                        }
                    }
                    .onDelete { indexSet in
                        ingredients.remove(atOffsets: indexSet)
                    }
                    
                    Button {
                        showingIngredientSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Thêm nguyên liệu")
                        }
                    }
                }
                
                if editingItem == nil {
                    Section {
                        Button {
                            showingImportSheet = true
                        } label: {
                            HStack {
                                Image(systemName: "square.and.arrow.down")
                                Text("Nhập từ file")
                            }
                        }
                    }
                }
            }
            .navigationTitle(editingItem == nil ? "Thêm món mới" : "Chỉnh sửa món")
            .navigationBarItems(
                leading: Button("Hủy") {
                    dismiss()
                },
                trailing: Button(editingItem == nil ? "Thêm" : "Lưu") {
                    Task {
                        await saveMenuItem()
                    }
                }
                .disabled(name.isEmpty || price <= 0 || category.isEmpty)
            )
            .onChange(of: selectedImage) { _ in
                Task {
                    if let data = try? await selectedImage?.loadTransferable(type: Data.self) {
                        imageData = data
                    }
                }
            }
            .sheet(isPresented: $showingIngredientSheet) {
                AddIngredientUsageView(ingredients: $ingredients)
            }
            .sheet(isPresented: $showingImportSheet) {
                ImportMenuItemsView(viewModel: viewModel)
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    private func saveMenuItem() async {
        isLoading = true
        defer { isLoading = false }
        
        let menuItem = MenuItem(
            id: editingItem?.id,
            name: name,
            price: price,
            category: category,
            ingredients: ingredients,
            isAvailable: isAvailable,
            imageURL: nil, // Sẽ được cập nhật sau khi upload ảnh
            createdAt: editingItem?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        do {
            if let _ = editingItem {
                await viewModel.updateMenuItem(menuItem, imageData: imageData)
            } else {
                await viewModel.createMenuItem(menuItem, imageData: imageData)
            }
            dismiss()
        }
    }
}

struct AddIngredientUsageView: View {
    @Binding var ingredients: [IngredientUsage]
    @Environment(\.dismiss) private var dismiss
    @State private var selectedItem: InventoryItem?
    @State private var quantity = 0.0
    @State private var unit = ""
    
    var body: some View {
        NavigationView {
            Form {
                Picker("Nguyên liệu", selection: $selectedItem) {
                    Text("Chọn nguyên liệu").tag(Optional<InventoryItem>.none)
//                    ForEach(viewModel.inventoryItems) { item in
//                        Text(item.name).tag(Optional<InventoryItem>.some(item))
//                    }
                }
                
                HStack {
                    Text("Số lượng:")
                    TextField("0", value: $quantity, format: .number)
                        .keyboardType(.decimalPad)
                }
                
                TextField("Đơn vị", text: $unit)
            }
            .navigationTitle("Thêm nguyên liệu")
            .navigationBarItems(
                leading: Button("Hủy") {
                    dismiss()
                },
                trailing: Button("Thêm") {
                    if let item = selectedItem {
                        ingredients.append(IngredientUsage(
                            inventoryItemID: item.id ?? "",
                            quantity: quantity,
                            unit: unit
                        ))
                        dismiss()
                    }
                }
                .disabled(selectedItem == nil || quantity <= 0 || unit.isEmpty)
            )
        }
    }
}

struct ImportMenuItemsView: View {
    @ObservedObject var viewModel: MenuViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Nhập danh sách món từ file Excel hoặc CSV")
                    .font(.headline)
                    .multilineTextAlignment(.center)
                
                Button {
                    showingFilePicker = true
                } label: {
                    HStack {
                        Image(systemName: "doc")
                        Text("Chọn file")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                }
                
                Text("Lưu ý: File cần có các cột: Tên món, Giá, Danh mục")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
            }
            .padding()
            .navigationTitle("Nhập từ file")
            .navigationBarItems(leading: Button("Đóng") {
                dismiss()
            })
            .fileImporter(
                isPresented: $showingFilePicker,
                allowedContentTypes: [.commaSeparatedText, .spreadsheet]
            ) { result in
                switch result {
                case .success(let file):
                    Task {
                        await importFile(at: file)
                    }
                case .failure:
                    // Xử lý lỗi
                    break
                }
            }
            .overlay {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
    }
    
    private func importFile(at url: URL) async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            await viewModel.importMenuItems(from: url)
            dismiss()
        }
    }
} 
