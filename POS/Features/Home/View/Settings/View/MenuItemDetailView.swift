import SwiftUI

struct MenuItemDetailView: View {
    let item: MenuItem
    @ObservedObject var viewModel: MenuViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Hình ảnh sản phẩm
                    if let imageURL = item.imageURL {
                        AsyncImage(url: imageURL) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.gray.opacity(0.2)
                        }
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    } else {
                        Rectangle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(height: 200)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    // Thông tin cơ bản
                    Group {
                        Text(item.name)
                            .font(.title)
                            .bold()
                        
                        Text(String(format: "%.0f₫", item.price))
                            .font(.title2)
                            .foregroundColor(.blue)
                        
                        Text("Danh mục: \(item.category)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        if let isAvailable = item.isAvailable {
                            HStack {
                                Image(systemName: isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(isAvailable ? .green : .red)
                                Text(isAvailable ? "Còn món" : "Hết món")
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Nguyên liệu
                    if let ingredients = item.ingredients, !ingredients.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Nguyên liệu")
                                .font(.headline)
                            
                            ForEach(ingredients, id: \.inventoryItemID) { ingredient in
                                HStack {
                                    Text("• \(ingredient.quantity) \(ingredient.unit)")
//                                    if let inventoryItem = try await viewModel.getInventoryItem(by: ingredient.inventoryItemID) {
//                                        Text(inventoryItem.name)
//                                    }
                                }
                                .font(.subheadline)
                            }
                        }
                        .padding(.horizontal)
                    }
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarItems(
                leading: Button("Đóng") {
                    dismiss()
                },
                trailing: HStack {
                    Button {
                        showingEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                    
                    Button {
                        showingDeleteAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.red)
                    }
                }
            )
            .alert("Xóa món", isPresented: $showingDeleteAlert) {
                Button("Hủy", role: .cancel) { }
                Button("Xóa", role: .destructive) {
                    Task {
                        await viewModel.deleteMenuItem(item)
                        dismiss()
                    }
                }
            } message: {
                Text("Bạn có chắc chắn muốn xóa món này không?")
            }
            .sheet(isPresented: $showingEditSheet) {
                AddMenuItemView(viewModel: viewModel)
            }
        }
    }
} 
