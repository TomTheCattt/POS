//
//  SettingsView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/5/25.
//

import SwiftUI

// MARK: - Settings Models
enum SettingsCategory: String, CaseIterable, Identifiable {
    case account = "Tài khoản"
    case shops = "Cửa hàng"
    case theme = "Giao diện"
    case printer = "Máy in"
    case language = "Ngôn ngữ"
    
    var id: String { rawValue }
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .account:
            return "person.circle.fill"
        case .shops:
            return "building.2.fill"
        case .theme:
            return "paintbrush.fill"
        case .printer:
            return "printer.fill"
        case .language:
            return "globe"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .account:
            return .blue
        case .shops:
            return .green
        case .theme:
            return .purple
        case .printer:
            return .orange
        case .language:
            return .indigo
        }
    }
    
    var options: [SettingsOption] {
        switch self {
        case .account:
            return [
                .account(.profile),
                .account(.security),
                .account(.notifications),
                .account(.privacy)
            ]
        case .shops:
            return [
                .shop(.locations),
                .shop(.menu),
                .shop(.inventory),
                .shop(.staff)
            ]
        case .theme, .printer, .language:
            return []
        }
    }
}

enum SettingsOption: Identifiable {
    case account(AccountOption)
    case shop(ShopOption)
    
    var id: String {
        switch self {
        case .account(let option):
            return "account_\(option.rawValue)"
        case .shop(let option):
            return "shop_\(option.rawValue)"
        }
    }
    
    var title: String {
        switch self {
        case .account(let option):
            return option.title
        case .shop(let option):
            return option.title
        }
    }
    
    var icon: String {
        switch self {
        case .account(let option):
            return option.icon
        case .shop(let option):
            return option.icon
        }
    }
    
    var iconColor: Color {
        switch self {
        case .account(let option):
            return option.iconColor
        case .shop(let option):
            return option.iconColor
        }
    }
}

enum AccountOption: String {
    case profile = "Thông tin cá nhân"
    case security = "Bảo mật"
    case notifications = "Thông báo"
    case privacy = "Quyền riêng tư"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .profile:
            return "person.fill"
        case .security:
            return "lock.fill"
        case .notifications:
            return "bell.fill"
        case .privacy:
            return "hand.raised.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .profile:
            return .blue
        case .security:
            return .red
        case .notifications:
            return .orange
        case .privacy:
            return .purple
        }
    }
}

enum ShopOption: String {
    case locations = "Quản lý cửa hàng"
    case menu = "Thực đơn"
    case inventory = "Nguyên liệu"
    case staff = "Nhân viên"
    
    var title: String { rawValue }
    
    var icon: String {
        switch self {
        case .locations:
            return "building.2.fill"
        case .menu:
            return "list.bullet.clipboard.fill"
        case .inventory:
            return "archivebox.fill"
        case .staff:
            return "person.2.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .locations:
            return .green
        case .menu:
            return .blue
        case .inventory:
            return .orange
        case .staff:
            return .purple
        }
    }
}

// MARK: - Supporting Views
struct OwnerAuthenticationSheet: View {
    @EnvironmentObject private var appState: AppState
    @Binding var isAuthenticated: Bool
    let ownerPassword: String
    @Environment(\.dismiss) var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var attempts: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 50))
                    .foregroundColor(appState.currentTabThemeColors.primaryColor)
                    .padding()
                
                Text("Xác thực chủ sở hữu")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Nhập mật khẩu chủ sở hữu để tiếp tục")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                SecureField("Mật khẩu chủ sở hữu", text: $password)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding(.horizontal)
                
                if showError {
                    Text("Mật khẩu không chính xác")
                        .font(.caption)
                        .foregroundColor(.red)
                }
                
                Button {
                    authenticate()
                } label: {
                    Text("Xác nhận")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 200)
                        .padding()
                        .background(appState.currentTabThemeColors.gradient(for: colorScheme))
                        .cornerRadius(12)
                }
                .disabled(password.isEmpty)
                .opacity(password.isEmpty ? 0.6 : 1)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hủy") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func authenticate() {
        if password == ownerPassword {
            isAuthenticated = true
            dismiss()
        } else {
            attempts += 1
            showError = true
            password = ""
            
            // Disable after 3 failed attempts
            if attempts >= 3 {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    dismiss()
                }
            }
        }
    }
}

