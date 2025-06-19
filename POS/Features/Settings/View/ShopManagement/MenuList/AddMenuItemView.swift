import Combine
import SwiftUI

struct MenuItemFormView: View {
    @ObservedObject private var viewModel: MenuViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    private let menu: AppMenu
    private let menuItem: MenuItem?
    
    @State private var name = ""
    @State private var price = ""
    @State private var category = ""
    @State private var selectedImage: UIImage?
    @State private var showingImagePicker = false
    @State private var showingRecipeSheet = false
    @State private var recipe: [Recipe] = []
    @State private var isUploading = false
    @FocusState private var focusedField: AppTextField?
    
    // Validation states
    @State private var nameError: String?
    @State private var priceError: String?
    @State private var categoryError: String?
    @State private var recipeError: String?
    
    private var isFormValid: Bool {
        nameError == nil && 
        priceError == nil && 
        categoryError == nil && 
        recipeError == nil &&
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !price.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !category.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(price) != nil
    }
    
    init(viewModel: MenuViewModel, menu: AppMenu, menuItem: MenuItem?) {
        self.viewModel = viewModel
        self.menu = menu
        self.menuItem = menuItem
    }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false){
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
        .onChange(of: name) { _ in validateName() }
        .onChange(of: price) { _ in validatePrice() }
        .onChange(of: category) { _ in validateCategory() }
        .onChange(of: recipe) { _ in validateRecipe() }
    }
    
    private var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: menuItem == nil ? "plus.circle.fill" : "pencil.circle.fill")
                .font(.system(size: 50))
                .foregroundStyle(appState.currentTabThemeColors.gradient(for: colorScheme))
            
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
            ValidatedFormField(
                icon: "text.cursor",
                title: "Tên món",
                placeholder: "Nhập tên món...",
                text: $name,
                field: .addMenuItemSection(.name),
                focusedField: $focusedField,
                error: nameError
            )
            
            // Giá
            ValidatedFormField(
                icon: "banknote",
                title: "Giá bán",
                placeholder: "Nhập giá bán...",
                text: $price,
                field: .addMenuItemSection(.price),
                focusedField: $focusedField,
                keyboardType: .numberPad,
                error: priceError
            )
            
            // Danh mục
            VStack(alignment: .leading, spacing: 12) {
                Label("Danh mục", systemImage: "tag")
                    .font(.headline)
                
                CategorySuggestionView(selectedCategory: $category)
                
                VStack(alignment: .leading, spacing: 8) {
                    TextField("Hoặc nhập danh mục khác...", text: $category)
                        .focused($focusedField, equals: .addMenuItemSection(.category))
                        .textFieldStyle(CustomTextFieldStyle())
                        .autocorrectionDisabled()
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(categoryError != nil ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                        )
                    
                    if let error = categoryError {
                        HStack(spacing: 4) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.caption)
                                .foregroundColor(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundColor(.red)
                        }
                        .transition(.opacity.combined(with: .move(edge: .top)))
                    }
                }
            }
        }
    }
    
    private var recipeSection: some View {
        VStack(alignment: .leading, spacing: 8) {
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
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(recipeError != nil ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                )
            }
            
            if let error = recipeError {
                HStack(spacing: 4) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.caption)
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
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
                appState.currentTabThemeColors.gradient(for: colorScheme) :
                LinearGradient(
                    colors: [Color(.systemGray4), Color(.systemGray3)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .foregroundColor(.white)
            .cornerRadius(16)
        }
        .disabled(!isFormValid || isUploading)
    }
    
    // MARK: - Validation Methods
    private func validateName() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedName.isEmpty {
            nameError = "Tên món không được để trống"
        } else if trimmedName.count < 2 {
            nameError = "Tên món phải có ít nhất 2 ký tự"
        } else if trimmedName.count > 50 {
            nameError = "Tên món không được vượt quá 50 ký tự"
        } else if !trimmedName.matches(pattern: "^[a-zA-ZÀ-ỹ0-9\\s\\-&()]+$") {
            nameError = "Tên món chỉ được chứa chữ cái, số và ký tự đặc biệt cơ bản"
        } else {
            nameError = nil
        }
    }
    
    private func validatePrice() {
        let trimmedPrice = price.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedPrice.isEmpty {
            priceError = "Giá bán không được để trống"
        } else if let priceValue = Double(trimmedPrice) {
            if priceValue <= 0 {
                priceError = "Giá bán phải lớn hơn 0"
            } else if priceValue > 1000000000 {
                priceError = "Giá bán không được vượt quá 1 tỷ VND"
            } else {
                priceError = nil
            }
        } else {
            priceError = "Giá bán phải là số hợp lệ"
        }
    }
    
    private func validateCategory() {
        let trimmedCategory = category.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if trimmedCategory.isEmpty {
            categoryError = "Danh mục không được để trống"
        } else if trimmedCategory.count < 2 {
            categoryError = "Danh mục phải có ít nhất 2 ký tự"
        } else if trimmedCategory.count > 30 {
            categoryError = "Danh mục không được vượt quá 30 ký tự"
        } else {
            categoryError = nil
        }
    }
    
    private func validateRecipe() {
        if recipe.isEmpty {
            recipeError = "Vui lòng thêm ít nhất một nguyên liệu vào công thức"
        } else if recipe.count > 20 {
            recipeError = "Công thức không được vượt quá 20 nguyên liệu"
        } else {
            // Kiểm tra từng nguyên liệu
            for (index, recipeItem) in recipe.enumerated() {
                if recipeItem.requiredAmount.value <= 0 {
                    recipeError = "Nguyên liệu thứ \(index + 1) phải có số lượng lớn hơn 0"
                    return
                }
            }
            recipeError = nil
        }
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
        
        // Validate initial data
        validateName()
        validatePrice()
        validateCategory()
        validateRecipe()
    }
    
    private func handleSubmit() async {
        // Validate all fields before submit
        validateName()
        validatePrice()
        validateCategory()
        validateRecipe()
        
        guard isFormValid else { 
            appState.sourceModel.showError("Vui lòng kiểm tra lại thông tin")
            return 
        }
        
        isUploading = true
        defer { isUploading = false }
        
        do {
            let priceValue = Double(price) ?? 0
            
            if let menuItem = menuItem {
                // Cập nhật món ăn
                var updatedItem = menuItem
                updatedItem.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedItem.price = priceValue
                updatedItem.category = category.trimmingCharacters(in: .whitespacesAndNewlines)
                updatedItem.recipe = recipe
                
                if let imageData = selectedImage?.jpegData(compressionQuality: 0.7) {
                    try await viewModel.updateMenuItem(updatedItem, in: menu, imageData: imageData)
                } else {
                    try await viewModel.updateMenuItem(updatedItem, in: menu, imageData: nil)
                }
                
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
                
                if let imageData = selectedImage?.jpegData(compressionQuality: 0.7) {
                    try await viewModel.createMenuItem(newItem, in: menu, imageData: imageData)
                } else {
                    try await viewModel.createMenuItem(newItem, in: menu, imageData: nil)
                }
                
                appState.sourceModel.showSuccess("Thêm món thành công!")
            }
            
            appState.coordinator.dismiss()
        } catch {
            appState.sourceModel.showError("Có lỗi xảy ra: \(error.localizedDescription)")
        }
    }
}

// MARK: - Validated Form Field
struct ValidatedFormField: View {
    let icon: String
    let title: String
    let placeholder: String
    @Binding var text: String
    let field: AppTextField
    let focusedField: FocusState<AppTextField?>.Binding
    var keyboardType: UIKeyboardType = .default
    let error: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.headline)
            
            VStack(alignment: .leading, spacing: 8) {
                TextField(placeholder, text: $text)
                    .focused(focusedField, equals: field)
                    .keyboardType(keyboardType)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocorrectionDisabled()
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(error != nil ? Color.red.opacity(0.5) : Color.clear, lineWidth: 1)
                    )
                
                if let error = error {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                            .foregroundColor(.red)
                        Text(error)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }
}

// MARK: - String Extension for Validation
extension String {
    func matches(pattern: String) -> Bool {
        return self.range(of: pattern, options: .regularExpression) != nil
    }
}

struct RecipeFormView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var appState: AppState
    @Binding var recipe: [Recipe]
    @Environment(\.colorScheme) private var colorScheme
    
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
        ScrollView(showsIndicators: false){
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
                    appState.currentTabThemeColors.gradient(for: colorScheme) :
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
                                .fill(.primary.opacity(0.05))
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
