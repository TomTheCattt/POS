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
                SearchBar(text: $searchText, placeholder: "Tìm kiếm món...")
                
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
            bottomToolbar
        }
        .navigationTitle("Quản lý thực đơn")
        .sheet(isPresented: $showingAddEditSheet) {
//            MenuItemFormView(
//                item: selectedItem,
//                inventoryItems: [],
//                onSave: handleSaveMenuItem,
//                onAddNewIngredient: handleAddNewIngredient
//            )
        }
        .sheet(isPresented: $showingImportSheet) {
            ImportDataView()
        }
        .sheet(isPresented: $showingHistorySheet) {
            InventoryHistoryView()
        }
    }
    
    private var bottomToolbar: some View {
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
                Label("Thêm món mới", systemImage: "plus.circle.fill")
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
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
    
    private func handleSaveMenuItem(_ newItem: MenuItem) {
        if let existingItem = selectedItem {
            // Update existing item
        } else {
            // Add new item
        }
        showingAddEditSheet = false
    }
    
    private func handleAddNewIngredient() {
        // Handle adding new ingredient
    }
    
    private func handleAction(_ action: ActionType) {
        switch action {
        case .import:
            showingImportSheet = true
        case .export:
            // Handle export
            break
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
                imageView
                infoView
            }
        }
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(
                    color: Color.black.opacity(0.1),
                    radius: 2,
                    x: 0,
                    y: 1
                )
        )
    }
    
    private var imageView: some View {
        Group {
            if let imageURL = item.imageURL {
                AsyncImage(url: imageURL) { image in
                    image.resizable().aspectRatio(contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
            } else {
                Color.gray.opacity(0.2)
            }
        }
        .frame(height: 120)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private var infoView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(.headline)
            
            Text(String(format: "%.0f₫", item.price))
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            availabilityBadge
        }
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var availabilityBadge: some View {
        Text(item.isAvailable ? "Còn món" : "Hết món")
            .font(.caption)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(item.isAvailable ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
            .foregroundColor(item.isAvailable ? .green : .red)
            .clipShape(Capsule())
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
//    UpdateMenuView(viewModel: MenuViewModel(source: SourceModel()))
//        .environmentObject(AppState())
//}
