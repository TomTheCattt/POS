import SwiftUI

struct MenuView: View {
    
    private let strings = AppLocalizedString()
    
    @ObservedObject var viewModel: MenuViewModel
    @ObservedObject var coordinator: AppCoordinator
    
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
            TextField("Find item...", text: Binding(
                get: { viewModel.searchKey },
                set: { viewModel.updateSearchKey($0) }
            ))
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
                ForEach(viewModel.categories, id: \.self) { category in
                    OptionButton(
                        title: category,
                        isSelected: viewModel.selectedCategory == category
                    ) {
                        viewModel.updateSelectedCategory(category)
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
                ForEach(viewModel.filteredMenuItems) { item in
                    ItemView(menuItem: item) { temp, consump in
                        viewModel.addItemToOrder(item, temp, consump)
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
                    viewModel.clearOrder()
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
                Text(viewModel.displayName)
                    .font(.headline)
            }
        }
    }
    
    private func orderItemsList(geometry: GeometryProxy) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                ForEach(viewModel.selectedItems) { item in
                    orderItemView(for: item)
                    Divider()
                }
            }
        }
        .frame(height: geometry.size.height / 1.8)
    }
    
    private func orderItemView(for item: OrderItem) -> some View {
        let menuItem = viewModel.getMenuItem(by: item.menuItemId)
        
        return OrderItemView(
            orderItem: item,
            coordinator: coordinator,
            name: menuItem?.name ?? "Unknown Item",
            price: "$\(String(format: "%.2f", menuItem?.price ?? 0.0))",
            updateQuantity: { increment in
                viewModel.updateOrderItemQuantity(for: item.id, increment: increment)
            },
            updateNote: { note in
                viewModel.updateOrderItemNote(for: item.id, note: note)
            }
        )
        .padding(.vertical, 4)
    }
    
    private func orderTotalSection() -> some View {
        HStack {
            Text(strings.total)
                .font(.headline)
            Spacer()
            Text(viewModel.totalPrice)
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
                    OptionButton(
                        title: option.title,
                        isSelected: viewModel.paymentMethod == option
                    ) {
                        viewModel.updatePaymentMethod(option)
                    }
                }
            }
        }
    }
    
    private func paymentButton() -> some View {
        Button {
            viewModel.createOrder()
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
                .disabled(viewModel.selectedItems.isEmpty)
                .opacity(viewModel.selectedItems.isEmpty ? 0.5 : 1)
        }
        .padding(.top, 12)
    }
}

// MARK: - Supporting Views
struct ItemView: View {
    
    private let strings = AppLocalizedString()
    
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
        Image(systemName: "cup.and.saucer.fill")
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
                    OptionButton(
                        title: option.rawValue,
                        isSelected: temperature == option
                    ) {
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
                    OptionButton(
                        title: option.rawValue,
                        isSelected: consumption == option
                    ) {
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
            Text(strings.addItem)
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

//
//#Preview {
//    MenuView()
//}
