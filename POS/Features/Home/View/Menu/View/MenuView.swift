import SwiftUI

struct MenuView: View {
    
    @State private var searchKey: String = ""
    @State private var paymentMethod: PaymentMethod = .cash
    @State private var selectedItems: [OrderItem] = []
    @State private var selectedCategory: String = "Coffee"
    
    @ObservedObject var viewModel: MenuViewModel
    
    // Sample menu items for demonstration
    private let menuItems: [MenuItem] = [
        MenuItem(id: "1", name: "Coffee", price: 2, category: "Coffee", ingredients: [IngredientUsage(inventoryItemID: "1", quantity: 2, unit: .gram)], isAvailable: true),
        MenuItem(id: "2", name: "Coffee", price: 2, category: "Coffee", ingredients: [IngredientUsage(inventoryItemID: "1", quantity: 2, unit: .gram)], isAvailable: true),
        MenuItem(id: "3", name: "Coffee", price: 2, category: "Coffee", ingredients: [IngredientUsage(inventoryItemID: "1", quantity: 2, unit: .gram)], isAvailable: true),
        MenuItem(id: "4", name: "Coffee", price: 2, category: "Coffee", ingredients: [IngredientUsage(inventoryItemID: "1", quantity: 2, unit: .gram)], isAvailable: true),
        MenuItem(id: "5", name: "Coffee", price: 2, category: "Coffee", ingredients: [IngredientUsage(inventoryItemID: "1", quantity: 2, unit: .gram)], isAvailable: true),
        MenuItem(id: "6", name: "Coffee", price: 2, category: "Coffee", ingredients: [IngredientUsage(inventoryItemID: "1", quantity: 2, unit: .gram)], isAvailable: true),
        MenuItem(id: "7", name: "Coffee", price: 2, category: "Coffee", ingredients: [IngredientUsage(inventoryItemID: "1", quantity: 2, unit: .gram)], isAvailable: true),
        MenuItem(id: "8", name: "Coffee", price: 2, category: "Coffee", ingredients: [IngredientUsage(inventoryItemID: "1", quantity: 2, unit: .gram)], isAvailable: true),
        MenuItem(id: "9", name: "Coffee", price: 2, category: "Coffee", ingredients: [IngredientUsage(inventoryItemID: "1", quantity: 2, unit: .gram)], isAvailable: true),
        MenuItem(id: "10", name: "Coffee", price: 2, category: "Coffee", ingredients: [IngredientUsage(inventoryItemID: "1", quantity: 2, unit: .gram)], isAvailable: true)
    ]
    
    // Sample categories
    private let categories = ["All", "Coffee", "Tea", "Pastries", "Sandwiches", "Drinks"]
    
    // Filter menu items by category
    private var filteredMenuItems: [MenuItem] {
        menuItems.filter {
            (selectedCategory == "All" || $0.category == selectedCategory) &&
            (searchKey.isEmpty || $0.name.localizedCaseInsensitiveContains(searchKey))
        }
    }
    