struct AddShopSheet: View {
    @ObservedObject var viewModel: ShopManagementViewModel
    @EnvironmentObject private var appState: AppState
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.colorScheme) private var colorScheme
    
    let shop: Shop?
    
    private var isEditing: Bool { shop != nil }
    
    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false){
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                appState.currentTabThemeColors.gradient(for: colorScheme)
                            )
                        
                        Text(isEditing ? "Chỉnh sửa cửa hàng" : "Thêm cửa hàng mới")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text(isEditing ? "Cập nhật thông tin cửa hàng" : "Điền thông tin để tạo cửa hàng của bạn")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 20)
                    
                    // Form Section
                    VStack(spacing: 24) {
                        // Basic Info Section
                        FormSection(title: "Thông tin cơ bản", systemImage: "info.circle.fill") {
                            CustomTextField(title: "Tên cửa hàng", text: $viewModel.shopName, icon: "building.fill", placeholder: "Nhập tên cửa hàng")
                                .focused($isTextFieldFocused)
                            
                            CustomTextField(
                                title: "Địa chỉ",
                                text: $viewModel.address,
                                icon: "location.fill",
                                placeholder: "Nhập địa chỉ cửa hàng"
                            )
                        }
                        
                        // Business Hours Section
                        FormSection(title: "Giờ hoạt động", systemImage: "clock.fill") {
                            VStack(alignment: .leading, spacing: 12) {
                                VStack(spacing: 16) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Giờ mở cửa")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            DatePicker("", selection: $viewModel.openTime, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .frame(maxWidth: .infinity)
                                                .padding(8)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(8)
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            Text("Giờ đóng cửa")
                                                .font(.subheadline)
                                                .foregroundColor(.secondary)
                                            
                                            DatePicker("", selection: $viewModel.closeTime, displayedComponents: .hourAndMinute)
                                                .labelsHidden()
                                                .frame(maxWidth: .infinity)
                                                .padding(8)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(8)
                                        }
                                    }
                                    
                                    Text(formatBusinessHours())
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        
                        // Financial Info Section
                        FormSection(title: "Thông tin tài chính", systemImage: "banknote.fill") {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Tiền thuê mặt bằng", systemImage: "house.fill")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "dollarsign.circle.fill")
                                            .foregroundColor(appState.currentTabThemeColors.primaryColor)
                                        TextField("0", value: $viewModel.groundRent, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    .padding(12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.systemGray6)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(appState.currentTabThemeColors.primaryColor.opacity(0.3), lineWidth: 1)
                                    )
                                    
                                    Picker("", selection: $viewModel.currency) {
                                        ForEach([Currency.vnd, Currency.usd], id: \.self) { currency in
                                            HStack {
                                                Text(currency.symbol)
                                                Text(currency.rawValue)
                                            }
                                            .tag(currency)
                                        }
                                    }
                                    .pickerStyle(MenuPickerStyle())
                                    .foregroundStyle(appState.currentTabThemeColors.primaryColor)
                                    .frame(width: 100)
                                    .padding(8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.systemGray6)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(appState.currentTabThemeColors.primaryColor.opacity(0.3), lineWidth: 1)
                                    )
                                }
                                
                                if viewModel.groundRent > 0 {
                                    Text("≈ \(formattedGroundRent)/tháng")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        
                        // Point Rate Section
                        FormSection(title: "Tỷ lệ tích điểm", systemImage: "star.circle.fill") {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Phần trăm tích điểm từ tổng hóa đơn", systemImage: "percent")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack {
                                    Image(systemName: "star.fill")
                                        .foregroundColor(.orange)
                                    
                                    TextField("0", value: $viewModel.pointRate, format: .number)
                                        .keyboardType(.decimalPad)
                                        .textFieldStyle(RoundedBorderTextFieldStyle())
                                    
                                    Text("%")
                                        .font(.headline)
                                        .foregroundColor(.secondary)
                                }
                                .padding(12)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                if viewModel.pointRate > 0.0 {
                                    Text("Khách hàng sẽ nhận \(String(format: "%.1f", viewModel.pointRate))% điểm từ tổng hóa đơn")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
                                }
                            }
                        }
                        
                        // Discount Vouchers Section
                        FormSection(title: "Mã khuyến mãi", systemImage: "ticket.fill") {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack {
                                    Label("Danh sách voucher", systemImage: "tag.fill")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Spacer()
                                    
                                    Button {
                                        appState.coordinator.navigateTo(.addVoucher, using: .present, with: .present)
                                    } label: {
                                        HStack(spacing: 4) {
                                            Image(systemName: "plus.circle.fill")
                                            Text("Thêm")
                                        }
                                        .font(.subheadline)
                                        .foregroundColor(.blue)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(Color.blue.opacity(0.1))
                                        .cornerRadius(8)
                                    }
                                }
                                
                                if viewModel.discountVouchers.isEmpty {
                                    VStack(spacing: 8) {
                                        Image(systemName: "ticket")
                                            .font(.system(size: 40))
                                            .foregroundColor(.gray.opacity(0.5))
                                        
                                        Text("Chưa có voucher nào")
                                            .font(.subheadline)
                                            .foregroundColor(.secondary)
                                        
                                        Text("Nhấn 'Thêm' để tạo voucher đầu tiên")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 20)
                                } else {
                                    ForEach(Array(viewModel.discountVouchers.enumerated()), id: \.offset) { index, voucher in
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(voucher.name)
                                                    .font(.headline)
                                                    .foregroundColor(.primary)
                                                
                                                Text("Giảm \(String(format: "%.1f", voucher.value))% tổng hóa đơn")
                                                    .font(.subheadline)
                                                    .foregroundColor(.secondary)
                                            }
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            
                                            Button {
                                                viewModel.removeVoucher(at: index)
                                            } label: {
                                                Image(systemName: "trash.circle.fill")
                                                    .foregroundColor(.red)
                                                    .font(.title2)
                                            }
                                        }
                                        .padding(12)
                                        .background(
                                            LinearGradient(
                                                colors: [.green.opacity(0.1), .blue.opacity(0.1)],
                                                startPoint: .leading,
                                                endPoint: .trailing
                                            )
                                        )
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.green.opacity(0.3), lineWidth: 1)
                                        )
                                    }
                                }
                            }
                        }
                        
                        // Status Section
                        FormSection(title: "Trạng thái", systemImage: "checkmark.circle.fill") {
                            Toggle("Kích hoạt cửa hàng", isOn: $viewModel.isActive)
                                .toggleStyle(SwitchToggleStyle(tint: .blue))
                                .padding(.vertical, 8)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Validation Errors
                    if !viewModel.getValidationErrors().isEmpty {
                        validationErrorsView
                    }
                    
                    // Create Button
                    Button {
                        Task {
                            isTextFieldFocused = false
                            try await viewModel.createNewShop()
                        }
                    } label: {
                        HStack {
                            if viewModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: isEditing ? "checkmark.circle.fill" : "plus.circle.fill")
                                    .font(.title3)
                                Text(isEditing ? "Cập nhật cửa hàng" : "Tạo cửa hàng")
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
                    }
                    .disabled(!isFormValid || viewModel.isLoading)
                    .padding()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        appState.coordinator.dismiss(style: .present)
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
            .onChange(of: viewModel.shopName) { _ in
                viewModel.clearValidationErrors()
            }
            .onChange(of: viewModel.address) { _ in
                viewModel.clearValidationErrors()
            }
            .onChange(of: viewModel.groundRent) { _ in
                viewModel.clearValidationErrors()
            }
            .onChange(of: viewModel.pointRate) { _ in
                viewModel.clearValidationErrors()
            }
            .onChange(of: viewModel.openTime) { _ in
                viewModel.clearValidationErrors()
            }
            .onChange(of: viewModel.closeTime) { _ in
                viewModel.clearValidationErrors()
            }
            .onChange(of: viewModel.discountVouchers) { _ in
                viewModel.clearValidationErrors()
            }
        }
    }
    
    // MARK: - Helper Methods
    private func formatBusinessHours() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let openTimeStr = formatter.string(from: viewModel.openTime)
        let closeTimeStr = formatter.string(from: viewModel.closeTime)
        return "\(openTimeStr) - \(closeTimeStr)"
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        viewModel.isFormValid
    }
    
    private var formattedGroundRent: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: viewModel.groundRent)) ?? "0"
        return "\(formattedNumber)\(viewModel.currency.symbol)"
    }
    
    // MARK: - Validation Display
    private var validationErrorsView: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(viewModel.getValidationErrors(), id: \.errorDescription) { error in
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundColor(.red)
                        .font(.caption)
                    
                    Text(error.errorDescription ?? "")
                        .font(.caption)
                        .foregroundColor(.red)
                    
                    Spacer()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.red.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Add Voucher Sheet
struct AddVoucherSheet: View {
    @ObservedObject private var viewModel: ShopManagementViewModel
    @EnvironmentObject private var appState: AppState
    @FocusState private var isNameFieldFocused: Bool
    
    init(viewModel: ShopManagementViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    Image(systemName: "ticket.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.green, .blue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("Thêm mã khuyến mãi")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Tạo voucher giảm giá cho cửa hàng")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top)
                
                // Form
                VStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Tên voucher", systemImage: "tag.fill")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        TextField("Nhập tên voucher", text: $viewModel.voucherName)
                            .focused($isNameFieldFocused)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .font(.body)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Phần trăm giảm giá", systemImage: "percent")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        HStack {
                            TextField("0", value: $viewModel.voucherValue, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                            
                            Text("%")
                                .font(.headline)
                                .foregroundColor(.secondary)
                        }
                        
                        if viewModel.voucherValue > 0 {
                            Text("Voucher sẽ giảm \(String(format: "%.1f", viewModel.voucherValue))% tổng hóa đơn")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Buttons
                VStack(spacing: 12) {
                    Button {
                        viewModel.addVoucher()
                        //appState.coordinator.dismiss(style: .present)
                    } label: {
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                            Text("Lưu voucher")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            LinearGradient(
                                colors: isVoucherValid ? [.green, .blue] : [.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    .disabled(!isVoucherValid)
                    
                    Button {
                        appState.coordinator.dismiss(style: .present)
                    } label: {
                        Text("Hủy")
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                isNameFieldFocused = true
            }
        }
    }
    
    private var isVoucherValid: Bool {
        !viewModel.voucherName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        viewModel.voucherValue > 0 && viewModel.voucherValue <= 100
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
        }
    }
}

// MARK: - Theme Preview Card
struct ThemePreviewCard: View {
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    let style: AppThemeStyle
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    Text(style.displayName)
                        .font(.headline)
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(appState.currentTabThemeColors.primaryColor)
                    }
                }
                
                // Color Preview
                VStack(spacing: 12) {
                    ForEach(HomeTab.allCases, id: \.self) { tab in
                        tabColorPreview(for: tab, with: style.colors)
                    }
                }
            }
            .padding()
            .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func tabColorPreview(for tab: HomeTab, with colors: AppThemeColors) -> some View {
        let tabColors: TabThemeColor
        switch tab {
        case .order:
            tabColors = colors.order
        case .history:
            tabColors = colors.history
        case .expense:
            tabColors = colors.expense
        case .revenue:
            tabColors = colors.revenue
        case .settings:
            tabColors = colors.settings
        }
        
        return HStack(spacing: 12) {
            Image(systemName: tab.icon)
                .foregroundColor(tabColors.primaryColor)
                .frame(width: 24)
            
            Text(tab.title)
                .font(.subheadline)
            
            Spacer()
            
            // Color previews
            HStack(spacing: 8) {
                Circle()
                    .fill(tabColors.primaryColor)
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(tabColors.secondaryColor)
                    .frame(width: 24, height: 24)
                Circle()
                    .fill(tabColors.accentColor)
                    .frame(width: 24, height: 24)
            }
        }
        .padding(8)
        .backgroundLayer(tabThemeColors: appState.currentTabThemeColors)
    }
}

