import Combine
import SwiftUI

struct MenuItemFormView: View {
    @ObservedObject var viewModel: MenuViewModel
    @EnvironmentObject private var appState: AppState
    
    let menu: AppMenu
    let menuItem: MenuItem?
    
    @State private var name = ""
    @State private var price = ""
    @State private var category = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingRecipeSheet = false
    @State private var recipe: [Recipe] = []
    @State private var isUploading = false
    @FocusState private var focusedField: Field?
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !price.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(price) != nil
    }
    
    enum Field {
        case name, price, category
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header với icon
                    headerSection
                    
                    // Image Picker Section
                    imagePickerSection
                    
                    // Form Fields
                    formSection
                    
                    // Recipe Section
                    recipeSection
                    
                    // Submit Button
                    submitButton
                    
                    Spacer(minLength: 20)
                }
                .padding(.horizontal, 20)
            }
            .navigationTitle(menuItem == nil ? "Thêm Món Mới" : "Chỉnh Sửa Món")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Huỷ") {
                        appState.coordinator.dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(image: $selectedImage)
            }
            .sheet(isPresented: $showingRecipeSheet) {
                RecipeFormView(recipe: $recipe)
            }
        }
        .onAppear {
            setupInitialData()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: menuItem == nil ? "plus.circle.fill" : "pencil.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            Text(menuItem == nil ? "Thêm món mới" : "Chỉnh sửa món")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Điền thông tin chi tiết về món ăn")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 10)
    }
    
    private var imagePickerSection: some View {
        Button(action: {
            showingImagePicker = true
        }) {
            ZStack {
                if let image = selectedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(.systemGray6))
                        .frame(height: 200)
                        .overlay(
                            VStack(spacing: 12) {
                                Image(systemName: "photo.on.rectangle.angled")
                                    .font(.system(size: 30))
                                    .foregroundColor(.secondary)
                                Text("Thêm hình ảnh món ăn")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                        )
                }
            }
        }
    }
    
    private var formSection: some View {
        VStack(spacing: 20) {
            // Tên món
            FormField(
                icon: "text.cursor",
                title: "Tên món",
                placeholder: "Nhập tên món...",
                text: $name,
                field: .name,
                focusedField: $focusedField
            )
            
            // Giá
            FormField(
                icon: "banknote",
                title: "Giá bán",
                placeholder: "Nhập giá bán...",
                text: $price,
                field: .price,
                focusedField: $focusedField,
                keyboardType: .numberPad
            )
            
            // Danh mục
            VStack(alignment: .leading, spacing: 12) {
                Label("Danh mục", systemImage: "tag")
                    .font(.headline)
                
                CategorySuggestionView(selectedCategory: $category)
                
                TextField("Hoặc nhập danh mục khác...", text: $category)
                    .focused($focusedField, equals: .category)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocorrectionDisabled()
            }
        }
    }
    
    private var recipeSection: some View {
        Button(action: {
            showingRecipeSheet = true
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Công thức")
                        .font(.headline)
                    Text(recipe.isEmpty ? "Thêm nguyên liệu" : "\(recipe.count) nguyên liệu")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var submitButton: some View {
        Button(action: {
            Task {
                await handleSubmit()
            }
        }) {
            HStack {
                if isUploading {
                    ProgressView()
                        .tint(.white)
                } else {
                    Text(menuItem == nil ? "Thêm món" : "Lưu thay đổi")
                        .fontWeight(.semibold)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                isFormValid ?
                LinearGradient(
                    colors: [.blue, .purple],
                    startPoint: .leading,
                    endPoint: .trailing
                ) :
                LinearGradient(
                    colors: [Color(.systemGray4), Color(.systemGray3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
            //.shadow(color: isFormValid ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
        }
        .disabled(!isFormValid || isUploading)
    }
    
    private func setupInitialData() {
        if let item = menuItem {
            name = item.name
            price = String(format: "%.0f", item.price)
            category = item.category
            recipe = item.recipe
            
            if let url = item.imageURL {
                // Load image from URL
                Task {
                    if let (data, _) = try? await URLSession.shared.data(from: url),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }
    
    private func handleSubmit() async {
        guard isFormValid else { return }
        
        isUploading = true
        defer { isUploading = false }
        
        do {
            let priceValue = Double(price) ?? 0
            
            if let menuItem = menuItem {
                // Cập nhật món ăn
                var updatedItem = menuItem
                await viewModel.updateMenuItem(updatedItem, in: menu, imageData: nil)
                // Cập nhật các trường
                // Xử lý cập nhật
                appState.sourceModel.showSuccess("Cập nhật món thành công!")
            } else {
                // Tạo món mới
                let newItem = MenuItem(
                    menuId: menu.id!,
                    name: name.trimmingCharacters(in: .whitespacesAndNewlines),
                    price: priceValue,
                    category: category.trimmingCharacters(in: .whitespacesAndNewlines),
                    recipe: recipe
                )
                await viewModel.createMenuItem(newItem, in: menu, imageData: nil)
                // Xử lý tạo mới
                appState.sourceModel.showSuccess("Thêm món thành công!")
            }
            
            appState.coordinator.dismiss()
        }
    }
}

struct FormField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let field: MenuItemFormView.Field
    let focusedField: FocusState<MenuItemFormView.Field?>.Binding
    var keyboardType: UIKeyboardType = .default
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            
            TextField(placeholder, text: $text)
                .focused(focusedField, equals: field)
                .keyboardType(keyboardType)
                .textFieldStyle(CustomTextFieldStyle())
                .autocorrectionDisabled()
        }
    }
}

struct RecipeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @Binding var recipe: [Recipe]
    
    @State private var selectedIngredient: IngredientUsage?
    @State private var quantity = ""
    @State private var selectedUnit = MeasurementUnit.gram
    @State private var showingIngredientPicker = false
    @State private var ingredients: [Recipe] = []
    @State private var searchText = ""
    
    private var isFormValid: Bool {
        selectedIngredient != nil && !quantity.isEmpty && Double(quantity) != nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header
                headerSection
                
                // Ingredient List
                recipeList
                
                // Add Ingredient Form
                addIngredientForm
                
                Spacer()
            }
            .padding()
            .navigationTitle("Công thức món ăn")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Huỷ") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Xong") {
                        recipe = ingredients
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingIngredientPicker) {
                IngredientPicker(viewModel: IngredientViewModel(source: appState.sourceModel), selectedIngredient: $selectedIngredient)
            }
        }
        .onAppear {
            ingredients = recipe
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Danh sách nguyên liệu")
                .font(.headline)
            
            if ingredients.isEmpty {
                Text("Chưa có nguyên liệu nào")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private var recipeList: some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(ingredients, id: \.ingredientUsage.id) { ingredient in
                    RecipeRow(recipe: ingredient) { recipe in
                        if let index = ingredients.firstIndex(where: { $0.ingredientUsage.id == recipe.ingredientUsage.id }) {
                            ingredients.remove(at: index)
                        }
                    }
                }
            }
        }
    }
    
    private var addIngredientForm: some View {
        VStack(spacing: 16) {
            // Ingredient Picker Button
            Button(action: {
                showingIngredientPicker = true
            }) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Chọn nguyên liệu")
                            .font(.headline)
                        Text(selectedIngredient?.name ?? "Chưa chọn nguyên liệu")
                            .font(.subheadline)
                            .foregroundColor(selectedIngredient == nil ? .secondary : .primary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
            }
            
            // Quantity Input
            HStack(spacing: 12) {
                TextField("Số lượng", text: $quantity)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(CustomTextFieldStyle())
                
                Picker("Đơn vị", selection: $selectedUnit) {
                    ForEach(MeasurementUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Add Button
            Button(action: addIngredient) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                    Text("Thêm nguyên liệu")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    isFormValid ?
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    ) :
                    LinearGradient(
                        colors: [Color(.systemGray4), Color(.systemGray3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .cornerRadius(12)
            }
            .disabled(!isFormValid)
        }
    }
    
    private func addIngredient() {
        guard let ingredient = selectedIngredient,
              let quantityValue = Double(quantity) else { return }
        
        let measurement = Measurement(value: quantityValue, unit: selectedUnit)
        let recipe = Recipe(
            ingredientUsage: ingredient,
            measurement: measurement,
            createdAt: Date(),
            updatedAt: Date()
        )
        
        withAnimation {
            ingredients.append(recipe)
        }
        
        // Reset form
        selectedIngredient = nil
        quantity = ""
        selectedUnit = .gram
    }
}

struct RecipeRow: View {
    let recipe: Recipe
    let onDelete: (Recipe) -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Circle()
                .fill(Color.blue.opacity(0.1))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "leaf.circle.fill")
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
            
            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.ingredientUsage.name)
                    .font(.headline)
                
                HStack {
                    Text("\(recipe.requiredAmount.value, specifier: "%.1f") \(recipe.requiredAmount.unit.rawValue)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Delete Button
            Button(action: {
                onDelete(recipe)
            }) {
                Image(systemName: "trash.circle.fill")
                    .font(.title2)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct IngredientPicker: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var viewModel: IngredientViewModel
    @Binding var selectedIngredient: IngredientUsage?
    @State private var searchText = ""
    @State private var ingredients: [IngredientUsage] = []
    
    var body: some View {
        NavigationView {
            VStack {
                // Search Bar
                SearchBar(text: $searchText, placeholder: "Tìm kiếm nguyên liệu...")
                    .padding()
                
                // Ingredient List
                List(filteredIngredients, id: \.id) { ingredient in
                    Button(action: {
                        selectedIngredient = ingredient
                        dismiss()
                    }) {
                        HStack(spacing: 12) {
                            // Icon
                            Circle()
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Image(systemName: "leaf.circle.fill")
                                        .foregroundStyle(
                                            LinearGradient(
                                                colors: [.green, .blue],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                )
                            
                            // Content
                            VStack(alignment: .leading, spacing: 4) {
                                Text(ingredient.name)
                                    .font(.headline)
                                
                                HStack {
                                    Text("\(ingredient.totalMeasurement, specifier: "%.1f") \(ingredient.measurementPerUnit.unit.displayName)")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Circle()
                                        .fill(ingredient.stockStatus.color)
                                        .frame(width: 8, height: 8)
                                    
                                    Text(ingredient.stockStatus.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("Chọn nguyên liệu")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Huỷ") {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            ingredients = viewModel.ingredients
        }
    }
    
    private var filteredIngredients: [IngredientUsage] {
        if searchText.isEmpty {
            return ingredients
        }
        return ingredients.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
}

struct CategorySuggestionView: View {
    @Binding var selectedCategory: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(SuggestedCategories.allCases, id: \.id) { category in
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            selectedCategory = category.name
                        }
                    } label: {
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(category.color.opacity(0.15))
                                    .frame(width: 40, height: 40)
                                
                                Image(systemName: category.icon)
                                    .font(.system(size: 20))
                                    .foregroundColor(category.color)
                            }
                            
                            Text(category.name)
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                        }
                        .frame(width: 70)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
//                                .shadow(
//                                    color: selectedCategory == category.name ? 
//                                        category.color.opacity(0.3) : .black.opacity(0.05),
//                                    radius: selectedCategory == category.name ? 8 : 4,
//                                    x: 0,
//                                    y: selectedCategory == category.name ? 4 : 2
//                                )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    selectedCategory == category.name ?
                                        category.color.opacity(0.5) : .clear,
                                    lineWidth: 1
                                )
                        )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }
}
