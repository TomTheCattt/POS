//
//  SettingsView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/5/25.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var appState: AppState
    
    @State private var isAccountExpanded: Bool = false
    @State private var selectedOption: SettingsOption?
    @State private var selectedSubOption: AccountSubOption?
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // MARK: - Sidebar
                sidebarView(width: geometry.size.width * 0.25)
                    .background(Color(.systemGroupedBackground))
                
                // MARK: - Content Area
                contentAreaView()
                    .frame(maxWidth: .infinity)
            }
        }
    }
    
    // MARK: - Sidebar View
    private func sidebarView(width: CGFloat) -> some View {
        VStack(spacing: 0) {
            // User Profile Section
            userProfileSection
            
            Divider()
            
            // Active Shop Section
            if let activeShop = appState.sourceModel.activatedShop {
                activeShopSection(activeShop)
            }
            
            Divider()
            
            // Menu Options
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(SettingsOption.allCases, id: \.self) { option in
                        optionView(for: option)
                        Divider()
                    }
                }
            }
            
            Spacer()
            
            // Add Shop Button (Only for authenticated owners)
            if viewModel.isOwnerAuthenticated {
                addShopButton
                
                // Owner Logout Button
                Button {
                    appState.sourceModel.logoutAsOwner()
                } label: {
                    VStack(spacing: 4) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Đăng xuất chủ sở hữu")
                            Spacer()
                        }
                        
                        HStack {
                            Image(systemName: "clock")
                                .font(.caption)
                            Text(appState.sourceModel.remainingTimeString)
                                .font(.caption)
                            Spacer()
                        }
                        .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color.red.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .padding(.bottom)
                }
                .buttonStyle(.plain)
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
                .overlay(Circle().stroke(Color.blue.opacity(0.2), lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .foregroundColor(.blue)
            }
            
            // User Info
            VStack(spacing: 4) {
                Text(appState.sourceModel.currentUser?.displayName ?? "")
                    .font(.headline)
                Text(appState.sourceModel.currentUser?.email ?? "")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Owner Badge (if authenticated)
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
                                await appState.sourceModel.switchShop(to: shop)
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
                        .foregroundColor(.blue)
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .padding(.horizontal)
        }
        .padding(.vertical)
    }
    
    private var addShopButton: some View {
        Button {
            appState.coordinator.navigateTo(.addShop, using: .present, with: .present)
        } label: {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Thêm cửa hàng mới")
            }
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.blue)
            .cornerRadius(12)
            .padding()
        }
    }
    
    // MARK: - Option Views
    private func optionView(for option: SettingsOption) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            optionButton(for: option)
            
            if option == .account && isAccountExpanded {
                subOptionsView(for: option)
            }
        }
    }
    
    private func optionButton(for option: SettingsOption) -> some View {
        Button {
            handleOptionTap(option)
        } label: {
            HStack(spacing: 12) {
                // Icon
                Image(systemName: option.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(option.iconColor)
                    .frame(width: 28, height: 28)
                    .background(option.iconColor.opacity(0.1))
                    .cornerRadius(8)
                
                // Title
                Text(option.title)
                    .font(.body)
                
                Spacer()
                
                // Chevron or Lock Icon
                Group {
                    if (option == .manageShops || option == .account), !viewModel.isOwnerAuthenticated {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                    } else if option == .account {
                        Image(systemName: isAccountExpanded ? "chevron.down" : "chevron.right")
                            .animation(.easeInOut(duration: 0.2), value: isAccountExpanded)
                    } else {
                        Image(systemName: "chevron.right")
                    }
                }
                .font(.system(size: 14, weight: .medium))
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedOption == option ? option.iconColor.opacity(0.1) : Color.clear)
            )
        }
        .foregroundColor(selectedOption == option ? option.iconColor : .primary)
    }
    
    private func subOptionsView(for option: SettingsOption) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(option.subOptions ?? []) { subOption in
                Divider()
                subOptionButton(for: subOption)
            }
        }
    }
    
    private func subOptionButton(for subOption: AccountSubOption) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedSubOption = subOption
                selectedOption = .account
            }
        } label: {
            HStack {
                Text(subOption.title)
                    .padding(.leading, 40)
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedSubOption == subOption ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .foregroundColor(selectedSubOption == subOption ? .blue : .primary)
    }
    
    // MARK: - Content Area
    private func contentAreaView() -> some View {
        ZStack {
            if let selectedOption = selectedOption {
                Group {
                    contentForOption(selectedOption)
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
            } else {
                placeholderView
            }
        }
        .animation(.easeInOut, value: selectedOption)
        .padding()
        .background(Color(.systemBackground))
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
                    .background(Color.blue)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    // MARK: - Handle Actions
    private func handleOptionTap(_ option: SettingsOption) {
        withAnimation(.easeInOut(duration: 0.25)) {
            if (option == .manageShops || option == .account) && !viewModel.isOwnerAuthenticated {
                selectedOption = option
            } else if option == .account {
                isAccountExpanded.toggle()
                if !isAccountExpanded {
                    selectedSubOption = nil
                }
            } else {
                selectedOption = option
                selectedSubOption = nil
                isAccountExpanded = false
            }
        }
    }
    
    @ViewBuilder
    private func contentForOption(_ option: SettingsOption) -> some View {
        switch option {
        case .account:
            if viewModel.isOwnerAuthenticated {
                if let subOption = selectedSubOption {
                    accountSubOptionContent(subOption)
                } else {
                    accountMainContent
                }
            } else {
                requireOwnerAuthView
            }
        case .manageShops:
            if viewModel.isOwnerAuthenticated {
                appState.coordinator.makeView(for: .manageShops)
            } else {
                requireOwnerAuthView
            }
        case .setUpPrinter:
            printerSetupContent
        case .language:
            languageContent
        case .theme:
            themeContent
        }
    }
    
    private var accountMainContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Tài khoản")
                .font(.title)
                .bold()
            
            Text("Chọn một mục từ menu bên trái để xem chi tiết")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    private func accountSubOptionContent(_ subOption: AccountSubOption) -> some View {
        Group {
            switch subOption {
            case .accountDetail:
                appState.coordinator.makeView(for: .accountDetail)
            case .password:
                appState.coordinator.makeView(for: .password)
            }
        }
    }
    
    private var manageShopsContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("Quản lý cửa hàng")
                    .font(.title)
                    .bold()
                
                Spacer()
                
//                if viewModel.canAddNewShop {
//                    Button {
//                        showAddShopSheet = true
//                    } label: {
//                        Label("Thêm cửa hàng", systemImage: "plus")
//                    }
//                    .buttonStyle(.borderedProminent)
//                }
            }
            
            if let shops = appState.sourceModel.shops {
                if shops.isEmpty {
                    emptyShopsView
                } else {
                    shopsListView(shops)
                }
            } else {
                ProgressView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    private var emptyShopsView: some View {
        VStack(spacing: 12) {
            Image(systemName: "building.2.crop.circle")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text("Chưa có cửa hàng nào")
                .font(.title3)
                .bold()
            
            Text("Bắt đầu bằng cách thêm cửa hàng đầu tiên của bạn")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func shopsListView(_ shops: [Shop]) -> some View {
        List(shops) { shop in
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(shop.shopName)
                        .font(.headline)
                }
                
                Spacer()
                
                if shop.isActive {
                    Text("Đang hoạt động")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                Task {
                    //await viewModel.selectShop(shop)
                }
            }
        }
    }
    
    private var printerSetupContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Cài đặt máy in")
                .font(.title)
                .bold()
            
            Text("Tính năng đang được phát triển")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    private var languageContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Ngôn ngữ")
                .font(.title)
                .bold()
            
            Text("Tính năng đang được phát triển")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    private var themeContent: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Giao diện")
                .font(.title)
                .bold()
            
            Text("Tính năng đang được phát triển")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
}

// MARK: - Supporting Views
struct OwnerAuthenticationSheet: View {
    @Binding var isAuthenticated: Bool
    let ownerPassword: String
    @Environment(\.dismiss) var dismiss
    
    @State private var password: String = ""
    @State private var showError: Bool = false
    @State private var attempts: Int = 0
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Image(systemName: "key.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.blue)
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
                        .background(Color.blue)
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
    @State private var name: String = ""
    @State private var address: String = ""
    @State private var phone: String = ""
    @State private var isLoading: Bool = false
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Thông tin cửa hàng")) {
                    TextField("Tên cửa hàng", text: $name)
                    TextField("Địa chỉ", text: $address)
                    TextField("Số điện thoại", text: $phone)
                        .keyboardType(.phonePad)
                }
                
                Section {
                    Button {
                        //createShop()
                    } label: {
                        HStack {
                            Text("Tạo cửa hàng")
                            if isLoading {
                                Spacer()
                                ProgressView()
                            }
                        }
                    }
                    .disabled(isLoading || name.isEmpty || address.isEmpty)
                }
            }
            .navigationTitle("Thêm cửa hàng mới")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Hủy") {
                        appState.coordinator.dismiss(style: .present)
                    }
                }
            }
        }
    }
}