// MARK: - Main View
struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var appState: AppState
    @Environment(\.colorScheme) var colorScheme
    @Namespace private var animation
    
    @State private var appearAnimation = false
    @State private var selectedTabAnimation = false
    
    private var activatedShop: Shop? {
        appState.sourceModel.activatedShop
    }
    
    var body: some View {
        Group {
            if isIphone {
                iphoneLayout
            } else {
                iPadLayout
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                appearAnimation = true
            }
            Task {
                appState.sourceModel.setupShopsListener()
            }
        }
        .onDisappear {
            Task {
                appState.sourceModel.removeShopsListener()
            }
        }
    }
    
}

// MARK: - iPhone Layout
extension SettingsView {
    private var iphoneLayout: some View {
        ScrollView(showsIndicators: false){
            VStack(spacing: 24) {
                userProfileCard
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(y: appearAnimation ? 0 : 20)
                
                if let activeShop = activatedShop {
                    activeShopCard(activeShop)
                        .opacity(appearAnimation ? 1 : 0)
                        .offset(y: appearAnimation ? 0 : 20)
                }
                
                // Settings Categories
                VStack(spacing: 16) {
                    ForEach(SettingsCategory.allCases) { category in
                        VStack(spacing: 0) {
                            // Main Category
                            settingsCategoryCard(category)
                                .opacity(appearAnimation ? 1 : 0)
                                .offset(y: appearAnimation ? 0 : 20)
                            
                            // SubOptions if expanded
                            if viewModel.isOwnerAuthenticated {
                                if category == .account && viewModel.isAccountExpanded {
                                    subOptionsContainer(for: category)
                                } else if category == .shops && viewModel.isManageShopExpanded {
                                    subOptionsContainer(for: category)
                                }
                            }
                        }
                    }
                }
                
                if viewModel.isOwnerAuthenticated {
                    ownerActionsSection
                }
            }
            .padding()
        }
        .navigationTitle("Cài đặt")
        
    }
    
