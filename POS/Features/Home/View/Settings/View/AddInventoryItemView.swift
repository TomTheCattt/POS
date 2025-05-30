import SwiftUI

struct AddInventoryItemView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @EnvironmentObject private var appState: AppState
    let editingItem: InventoryItem? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var name = ""
    @State private var quantity = 0.0
    @State private var selectedUnit: MeasurementUnit?
    @State private var measurementValue = 1.0
    @State private var selectedMeasurementUnit: MeasurementUnit?
    @State private var costPrice = 0.0
    @State private var minQuantity = 0.0
    @State private var showingImportSheet = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin cơ bản")) {
                    TextField("Tên sản phẩm", text: $name)
                        .keyboardType(.default)
                    
                    HStack {
                        Text("Số lượng:")
                        TextField("0", value: $quantity, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Đơn vị:")
                        Picker("", selection: $selectedUnit) {
                            Text("Chọn đơn vị").tag(Optional<MeasurementUnit>.none)
                            ForEach(MeasurementUnit.allCases) { unit in
                                Text(unit.displayName).tag(Optional(unit))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                Section(header: Text("Định lượng cho 1 đơn vị")) {
                    HStack {
                        Text("Giá trị:")
                        TextField("1", value: $measurementValue, format: .number)
                            .keyboardType(.decimalPad)
                    }
                    
                    HStack {
                        Text("Đơn vị đo:")
                        Picker("", selection: $selectedMeasurementUnit) {
                            Text("Chọn đơn vị").tag(Optional<MeasurementUnit>.none)
                            ForEach(MeasurementUnit.allCases) { unit in
                                Text(unit.displayName).tag(Optional(unit))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section(header: Text("Thông tin bổ sung")) {
                    HStack {
                        Text("Giá nhập:")
                        TextField("0", value: $costPrice, format: .number)
                            .keyboardType(.decimalPad)
                        Text("₫")
                    }

                    HStack {
                        Text("Số lượng tối thiểu:")
                        TextField("0", value: $minQuantity, format: .number)
                            .keyboardType(.decimalPad)
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
            .navigationTitle(editingItem == nil ? "Thêm sản phẩm mới" : "Chỉnh sửa sản phẩm")
            .navigationBarItems(
                leading: Button("Hủy") {
                    dismiss()
                },
                trailing: Button(editingItem == nil ? "Thêm" : "Lưu") {
                    Task {
                        await saveInventoryItem()
                    }
                }
                .disabled(name.isEmpty || quantity < 0 || selectedUnit == nil || selectedMeasurementUnit == nil || costPrice < 0)
            )
            .sheet(isPresented: $showingImportSheet) {
                ImportInventoryItemsView(viewModel: viewModel)
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
    
    private func saveInventoryItem() async {
        isLoading = true
        defer { isLoading = false }
        
        let measurement = Measurement(
            value: measurementValue,
            unit: selectedMeasurementUnit ?? .gram
        )
        
        let inventoryItem = InventoryItem(
            name: name,
            quantity: quantity,
            unit: selectedUnit ?? .piece,
            measurement: measurement,
            minQuantity: minQuantity,
            costPrice: costPrice,
            createdAt: editingItem?.createdAt ?? Date(),
            updatedAt: Date()
        )
        
        do {
            if let editingItem = editingItem {
                await viewModel.updateInventoryItem(inventoryItem)
            } else {
                await viewModel.createInventoryItem(inventoryItem)
            }
            dismiss()
        }
    }
}

struct ImportInventoryItemsView: View {
    @ObservedObject var viewModel: InventoryViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var showingFilePicker = false
    @State private var isLoading = false
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Nhập danh sách sản phẩm từ file Excel hoặc CSV")
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
                
                Text("Lưu ý: File cần có các cột: Tên sản phẩm, Số lượng, Đơn vị, Giá nhập, Danh mục")
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
            await viewModel.importInventoryItems(from: url)
            dismiss()
        }
    }
} 
