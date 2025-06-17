import SwiftUI

struct CustomerSearchSection: View {
    @ObservedObject var viewModel: OrderViewModel
    @EnvironmentObject private var appState: AppState
    @FocusState private var isSearchFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Thông tin khách hàng")
                .font(.headline)
            
            HStack {
                // Search bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Tìm theo số điện thoại", text: Binding(
                        get: { viewModel.customerSearchKey },
                        set: { viewModel.updateCustomerSearchKey($0) }
                    ))
                    .keyboardType(.numberPad)
                    .focused($isSearchFocused)
                    
                    if !viewModel.customerSearchKey.isEmpty {
                        Button {
                            viewModel.clearCustomerSearch()
                            isSearchFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.systemGray6)
                        //.shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(appState.sourceModel.currentThemeColors.order.primaryColor.opacity(0.3), lineWidth: 1)
                )
                
                // Add customer button
                Button {
                    appState.coordinator.navigateTo(.addCustomer, using: .present, with: .present)
                } label: {
                    Image(systemName: "person.badge.plus")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(
                            appState.sourceModel.currentThemeColors.order.gradient(for: colorScheme)
                        )
                        .clipShape(Circle())
                }
            }
            
            // Search results
            if !viewModel.customerSearchKey.isEmpty && !viewModel.searchedCustomers.isEmpty {
                ScrollView {
                    VStack(alignment: .leading, spacing: 8) {
                        ForEach(viewModel.searchedCustomers) { customer in
                            CustomerRow(customer: customer) {
                                withAnimation(.spring(response: 0.3)) {
                                    viewModel.selectCustomer(customer)
                                    viewModel.clearCustomerSearch()
                                    isSearchFocused = false
                                }
                            }
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }
                    }
                }
                .frame(maxHeight: 150)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            
            // Selected customer info
            if let customer = viewModel.selectedCustomer {
                HStack {
                    VStack(alignment: .leading) {
                        Text(customer.displayName)
                            .font(.subheadline.bold())
                        Text(customer.phoneNumber)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            viewModel.clearSelectedCustomer()
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }
        }
        .animation(.spring(response: 0.3), value: viewModel.searchedCustomers)
    }
}

struct CustomerRow: View {
    let customer: Customer
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    Text(customer.displayName)
                        .font(.subheadline.bold())
                    Text(customer.phoneNumber)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                Spacer()
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color(.systemBackground))
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AddCustomerView: View {
    @ObservedObject var viewModel: OrderViewModel
    @EnvironmentObject private var appState: AppState
    @State private var name = ""
    @State private var phoneNumber = ""
    @State private var gender: Gender = .male
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Icon
                    VStack(spacing: 16) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 50))
                            .foregroundStyle(appState.sourceModel.currentThemeColors.order.gradient(for: colorScheme))
                            .padding(.top, 20)
                        
                        Text("Thêm khách hàng mới")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                    }
                    
                    // Form Content
                    VStack(spacing: 20) {
                        // Name Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "person")
                                    .foregroundStyle(appState.sourceModel.currentThemeColors.order.gradient(for: colorScheme))
                                    .frame(width: 20)
                                Text("Họ và tên")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            TextField("Nhập họ tên khách hàng", text: $name)
                                .textFieldStyle(CustomTextFieldStyle())
                        }
                        
                        // Phone Field
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: "phone")
                                    .foregroundStyle(appState.sourceModel.currentThemeColors.order.gradient(for: colorScheme))
                                    .frame(width: 20)
                                Text("Số điện thoại")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            TextField("Nhập số điện thoại", text: $phoneNumber)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // Gender Picker
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "figure.dress.line.vertical.figure")
                                    .foregroundStyle(appState.sourceModel.currentThemeColors.order.gradient(for: colorScheme))
                                    .frame(width: 20)
                                Text("Giới tính")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                            }
                            
                            HStack(spacing: 12) {
                                // Male Button
                                Button(action: { gender = .male }) {
                                    HStack {
                                        Image(systemName: gender == .male ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(gender == .male ? .blue : .gray)
                                        Text("Nam")
                                            .foregroundColor(gender == .male ? .blue : .primary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(gender == .male ? Color.blue.opacity(0.1) : Color.gray.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(gender == .male ? Color.blue : Color.gray, lineWidth: 1)
                                    )
                                }
                                
                                // Female Button
                                Button(action: { gender = .female }) {
                                    HStack {
                                        Image(systemName: gender == .female ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(gender == .female ? .pink : .gray)
                                        Text("Nữ")
                                            .foregroundColor(gender == .female ? .pink : .primary)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 8)
                                            .fill(gender == .female ? Color.pink.opacity(0.1) : Color.gray.opacity(0.1))
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 8)
                                            .stroke(gender == .female ? Color.pink : Color.gray, lineWidth: 1)
                                    )
                                }
                                
                                Spacer()
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        Button(action: saveCustomer) {
                            HStack {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 16, weight: .semibold))
                                Text("Lưu khách hàng")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                appState.sourceModel.currentThemeColors.order.gradient(for: colorScheme)
                            )
                            .foregroundColor(.white)
                            .cornerRadius(12)
                            //.shadow(color: Color.blue.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(name.isEmpty || phoneNumber.isEmpty)
                        .opacity(name.isEmpty || phoneNumber.isEmpty ? 0.6 : 1.0)
                        
                        Button(action: {
//                            appState.coordinator.dismiss(style: .present)
                        }) {
                            Text("Hủy")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.gray.opacity(0.1))
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
        }
    }
    
    private func saveCustomer() {
        if isValidPhoneNumber(phoneNumber) {
            Task {
                await viewModel.createCustomer(name: name, phoneNumber: phoneNumber, gender: gender)
//                appState.coordinator.dismiss(style: .present)
            }
        } else {
            appState.sourceModel.showAlert(title: "Lỗi", message: "Số điện thoại không hợp lệ")
        }
    }
    
    private func isValidPhoneNumber(_ phone: String) -> Bool {
        let phoneRegex = "^[0-9]{10,11}$"
        let phonePredicate = NSPredicate(format: "SELF MATCHES %@", phoneRegex)
        return phonePredicate.evaluate(with: phone)
    }
}

// Custom Text Field Style
//struct CustomTextFieldStyle: TextFieldStyle {
//    func _body(configuration: TextField<Self._Label>) -> some View {
//        configuration
//            .padding(.horizontal, 16)
//            .padding(.vertical, 12)
//            .background(Color(.systemBackground))
//            .cornerRadius(10)
//            .overlay(
//                RoundedRectangle(cornerRadius: 10)
//                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
//            )
//            .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
//    }
//}
