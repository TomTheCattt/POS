import SwiftUI

//struct MenuItemDetailView: View {
//    let item: MenuItem
//    @ObservedObject var viewModel: MenuViewModel
//    @EnvironmentObject private var appState: AppState
//    @Environment(\.dismiss) private var dismiss
//    @State private var showingEditSheet = false
//    @State private var showingDeleteAlert = false
//    @State private var ingredients: [IngredientWithDetails] = []
//    
//    struct IngredientWithDetails: Identifiable {
//        let id: String
//        let name: String
//        let quantity: Double
//        let unit: MeasurementUnit
//        let isAvailable: Bool
//    }
//    
//    var body: some View {
//        NavigationView {
//            ScrollView {
//                VStack(alignment: .leading, spacing: 20) {
//                    // Hình ảnh sản phẩm
//                    if let imageURL = item.imageURL {
//                        AsyncImage(url: imageURL) { image in
//                            image
//                                .resizable()
//                                .aspectRatio(contentMode: .fill)
//                        } placeholder: {
//                            Color.gray.opacity(0.2)
//                        }
//                        .frame(height: 200)
//                        .clipShape(RoundedRectangle(cornerRadius: 12))
//                    } else {
//                        Rectangle()
//                            .fill(Color.gray.opacity(0.2))
//                            .frame(height: 200)
//                            .clipShape(RoundedRectangle(cornerRadius: 12))
//                    }
//                    
//                    // Thông tin cơ bản
//                    Group {
//                        Text(item.name)
//                            .font(.title)
//                            .bold()
//                        
//                        Text(String(format: "%.0f₫", item.price))
//                            .font(.title2)
//                            .foregroundColor(.blue)
//                        
//                        Text("Danh mục: \(item.category)")
//                            .font(.subheadline)
//                            .foregroundColor(.secondary)
//                        
//                        HStack {
//                            Image(systemName: item.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
//                                .foregroundColor(item.isAvailable ? .green : .red)
//                            Text(item.isAvailable ? "Còn món" : "Hết món")
//                            if !item.isAvailable {
//                                Text("(Thiếu nguyên liệu)")
//                                    .font(.caption)
//                                    .foregroundColor(.red)
//                            }
//                        }
//                    }
//                    .padding(.horizontal)
//                    
//                    // Nguyên liệu
//                    if !ingredients.isEmpty {
//                        VStack(alignment: .leading, spacing: 12) {
//                            Text("Nguyên liệu")
//                                .font(.headline)
//                            
//                            ForEach(ingredients) { ingredient in
//                                HStack {
//                                    Image(systemName: ingredient.isAvailable ? "checkmark.circle.fill" : "xmark.circle.fill")
//                                        .foregroundColor(ingredient.isAvailable ? .green : .red)
//                                        .font(.caption)
//                                    
//                                    Text(ingredient.name)
//                                        .fontWeight(.medium)
//                                    
//                                    Spacer()
//                                    
//                                    Text("\(String(format: "%.1f", ingredient.quantity)) \(ingredient.unit.displayName)")
//                                        .foregroundColor(.secondary)
//                                }
//                                .padding(.vertical, 4)
//                            }
//                        }
//                        .padding(.horizontal)
//                        .padding(.top)
//                    }
//                    
//                    Spacer()
//                }
//            }
//            .navigationBarTitleDisplayMode(.inline)
//            .navigationBarItems(
//                leading: Button("Đóng") {
//                    dismiss()
//                },
//                trailing: HStack {
//                    Button {
//                        showingEditSheet = true
//                    } label: {
//                        Image(systemName: "pencil")
//                    }
//                    
//                    Button {
//                        showingDeleteAlert = true
//                    } label: {
//                        Image(systemName: "trash")
//                            .foregroundColor(.red)
//                    }
//                }
//            )
//            .alert("Xóa món", isPresented: $showingDeleteAlert) {
//                Button("Hủy", role: .cancel) { }
//                Button("Xóa", role: .destructive) {
//                    Task {
//                        await viewModel.deleteMenuItem(item)
//                        dismiss()
//                    }
//                }
//            } message: {
//                Text("Bạn có chắc chắn muốn xóa món này không?")
//            }
//            .sheet(isPresented: $showingEditSheet) {
//                AddMenuItemView(viewModel: viewModel)
//            }
//            .task {
//                await loadIngredientDetails()
//            }
//        }
//    }
//    
//    private func loadIngredientDetails() async {
//        //guard let itemIngredients = item.ingredients else { return }
//        
//        var loadedIngredients: [IngredientWithDetails] = []
////        for ingredient in item.ingredients {
////            if let IngredientUsage = appState.sourceModel.inventory?.first(where: { $0.id == ingredient.IngredientUsageID }) {
////                loadedIngredients.append(IngredientWithDetails(
////                    id: IngredientUsage.id ?? "",
////                    name: IngredientUsage.name,
////                    quantity: ingredient.quantity,
////                    unit: ingredient.unit,
////                    isAvailable: IngredientUsage.stockStatus != .outOfStock
////                ))
////            }
////        }
//        ingredients = loadedIngredients
//    }
//} 
