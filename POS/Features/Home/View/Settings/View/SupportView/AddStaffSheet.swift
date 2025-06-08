import SwiftUI

struct AddStaffSheet: View {
    @ObservedObject var viewModel: StaffViewModel
    @Environment(\.dismiss) var dismiss
    @FocusState private var focusedField: Field?
    
    let staff: Staff?
    
    @State private var name = ""
    @State private var position = StaffPosition.cashier
    @State private var hourlyRate = ""
    @State private var isLoading = false
    
    private var isEditing: Bool { staff != nil }
    
    enum Field {
        case name, hourlyRate
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: isEditing ? "person.fill.viewfinder" : "person.fill.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text(isEditing ? "Chỉnh sửa nhân viên" : "Thêm nhân viên mới")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(isEditing ? "Cập nhật thông tin nhân viên" : "Điền thông tin để thêm nhân viên mới")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form Section
                    VStack(spacing: 24) {
                        // Basic Info Section
                        FormSection(title: "Thông tin cơ bản", systemImage: "person.text.rectangle.fill") {
                            VStack(spacing: 16) {
                                // Name
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Tên nhân viên", systemImage: "person.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    TextField("Nhập tên nhân viên", text: $name)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .padding(12)
                                        .background(Color(.systemGray6))
                                        .cornerRadius(12)
                                        .focused($focusedField, equals: .name)
                                }
                                
                                // Position
                                VStack(alignment: .leading, spacing: 8) {
                                    Label("Vị trí", systemImage: "person.badge.clock.fill")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                    
                                    Picker("Vị trí", selection: $position) {
                                        ForEach(StaffPosition.allCases, id: \.self) { position in
                                            Text(position.displayName)
                                                .tag(position)
                                        }
                                    }
                                    .pickerStyle(.segmented)
                                }
                            }
                        }
                        
                        // Salary Section
                        FormSection(title: "Thông tin lương", systemImage: "dollarsign.circle.fill") {
                            VStack(alignment: .leading, spacing: 8) {
                                Label("Lương theo giờ", systemImage: "creditcard.fill")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: "dollarsign.circle.fill")
                                        .foregroundColor(.blue)
                                    TextField("0", text: $hourlyRate)
                                        .keyboardType(.numberPad)
                                        .textFieldStyle(PlainTextFieldStyle())
                                        .focused($focusedField, equals: .hourlyRate)
                                    
                                    Text("VNĐ/giờ")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                if let rate = Double(hourlyRate), rate > 0 {
                                    Text("≈ \(formatCurrency(rate))/giờ")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                    
                    // Action Button
                    Button {
                        Task {
                            await saveStaff()
                        }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.title3)
                                Text(isEditing ? "Cập nhật" : "Thêm nhân viên")
                                    .font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: isFormValid ? [.blue, .purple] : [.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(15)
                        .shadow(color: isFormValid ? .blue.opacity(0.3) : .clear, radius: 5, x: 0, y: 2)
                    }
                    .disabled(!isFormValid || isLoading)
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("Hủy")
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.red.opacity(0.8), .orange.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    }
                }
            }
            .onAppear {
                if let staff = staff {
                    name = staff.name
                    position = staff.position
                    hourlyRate = String(format: "%.0f", staff.hourlyRate)
                }
            }
        }
        .interactiveDismissDisabled(isLoading)
    }
    
    // MARK: - Helper Methods
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        Double(hourlyRate) ?? 0 > 0
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: value)) ?? "0"
        return "\(formattedNumber)đ"
    }
    
    private func saveStaff() async {
        guard let rate = Double(hourlyRate) else { return }
        
        isLoading = true
        focusedField = nil
        
        do {
            if let staff = staff {
                // Update existing staff
                try await viewModel.updateStaff(
                    staff,
                    name: name,
                    position: position,
                    hourlyRate: rate
                )
            } else {
                // Create new staff
                try await viewModel.createStaff(
                    name: name,
                    position: position,
                    hourlyRate: rate
                )
            }
            dismiss()
        } catch {
            // Handle error
            print("Error saving staff: \(error)")
        }
        
        isLoading = false
    }
}

// MARK: - Supporting Views
private struct FormSection<Content: View>: View {
    let title: String
    let systemImage: String
    let content: Content
    
    init(title: String, systemImage: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.systemImage = systemImage
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Label(title, systemImage: systemImage)
                .font(.headline)
                .foregroundColor(.primary)
            
            content
                .padding(16)
                .background(Color(.systemBackground))
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
    }
} 