    // MARK: - iPhone Layout Cards
    private var userProfileCard: some View {
        VStack(spacing: 16) {
            userAvatar
            userInfo
        }
        .frame(maxWidth: .infinity)
        .padding(24)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 20)
    }
    
    private var userAvatar: some View {
        Group {
            if let photoURL = appState.sourceModel.currentUser?.photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                }
                .frame(width: 80, height: 80)
                .clipShape(Circle())
                .overlay(avatarBorder)
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 80, height: 80)
                    .foregroundStyle(avatarGradient)
            }
        }
    }
    
    private var avatarBorder: some View {
        Circle()
            .stroke(appState.currentTabThemeColors.gradient(for: colorScheme), lineWidth: 3)
    }
    
    private var avatarGradient: LinearGradient {
        appState.currentTabThemeColors.gradient(for: colorScheme)
    }
    
    private var userInfo: some View {
        VStack(spacing: 8) {
            Text(appState.sourceModel.currentUser?.displayName ?? "")
                .font(.title2)
                .fontWeight(.bold)
            
            if viewModel.isOwnerAuthenticated {
                Text(appState.sourceModel.currentUser?.email ?? "")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                ownerBadge
            }
        }
    }
    
    private var ownerBadge: some View {
        HStack {
            Image(systemName: "checkmark.shield.fill")
                .foregroundColor(.green)
            Text("Chủ sở hữu")
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.green.opacity(0.1))
        .cornerRadius(12)
    }
    
    private func activeShopCard(_ shop: Shop) -> some View {
        VStack(spacing: 16) {
            shopHeader(shop)
            shopStatus
        }
        .padding(20)
        .layeredCard(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 20)
    }
    
    private func shopHeader(_ shop: Shop) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text("Cửa hàng đang hoạt động")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(shop.shopName)
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            Spacer()
            
            shopSwitchButton
        }
    }
    
    private var shopSwitchButton: some View {
        Menu {
            ForEach(appState.sourceModel.shops ?? []) { shop in
                Button {
                    Task {
                        await viewModel.switchShop(to: shop)
                    }
                } label: {
                    if shop.id == appState.sourceModel.activatedShop?.id {
                        Label(shop.shopName, systemImage: "checkmark")
                    } else {
                        Text(shop.shopName)
                    }
                }
                .tint(.primary)
            }
        } label: {
            HStack {
                Text("Đổi cửa hàng")
                    .font(.subheadline)
                Image(systemName: "chevron.up.chevron.down")
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(appState.currentTabThemeColors.primaryColor.opacity(0.1))
            .cornerRadius(12)
        }
    }
    
    private var shopStatus: some View {
        HStack {
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                Text("Đang hoạt động")
                    .font(.subheadline)
                    .foregroundColor(.green)
            }
            
            Spacer()
            
            Text(formatBusinessHours())
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    // MARK: - Settings Category Cards
    private func settingsCategoryCard(_ category: SettingsCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                handleCategoryTap(category)
            }
        } label: {
            HStack(spacing: 16) {
                categoryIcon(category)
                categoryInfo(category)
                Spacer()
                categoryIndicator(category)
            }
            .padding(16)
            .layeredCard(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 20)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Owner Actions Section
    private var ownerActionsSection: some View {
        VStack(spacing: 16) {
            addShopButton
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
            ownerLogoutButton
                .opacity(appearAnimation ? 1 : 0)
                .offset(y: appearAnimation ? 0 : 20)
        }
    }
    
    // MARK: - Helper Methods
    private func formatBusinessHours() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        let openTimeStr = formatter.string(from: appState.sourceModel.activatedShop?.businessHours.openTime ?? Date())
        let closeTimeStr = formatter.string(from: appState.sourceModel.activatedShop?.businessHours.closeTime ?? Date())
        return "\(openTimeStr) - \(closeTimeStr)"
    }
}