    // Calculate total price
    private var totalPrice: String {
        let total = selectedItems.reduce(0.0) { result, item in
            // Find the corresponding menu item to get its price
            let menuItem = menuItems.first(where: { $0.id == item.menuItemId })
            let itemPrice = menuItem?.price ?? 0
            return result + Double(itemPrice) * Double(item.quantity)
        }
        return "$\(String(format: "%.2f", total))"
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(alignment: .top, spacing: 16) {
                leftSideMenu(geometry: geometry)
                rightSideOrder(geometry: geometry)
            }
        }
        .padding(.horizontal)
        .background(Color(.systemGray6))
    }
    
    // MARK: - Left side containing categories and menu items
    private func leftSideMenu(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading) {
            menuHeader(width: (geometry.size.width - 16) * 2 / 3)
            categoryScrollView()
            menuItemsGrid()
        }
        .frame(maxWidth: max((geometry.size.width - 16) * 2 / 3, 0))
        .frame(maxHeight: .infinity)
    }
    
    private func menuHeader(width: CGFloat) -> some View {
        HStack {
            Text("Choose Category")
                .fontWeight(.bold)
                .font(.system(size: 20))
            Spacer()
            searchField(width: width)
        }
    }
    
    private func searchField(width: CGFloat) -> some View {
        HStack {
            TextField("Find item...", text: $searchKey)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .disableAutocorrection(true)
                .italic()
            
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.trailing, 12)
        }
        .background(Color(.white))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: max(width * 0.6, 0))
    }
    
    private func categoryScrollView() -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(categories, id: \.self) { category in
                    OptionButton(
                        title: category,
                        isSelected: selectedCategory == category
                    ) {
                        selectedCategory = category
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
    
    private func menuItemsGrid() -> some View {
        ScrollView {
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 3),
                spacing: 24
            ) {
                ForEach(filteredMenuItems) { item in
                    ItemView(menuItem: item) { temp, consump in
                        addItemToOrder(item, temp, consump)
                    }
                    .frame(maxWidth: .infinity)
                    .aspectRatio(3/4, contentMode: .fit)
                    .background(Color.white)
                    .cornerRadius(12)
                    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                }
            }
        }
    }
    
    // MARK: - Right side containing order details
    private func rightSideOrder(geometry: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            userProfileHeader()
            
            HStack {
                Text("Order")
                    .font(.title3)
                    .fontWeight(.bold)
                Spacer()
                Button {
                    selectedItems.removeAll()
                } label: {
                    Text("Clear All")
                        .font(.footnote)
                        .italic()
                        .tint(Color.gray)
                }
            }
            
            orderItemsList(geometry: geometry)
            
            Divider()
                .padding(.vertical, 8)
            
            orderTotalSection()
            
            paymentMethodSection()
            
            paymentButton()
        }
        .padding(.horizontal)
        .frame(maxWidth: max((geometry.size.width - 16) / 3, 0))
        .frame(height: geometry.size.height)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(radius: 2)
    }
    
    private func userProfileHeader() -> some View {
        HStack(spacing: 12) {
            Image(systemName: "person.circle.fill")
                .resizable()
                .scaledToFill()
                .frame(width: 60, height: 60)
                .foregroundColor(.blue)
            
            VStack(alignment: .leading) {
                Text("Good morning,")
                    .foregroundColor(.secondary)
                Text(viewModel.getDisplayName())
                    .font(.headline)
            }
        }
    }
    
    private func orderItemsList(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(selectedItems) { item in
                    orderItemView(for: item)
                    Divider()
                }
            }
        }
        .frame(height: geometry.size.height / 1.8)
    }
    
    private func orderItemView(for item: OrderItem) -> some View {
        let menuItem = menuItems.first(where: { $0.id == item.menuItemId })
        
        return OrderItemView(
            orderItem: item,
            name: menuItem?.name ?? "Unknown Item",
            price: "$\(String(format: "%.2f", menuItem?.price ?? 0.0))"
        )
        .padding(.vertical, 4)
    }
    
    private func orderTotalSection() -> some View {
        HStack {
            Text("Total")
                .font(.headline)
            Spacer()
            Text(totalPrice)
                .font(.headline)
        }
    }
    
    private func paymentMethodSection() -> some View {
        VStack(alignment: .leading) {
            Text("Payment Method")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.top, 8)
            
            HStack {
                ForEach(PaymentMethod.allCases, id: \.self) { option in
                    OptionButton(title: option.title,
                                 isSelected: paymentMethod == option) {
                        paymentMethod = option
                    }
                }
            }
        }
    }
    
    private func paymentButton() -> some View {
        Button {
            let total = selectedItems.reduce(0.0) { result, item in
                let menuItem = menuItems.first(where: { $0.id == item.menuItemId })
                let price = menuItem?.price ?? 0
                return result + Double(price) * Double(item.quantity)
            }
            
            let discount = 0.0
            
            let newOrder = Order(id: UUID().uuidString, items: selectedItems, createdAt: Date(), createdBy: "Viet Anh Nguyen", totalAmount: total, discount: discount, paymentMethod: paymentMethod)
            
            print("Created order: \(newOrder)")
            
            selectedItems.removeAll()
            
        } label: {
            Text("Create Order")
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue)
                )
                .foregroundColor(.white)
                .font(.headline)
                .disabled(selectedItems.isEmpty)
                .opacity(selectedItems.isEmpty ? 0.5 : 1)
        }
        .padding(.top, 12)
    }
    
    // MARK: - Helper Functions
    private func addItemToOrder(_ item: MenuItem, _ temprature: TemperatureOption, _ consumption: ConsumptionOption) {
        if let index = selectedItems.firstIndex(where: {
            $0.menuItemId == item.id &&
            $0.temprature == temprature &&
            $0.consumption == consumption
        }) {
            selectedItems[index].quantity += 1
        } else {
            selectedItems.append(OrderItem(
                menuItemId: item.id,
                quantity: 1,
                note: "",
                temprature: temprature,
                consumption: consumption
            ))
        }
    }
}

