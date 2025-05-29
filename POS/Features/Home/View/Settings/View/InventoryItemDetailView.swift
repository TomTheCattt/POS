import SwiftUI

struct InventoryItemDetailView: View {
    let item: InventoryItem
    @ObservedObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var showingDeleteAlert = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin cơ bản")) {
                    HStack {
                        Text("Tên sản phẩm:")
                        Spacer()
                        Text(item.name)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Số lượng:")
                        Spacer()
                        Text("\(item.quantity) \(item.unit)")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Giá nhập:")
                        Spacer()
                        Text(String(format: "%.0f₫", item.costPrice))
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Thông tin bổ sung")) {
                    HStack {
                        Text("Số lượng tối thiểu:")
                        Spacer()
                        Text("\(item.minQuantity) \(item.unit)")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Thời gian")) {
                    HStack {
                        Text("Ngày tạo:")
                        Spacer()
                        Text(item.createdAt.formatted())
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("Cập nhật lần cuối:")
                        Spacer()
                        Text(item.updatedAt.formatted())
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Chi tiết sản phẩm")
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
            .alert("Xóa sản phẩm", isPresented: $showingDeleteAlert) {
                Button("Hủy", role: .cancel) { }
                Button("Xóa", role: .destructive) {
                    Task {
                        await viewModel.deleteInventoryItem(item)
                        dismiss()
                    }
                }
            } message: {
                Text("Bạn có chắc chắn muốn xóa sản phẩm này không?")
            }
            .sheet(isPresented: $showingEditSheet) {
                AddInventoryItemView(viewModel: viewModel)
            }
        }
    }
}