// MARK: - iPad Layout
extension SettingsView {
    private var iPadLayout: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // MARK: - Sidebar
                sidebarView(width: geometry.size.width * 0.25)
                    .background(
                        RoundedRectangle(cornerRadius: 0)
                            .fill(.regularMaterial)
                            .overlay(
                                LinearGradient(
                                    colors: [
                                        Color.clear,
                                        appState.currentTabThemeColors.secondaryColor.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .ignoresSafeArea()
                    )
                    .frame(maxHeight: .infinity)
                    .opacity(appearAnimation ? 1 : 0)
                    .offset(x: appearAnimation ? 0 : -50)
                
                // MARK: - Content Area
                settingsContentView
                .frame(maxWidth: .infinity)
                .opacity(appearAnimation ? 1 : 0)
                .offset(x: appearAnimation ? 0 : 50)
            }
        }
    }
    
    // MARK: Side bar for iPad
    private func sidebarView(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            // User Profile Section
            userProfileSection
            
            ModernDivider(tabThemeColors: appState.currentTabThemeColors)
            
            // Active Shop Section
            if let activeShop = activatedShop {
                activeShopSection(activeShop)
                ModernDivider(tabThemeColors: appState.currentTabThemeColors)
            }
            
            // Menu Options
            ScrollView(showsIndicators: false){
                VStack(alignment: .leading, spacing: 16) {
                    ForEach(SettingsCategory.allCases) { category in
                        categoryView(for: category)
                    }
                }
            }
            .padding(.horizontal)
            
            Spacer()
            
            // Add Shop Button (Only for authenticated owners)
            if viewModel.isOwnerAuthenticated {
                VStack(spacing: 8) {
                    addShopButton
                    ownerLogoutButton
                }
                .padding(.horizontal)
            }
        }
        .frame(width: width)
    }
    
    private var userProfileSection: some View {
        VStack(spacing: 12) {
            // User Avatar
            if let photoURL = appState.sourceModel.currentUser?.photoURL {
                AsyncImage(url: photoURL) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Image(systemName: "person.circle.fill")
                        .resizable()
                }
                .frame(width: 60, height: 60)
                .clipShape(Circle())
                .overlay(Circle().stroke(appState.currentTabThemeColors.primaryColor.opacity(0.2), lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundStyle(appState.currentTabThemeColors.animatedGradient(for: colorScheme))
            }
            
            // User Info
            VStack(spacing: 4) {
                Text(appState.sourceModel.currentUser?.displayName ?? "")
                    .font(.headline)
                if viewModel.isOwnerAuthenticated {
                    Text(appState.sourceModel.currentUser?.email ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                if viewModel.isOwnerAuthenticated {
                    HStack {
                        Image(systemName: "checkmark.shield.fill")
                            .foregroundColor(.green)
                        Text("Chủ sở hữu")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
            }
        }
        .padding()
    }
    
    private func activeShopSection(_ shop: Shop) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Cửa hàng đang hoạt động")
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shop.shopName)
                        .font(.headline)
                }
                
                Spacer()
                
                Menu {
                    ForEach(appState.sourceModel.shops ?? []) { shop in
                        Button {
                            Task {
                                await viewModel.switchShop(to: shop)
                            }
                        } label: {
                            if shop.id == appState.sourceModel.activatedShop?.id {
                                Label(shop.shopName, systemImage: "checkmark")
                            } else {
                                Text(shop.shopName)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "chevron.up.chevron.down")
                        .foregroundColor(appState.currentTabThemeColors.primaryColor)
                }
            }
            .padding()
            .middleLayer(tabThemeColors: appState.currentTabThemeColors)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    // MARK: - UI Options And Sub Options View
    private func categoryView(for category: SettingsCategory) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            categoryButton(for: category)
            
            if viewModel.isOwnerAuthenticated {
                if category == .account && viewModel.isAccountExpanded {
                    subOptionsContainer(for: category)
                } else if category == .shops && viewModel.isManageShopExpanded {
                    subOptionsContainer(for: category)
                }
            }
        }
    }
    
    private func categoryButton(for category: SettingsCategory) -> some View {
        VStack {
            HStack(spacing: 16) {
                categoryIcon(category)
                categoryInfo(category)
                Spacer()
                categoryIndicator(category)
            }
            .padding()
            .layeredSelectionButton(tabThemeColors: appState.currentTabThemeColors, cornerRadius: 12, isCapsule: false, isSelected: viewModel.selectedCategory == category, namespace: animation, geometryID: "selected_settings_category") {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    handleCategoryTap(category)
                }
            }
        }
    }
    
}