// MARK: - Supporting Views
struct ItemView: View {
    let menuItem: MenuItem
    let addAction: (_ temperature: TemperatureOption, _ consumption: ConsumptionOption) -> Void
    
    @State private var temperature: TemperatureOption = .hot
    @State private var consumption: ConsumptionOption = .stay
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 8) {
                itemImage(width: geometry.size.width)
                itemHeader()
                
                temperatureOptions()
                consumptionOptions()
                
                Spacer(minLength: 0)
                addButton(width: geometry.size.width)
            }
            .padding()
            .background(Color.white)
            .cornerRadius(12)
            .shadow(radius: 2)
        }
    }
    
    private func itemImage(width: CGFloat) -> some View {
        // Use AsyncImage
        Image(systemName: "cup.and.saucer.fill") // Fallback image if URL is nil
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(maxWidth: width, maxHeight: width * 0.7)
            .padding(8)
            .background(Color(.systemGray5))
            .cornerRadius(12)
    }
    
    private func itemHeader() -> some View {
        HStack {
            Text(menuItem.name)
                .font(.headline)
                .lineLimit(1)
            Spacer()
            Text("$\(String(format: "%.2f", menuItem.price))")
                .fontWeight(.bold)
        }
    }
    
    private func temperatureOptions() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Temperature:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                ForEach(TemperatureOption.allCases, id: \.self) { option in
                    OptionButton(title: option.rawValue,
                                 isSelected: temperature == option) {
                        temperature = option
                    }
                }
            }
        }
    }
    
    private func consumptionOptions() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Consumption:")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                ForEach(ConsumptionOption.allCases, id: \.self) { option in
                    OptionButton(title: option.rawValue,
                                 isSelected: consumption == option) {
                        consumption = option
                    }
                }
            }
        }
    }
    
    private func addButton(width: CGFloat) -> some View {
        Button(action: {
            addAction(temperature, consumption)
            temperature = .hot
            consumption = .stay
        }) {
            Text("Add")
                .frame(maxWidth: width)
                .padding(8)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.blue)
                )
                .foregroundColor(.white)
                .font(.caption.bold())
        }
    }
}

struct OptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.vertical, 8)
                .padding(.horizontal, 16)
                .background(isSelected ? Color.blue : Color(.systemGray5))
                .clipShape(Capsule())
        }
    }
}

struct OrderItemView: View {
    @State var orderItem: OrderItem
    let name: String
    let price: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 16) {
                itemImage()
                itemDetails()
                Spacer()
                quantitySelector()
            }
            noteSection()
        }
    }
    
    private func itemImage() -> some View {
        Image(systemName: "cup.and.saucer.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 40, height: 40)
            .cornerRadius(8)
            .foregroundColor(.blue)
            .padding(8)
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
    
    private func itemDetails() -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(name)
                .font(.headline)
            Text(price)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private func quantitySelector() -> some View {
        HStack(spacing: 12) {
            Button(action: {
                if orderItem.quantity > 1 {
                    orderItem.quantity -= 1
                }
            }) {
                Image(systemName: "minus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
            
            Text("\(orderItem.quantity)")
                .font(.headline)
                .frame(width: 30)
            
            Button(action: {
                orderItem.quantity += 1
            }) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func noteSection() -> some View {
        HStack {
            Text("Temprature: \(orderItem.temprature.rawValue), Consumption: \(orderItem.consumption.rawValue)")
                .font(.footnote)
                .foregroundStyle(Color.gray)
            Spacer()
            Button {
                
            } label: {
                HStack {
                    Text("Note")
                        .font(.footnote)
                }
            }
        }
    }
}
//
//#Preview {
//    MenuView()
//}