// MARK: - Extensions
extension SettingsOption {
    var icon: String {
        switch self {
        case .account: return "person.fill"
        case .manageShops: return "building.2.fill"
        case .setUpPrinter: return "printer.fill"
        case .language: return "globe"
        case .theme: return "paintbrush.fill"
        }
    }
    
    var iconColor: Color {
        switch self {
        case .account: return .blue
        case .manageShops: return .orange
        case .setUpPrinter: return .purple
        case .language: return .green
        case .theme: return .pink
        }
    }
}

enum SettingsOption: CaseIterable {
    case account, manageShops, setUpPrinter, language, theme
    
    var title: String {
        switch self {
        case .account: return "Tài khoản"
        case .manageShops: return "Quản lý cửa hàng"
        case .setUpPrinter: return "Cài đặt máy in"
        case .language: return "Ngôn ngữ"
        case .theme: return "Giao diện"
        }
    }

    var subOptions: [AccountSubOption]? {
        switch self {
        case .account:
            return AccountSubOption.allCases
        default:
            return nil
        }
    }
}

enum AccountSubOption: String, CaseIterable, Identifiable {
    case accountDetail
    case password

    var id: String { rawValue }

    var title: String {
        switch self {
        case .accountDetail: return "Thông tin tài khoản"
        case .password: return "Đổi mật khẩu"
        }
    }
}

//#Preview {
//    SettingsView(
//        viewModel: SettingsViewModel(environment: AppEnvironment()),
//        coordinator: AppCoordinator()
//    )
//}