// MARK: - Handle navigation and display
extension SettingsView {
    private func handleCategoryTap(_ category: SettingsCategory) {
        if isIphone {
            // Reset các trạng thái khác khi chọn category mới
            if category != viewModel.selectedCategory {
                viewModel.isAccountExpanded = false
                viewModel.isManageShopExpanded = false
                viewModel.selectedOption = nil
            }
            
            // Xử lý xác thực chủ sở hữu
            if (category == .shops || category == .account) && !viewModel.isOwnerAuthenticated {
                appState.coordinator.navigateTo(.ownerAuth, using: .fullScreen)
                return
            }
            
            // Xử lý các category cụ thể
            switch category {
            case .account:
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.isAccountExpanded.toggle()
                    viewModel.isManageShopExpanded = false
                    viewModel.selectedCategory = .account
                }
                
            case .shops:
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.isManageShopExpanded.toggle()
                    viewModel.isAccountExpanded = false
                    viewModel.selectedCategory = .shops
                }
                
            case .theme:
                appState.coordinator.navigateTo(.theme)
                viewModel.selectedCategory = category
                
            case .printer:
                appState.coordinator.navigateTo(.setUpPrinter)
                viewModel.selectedCategory = category
                
            case .language:
                // Các tính năng đang phát triển
                viewModel.selectedCategory = category
                break
            }
        } else {
            // iPad logic
            if (category == .shops || category == .account) && !viewModel.isOwnerAuthenticated {
                appState.coordinator.navigateTo(.ownerAuth, using: .present, with: .present)
                return
            }
            
            switch category {
            case .account:
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.isAccountExpanded.toggle()
                    viewModel.isManageShopExpanded = false
                    viewModel.selectedCategory = .account
                }
                
            case .shops:
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.isManageShopExpanded.toggle()
                    viewModel.isAccountExpanded = false
                    viewModel.selectedCategory = .shops
                }
                
            case .theme:
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.selectedOption = nil
                    viewModel.isAccountExpanded = false
                    viewModel.isManageShopExpanded = false
                }
                viewModel.selectedCategory = category
                
            case .printer:
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.selectedOption = nil
                    viewModel.isAccountExpanded = false
                    viewModel.isManageShopExpanded = false
                }
                viewModel.selectedCategory = category
                
            case .language:
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.selectedOption = nil
                    viewModel.isAccountExpanded = false
                    viewModel.isManageShopExpanded = false
                }
                viewModel.selectedCategory = category
                break
            }
        }
    }
    
    private func navigateToSubOption(_ option: SettingsOption) {
        // Đóng các menu mở rộng trước khi điều hướng
//        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
//            viewModel.isAccountExpanded = false
//            viewModel.isManageShopExpanded = false
//        }
        
        // Điều hướng đến màn hình tương ứng
        switch option {
        case .account(let accountOption):
            if viewModel.isManageShopExpanded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.isManageShopExpanded = false
                }
            }
            switch accountOption {
            case .profile:
                if isIphone {
                    appState.coordinator.navigateTo(.accountDetail)
                } else {
                    viewModel.selectedOption = option
                }
                break
            case .security:
                if isIphone {
                    appState.coordinator.navigateTo(.password)
                } else {
                    viewModel.selectedOption = option
                }
                break
            case .notifications, .privacy:
                // Đang phát triển
                break
            }
        case .shop(let shopOption):
            if viewModel.isManageShopExpanded {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    viewModel.isAccountExpanded = false
                }
            }
            switch shopOption {
            case .locations:
                if isIphone {
                    appState.coordinator.navigateTo(.manageShops)
                } else {
                    viewModel.selectedOption = option
                }
                break
            case .menu:
                if isIphone {
                    appState.coordinator.navigateTo(.menuSection(activatedShop))
                } else {
                    viewModel.selectedOption = option
                }
                break
            case .inventory:
                if isIphone {
                    appState.coordinator.navigateTo(.ingredientSection(activatedShop))
                } else {
                    viewModel.selectedOption = option
                }
                break
            case .staff:
                if isIphone {
                    appState.coordinator.navigateTo(.staff(activatedShop!))
                } else {
                    viewModel.selectedOption = option
                }
                break
            }
        }
    }
}

// MARK: - Settings Content View For iPad
extension SettingsView {
    private var settingsContentView: some View {
        ZStack {
            if let selectedCategory = viewModel.selectedCategory {
                Group {
                    contentForCategory(selectedCategory)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                placeholderView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut, value: viewModel.selectedCategory)
    }
    
    private var placeholderView: some View {
        VStack {
            Image(systemName: "gearshape")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text("Chọn một tùy chọn từ menu")
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Display Content For Settings Categories
    @ViewBuilder
    private func contentForCategory(_ category: SettingsCategory) -> some View {
        if let selectedOption = viewModel.selectedOption {
            if viewModel.isOwnerAuthenticated {
                contentForOption(selectedOption)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                requireOwnerAuthView
            }
        } else {
            switch category {
            case .account, .shops:
                if viewModel.isOwnerAuthenticated {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(category.title)
                            .font(.title)
                            .bold()
                        
                        Text("Chọn một mục từ menu bên trái để xem chi tiết")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding()
                } else {
                    requireOwnerAuthView
                }
            case .theme:
                appState.coordinator.makeView(for: .theme)
            case .printer:
                appState.coordinator.makeView(for: .setUpPrinter)
            case .language:
                Text("Đang phát triển")
                    .foregroundStyle(Color.secondary)
            }
        }
    }
    
    @ViewBuilder
    private func contentForOption(_ option: SettingsOption) -> some View {
        switch option {
        case .account(let accountOption):
            switch accountOption {
            case .profile:
                appState.coordinator.makeView(for: .accountDetail)
            case .security:
                appState.coordinator.makeView(for: .password)
            case .notifications, .privacy:
                Text("Đang phát triển...")
                    .foregroundColor(.secondary)
            }
        case .shop(let shopOption):
            switch shopOption {
            case .locations:
                appState.coordinator.makeView(for: .manageShops)
            case .menu:
                appState.coordinator.makeView(for: .menuSection(activatedShop))
            case .inventory:
                appState.coordinator.makeView(for: .ingredientSection(activatedShop))
            case .staff:
                appState.coordinator.makeView(for: .staff(activatedShop!))
            }
        }
    }
    
    private var requireOwnerAuthView: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Xác thực chủ sở hữu")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Để thực hiện thao tác này, bạn cần xác thực với mật khẩu chủ sở hữu")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button {
                appState.coordinator.navigateTo(.ownerAuth, using: .present, with: .present)
            } label: {
                Text("Xác thực ngay")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(width: 200)
                    .padding()
                    .background(appState.currentTabThemeColors.gradient(for: colorScheme))
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Common Components Extension
extension SettingsView {
    // MARK: - Owner Authenticated Section
    private var addShopButton: some View {
        Button {
            appState.coordinator.navigateTo(.addShop(nil), using: .present, with: .present)
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Thêm cửa hàng mới")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(appState.currentTabThemeColors.gradient(for: colorScheme))
            .cornerRadius(16)
        }
    }
    
    private var ownerLogoutButton: some View {
        Button {
            appState.sourceModel.logoutAsOwner()
        } label: {
            VStack(spacing: 8) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Đăng xuất chủ sở hữu")
                }
                Text("Thời gian còn lại: \(appState.sourceModel.remainingTimeString)")
                    .font(.footnote)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    // MARK: - Settings Category Components
    
    private func categoryIcon(_ category: SettingsCategory) -> some View {
        ZStack {
            Circle()
                .fill(category.iconColor.opacity(0.1))
                .frame(width: 44, height: 44)
            
            Image(systemName: category.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(category.iconColor)
        }
    }
    
    private func categoryInfo(_ category: SettingsCategory) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(category.title)
                .font(.headline)
                .foregroundColor(.primary)
            
            if !category.options.isEmpty {
                Text("\(category.options.count) tùy chọn")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func categoryIndicator(_ category: SettingsCategory) -> some View {
        Group {
            if (category == .shops || category == .account), !viewModel.isOwnerAuthenticated {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
                    .font(.system(size: 16, weight: .medium))
            } else if category == .account {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(viewModel.isAccountExpanded ? 90 : 0))
            } else if category == .shops {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(viewModel.isManageShopExpanded ? 90 : 0))
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
    }
    
    // MARK: - Sub-Options Container
    
    private func subOptionsContainer(for category: SettingsCategory) -> some View {
        VStack(spacing: 0) {
            // Visual connection line
            Rectangle()
                .fill(category.iconColor.opacity(0.2))
                .frame(width: 2)
                .frame(height: 8)
            
            // SubOptions
            VStack(spacing: 0) {
                ForEach(category.options) { option in
                    subOptionCard(option, parentCategory: category)
                }
            }
            .padding(.leading, 32)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(category.iconColor.opacity(0.05))
            )
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .transition(.asymmetric(
            insertion: .scale(scale: 0.95).combined(with: .opacity),
            removal: .scale(scale: 0.95).combined(with: .opacity)
        ))
    }
    
    private func subOptionCard(_ option: SettingsOption, parentCategory: SettingsCategory) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                navigateToSubOption(option)
            }
        } label: {
            HStack(spacing: 16) {
                // Visual connection line
                Rectangle()
                    .fill(parentCategory.iconColor.opacity(0.2))
                    .frame(width: 2)
                    .frame(height: 24)
                
                // Icon
                ZStack {
                    Circle()
                        .fill(option.iconColor.opacity(0.1))
                        .frame(width: 36, height: 36)
                    
                    Image(systemName: option.icon)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(option.iconColor)
                }
                
                // Info
                VStack(alignment: .leading, spacing: 4) {
                    Text(option.title)
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 16)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
    
}
