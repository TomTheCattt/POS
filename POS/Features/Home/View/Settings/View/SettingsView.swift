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

    private let isIphone = UIDevice.current.userInterfaceIdiom == .phone

    var body: some View {
        Group {
            if isIphone {
                iphoneLayout
            } else {
                ipadLayout
            }
        }
        .onAppear {
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
    
    // MARK: - iPhone Layout
    private var iphoneLayout: some View {
        List {
            // User Profile Section
            Section {
                userProfileCell
            }
            
            // Active Shop Section
            if let activeShop = appState.sourceModel.activatedShop {
                Section {
                    activeShopCell(activeShop)
                }
            }
            
            // Settings Options
            Section {
                ForEach(SettingsOption.allCases, id: \.self) { option in
                    settingsOptionCell(option)
                }
            }
            
            // Owner Actions
            if viewModel.isOwnerAuthenticated {
                Section {
//                    addShopButton
//                    ownerLogoutButton
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle("Cài đặt")
        .alert("Xác thực chủ sở hữu", isPresented: $viewModel.showAuthAlert) {
            SecureField("Mật khẩu", text: $viewModel.ownerPassword)
            Button("Hủy", role: .cancel) {
                viewModel.ownerPassword = ""
            }
            Button("Xác nhận") {
                viewModel.authenticateOwner()
            }
        } message: {
            if let lockEndTimeRemaining = appState.sourceModel.lockEndTimeRemaining {
                Text("Tài khoản đã bị khóa. Vui lòng thử lại sau \(lockEndTimeRemaining)")
            } else {
                Text("Nhập mật khẩu chủ sở hữu để tiếp tục. Còn \(3 - viewModel.authAttempts) lần thử")
            }
        }
    }
    
    // MARK: - iPad Layout
    private var ipadLayout: some View {
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
        .alert("Xác thực chủ sở hữu", isPresented: $viewModel.showAuthAlert) {
            SecureField("Mật khẩu", text: $viewModel.ownerPassword)
            Button("Hủy", role: .cancel) {
                viewModel.ownerPassword = ""
            }
            Button("Xác nhận") {
                viewModel.authenticateOwner()
            }
        } message: {
            if let lockEndTimeRemaining = appState.sourceModel.lockEndTimeRemaining {
                Text("Tài khoản đã bị khóa. Vui lòng thử lại sau \(lockEndTimeRemaining)")
            } else {
                Text("Nhập mật khẩu chủ sở hữu để tiếp tục. Còn \(3 - viewModel.authAttempts) lần thử")
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
                Divider()
            }
            
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
                ownerLogoutButton
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
    
    private var ownerLogoutButton: some View {
        Button {
            appState.sourceModel.logoutAsOwner()
        } label: {
            VStack(spacing: 4) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text("Đăng xuất chủ sở hữu")
                }
                Text("Thời gian còn lại: \(appState.sourceModel.remainingTimeString)")
                    .font(.footnote)
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(12)
            .padding(.horizontal)
            .padding(.bottom)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Option Views
    private func optionView(for option: SettingsOption) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            optionButton(for: option)
            
            if viewModel.isOwnerAuthenticated {
                if option == .account && viewModel.isAccountExpanded {
                    subOptionsView(for: option)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .trailing)),
                            removal: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .trailing))
                        ))
                }
                if option == .manageShops && viewModel.isManageShopExpanded {
                subOptionsView(for: option)
                        .transition(.asymmetric(
                            insertion: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .trailing)),
                            removal: .scale(scale: 0.95).combined(with: .opacity).combined(with: .move(edge: .trailing))
                        ))
                }
            }
        }
    }
    
    private func optionButton(for option: SettingsOption) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            handleOptionTap(option)
            }
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
                
                // Lock Icon or Chevron
                if (option == .manageShops || option == .account), !viewModel.isOwnerAuthenticated {
                    Image(systemName: "lock.fill")
                        .foregroundColor(.orange)
                } else if option == .account {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(viewModel.isAccountExpanded ? 90 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isAccountExpanded)
                } else if option == .manageShops {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .rotationEffect(.degrees(viewModel.isManageShopExpanded ? 90 : 0))
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: viewModel.isManageShopExpanded)
                } else {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.selectedOption == option ? option.iconColor.opacity(0.1) : Color.clear)
            )
            .animation(.easeInOut(duration: 0.2), value: viewModel.selectedOption)
        }
        .foregroundColor(viewModel.selectedOption == option ? option.iconColor : .primary)
        .contextMenu {
            quickActionsMenu(for: option)
        }
    }
    
    private func subOptionsView(for option: SettingsOption) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(option.subOptions) { subOption in
                Divider()
                subOptionButton(for: subOption)
                    .transition(.asymmetric(
                        insertion: .move(edge: .leading).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            }
        }
        .background(Color(.systemBackground))
    }
    
    private func subOptionButton(for subOption: SubOption) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                viewModel.selectedSubOption = subOption
                handleSubOptionTap(subOption)
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: subOption.icon)
                    .font(.system(size: 14))
                    .foregroundColor(subOption.color)
                    .frame(width: 24, height: 24)
                    .background(subOption.color.opacity(0.1))
                    .cornerRadius(6)
                
                Text(subOption.title)
                    .font(.subheadline)
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
                    .opacity(viewModel.selectedSubOption?.id == subOption.id ? 1 : 0.5)
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(viewModel.selectedSubOption?.id == subOption.id ? 
                        subOption.color.opacity(0.1) : Color.clear)
            )
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - Content Area
    private func contentAreaView() -> some View {
        ZStack {
            if let selectedOption = viewModel.selectedOption {
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
        .animation(.easeInOut, value: viewModel.selectedOption)
        .padding()
        .background(Color(.systemBackground))
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
    
    @ViewBuilder
    private func contentForOption(_ option: SettingsOption) -> some View {
        if let subOption = viewModel.selectedSubOption {
            contentForSubOption(subOption)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .trailing).combined(with: .opacity)
                ))
        } else {
            switch option {
            case .account, .manageShops:
                if viewModel.isOwnerAuthenticated {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(option.title)
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
            case .setUpPrinter:
                printerSetupContent
            case .language:
                languageContent
            case .theme:
                themeContent
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
                    .background(Color.blue)
                    .cornerRadius(12)
            }
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
    
    // MARK: - Common Components
    private var userProfileCell: some View {
        HStack(spacing: 12) {
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
                .frame(width: 50, height: 50)
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.blue.opacity(0.2), lineWidth: 2))
            } else {
                Image(systemName: "person.circle.fill")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .foregroundColor(.blue)
            }
            
            // User Info
            VStack(alignment: .leading, spacing: 4) {
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
                    .padding(.horizontal, 8)
                    .padding(.vertical, 2)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(8)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            handleOptionTap(.account)
        }
    }
    
    private func activeShopCell(_ shop: Shop) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(shop.shopName)
                    .font(.headline)
                Text("Đang hoạt động")
                    .font(.caption)
                    .foregroundColor(.green)
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
                    .foregroundColor(.blue)
            }
        }
    }
    
    private func settingsOptionCell(_ option: SettingsOption) -> some View {
        HStack {
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
            
            // Lock Icon or Chevron
            if (option == .manageShops || option == .account), !viewModel.isOwnerAuthenticated {
                Image(systemName: "lock.fill")
                    .foregroundColor(.orange)
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }
        }
        .contentShape(Rectangle())
        .contextMenu {
            quickActionsMenu(for: option)
        }
        .onTapGesture {
            handleOptionTap(option)
        }
    }
    
    // MARK: - Quick Actions Menu
    @ViewBuilder
    private func quickActionsMenu(for option: SettingsOption) -> some View {
        switch option {
        case .account:
            if viewModel.isOwnerAuthenticated {
                Button {
                    // Xem thông tin nhanh
                } label: {
                    Label("Xem thông tin", systemImage: "person.fill")
                }
                
                Button {
                    // Chụp ảnh mới
                } label: {
                    Label("Chụp ảnh mới", systemImage: "camera.fill")
                }
                
                Button(role: .destructive) {
                    Task {
                        await appState.sourceModel.signOut()
                    }
                } label: {
                    Label("Đăng xuất", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
            
        case .manageShops:
            if viewModel.isOwnerAuthenticated {
                Button {
                    // Thêm cửa hàng mới
                    appState.coordinator.navigateTo(.addShop, using: .present, with: .present)
                } label: {
                    Label("Thêm cửa hàng", systemImage: "plus.circle.fill")
                }
                
                Button {
                    // Xem thông tin cửa hàng
                } label: {
                    Label("Thông tin cửa hàng", systemImage: "info.circle.fill")
                }
            }
            
        case .setUpPrinter:
            Button {
                // Test in
            } label: {
                Label("Test in", systemImage: "printer.fill.and.paper.fill")
            }
            
            Button {
                // Xem trạng thái
            } label: {
                Label("Trạng thái kết nối", systemImage: "wifi")
            }
            
        case .language:
            Button {
                // Chuyển Tiếng Việt
            } label: {
                Label("Tiếng Việt", systemImage: "character.book.closed.fill")
            }
            
            Button {
                // Switch to English
            } label: {
                Label("English", systemImage: "character.book.closed.fill")
            }
            
        case .theme:
            Button {
                // Chế độ sáng
            } label: {
                Label("Chế độ sáng", systemImage: "sun.max.fill")
            }
            
            Button {
                // Chế độ tối
            } label: {
                Label("Chế độ tối", systemImage: "moon.fill")
            }
        }
    }
    
    private func handleOptionTap(_ option: SettingsOption) {
        
        // light haptics
        
        if isIphone {
            if (option == .manageShops || option == .account) && !viewModel.isOwnerAuthenticated {
                viewModel.showAuthAlert = true
            } else if option == .account {
                
            } else {
                navigateToOption(option)
            }
        } else {
            if (option == .manageShops || option == .account) && !viewModel.isOwnerAuthenticated {
                viewModel.selectedOption = option
            } else if option == .account {
                viewModel.isAccountExpanded.toggle()
                viewModel.selectedOption = .account
//                if !viewModel.isAccountExpanded || !viewModel.isManageShopExpanded {
//                    viewModel.selectedSubOption = nil
//                }
                if viewModel.isAccountExpanded && viewModel.isManageShopExpanded {
                    viewModel.isManageShopExpanded = false
                }
            } else if option == .manageShops {
                viewModel.isManageShopExpanded.toggle()
                viewModel.selectedOption = .manageShops
//                if !viewModel.isAccountExpanded || !viewModel.isManageShopExpanded {
//                    viewModel.selectedSubOption = nil
//                }
                if viewModel.isAccountExpanded && viewModel.isManageShopExpanded {
                    viewModel.isAccountExpanded = false
                }
            } else {
                viewModel.selectedOption = option
                viewModel.selectedSubOption = nil
                viewModel.isAccountExpanded = false
                viewModel.isManageShopExpanded = false
            }
        }
    }
    
    private func navigateToOption(_ option: SettingsOption) {
        switch option {
        case .account:
            appState.coordinator.navigateTo(.accountDetail)
        case .manageShops:
            appState.coordinator.navigateTo(.manageShops)
        case .setUpPrinter:
            // Navigate to printer setup
            break
        case .language:
            // Navigate to language settings
            break
        case .theme:
            // Navigate to theme settings
            break
        }
    }
    
    private func handleSubOptionTap(_ subOption: SubOption) {
        if isIphone {
            navigateToSubOption(subOption)
        } else {
            viewModel.selectedSubOption = subOption
        }
    }
    
    private func navigateToSubOption(_ subOption: SubOption) {
        switch subOption.id {
        case "profile":
            appState.coordinator.navigateTo(.accountDetail)
        case "security":
            appState.coordinator.navigateTo(.password)
        case "shops":
            appState.coordinator.navigateTo(.manageShops)
        case "menu":
            appState.coordinator.navigateTo(.menuSection)
        case "inventory":
            appState.coordinator.navigateTo(.ingredientSection)
        case "staff":
            appState.coordinator.navigateTo(.staff)
        case "analytics":
            appState.coordinator.navigateTo(.analytics)
        default:
            break
        }
    }
    
    @ViewBuilder
    private func contentForSubOption(_ subOption: SubOption) -> some View {
        switch subOption.id {
        case "profile":
            appState.coordinator.makeView(for: .accountDetail)
        case "security":
            appState.coordinator.makeView(for: .password)
        case "notification":
            notificationSettingsView
        case "privacy":
            privacySettingsView
        case "shops":
            appState.coordinator.makeView(for: .manageShops)
        case "menu":
            appState.coordinator.makeView(for: .menuSection)
        case "inventory":
            appState.coordinator.makeView(for: .ingredientSection)
        case "staff":
            appState.coordinator.makeView(for: .staff)
        case "analytics":
            appState.coordinator.makeView(for: .analytics)
        default:
            Text("Đang phát triển...")
                .foregroundColor(.secondary)
        }
    }
    
    private var notificationSettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Cài đặt thông báo")
                .font(.title)
                .bold()
            
            Text("Tính năng đang được phát triển")
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding()
    }
    
    private var privacySettingsView: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Quyền riêng tư")
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
    @FocusState private var isTextFieldFocused: Bool
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Header Section
                    VStack(spacing: 16) {
                        Image(systemName: "building.2.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("Thêm cửa hàng mới")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("Điền thông tin để tạo cửa hàng của bạn")
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
                        
                        // Financial Info Section
                        FormSection(title: "Thông tin tài chính", systemImage: "banknote.fill") {
                            VStack(alignment: .leading, spacing: 12) {
                                Label("Tiền thuê mặt bằng", systemImage: "house.fill")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                
                                HStack(spacing: 12) {
                                    HStack {
                                        Image(systemName: "dollarsign.circle.fill")
                                            .foregroundColor(.blue)
                                        TextField("0", value: $viewModel.groundRent, format: .number)
                                            .keyboardType(.decimalPad)
                                            .textFieldStyle(RoundedBorderTextFieldStyle())
                                    }
                                    .padding(12)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                    
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
                                    .frame(width: 100)
                                    .padding(8)
                                    .background(Color(.systemGray6))
                                    .cornerRadius(12)
                                }
                                
                                if viewModel.groundRent > 0 {
                                    Text("≈ \(formattedGroundRent)/tháng")
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 4)
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
                    
                    // Create Button
                    Button {
                        Task {
                            isTextFieldFocused = false
                            try await viewModel.createNewShop()
                        }
                    } label: {
                        HStack {
                            if appState.sourceModel.isLoading {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title3)
                                Text("Tạo cửa hàng")
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
                    .disabled(!isFormValid || appState.sourceModel.isLoading)
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
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
    
    // MARK: - Computed Properties
    private var isFormValid: Bool {
        !viewModel.shopName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !viewModel.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        viewModel.groundRent >= 0
    }
    
    private var formattedGroundRent: String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        numberFormatter.groupingSeparator = "."
        
        let formattedNumber = numberFormatter.string(from: NSNumber(value: viewModel.groundRent)) ?? "0"
        return "\(formattedNumber)\(viewModel.currency.symbol)"
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

//private struct CustomTextField: View {
//    let title: String
//    let placeholder: String
//    @Binding var text: String
//    let systemImage: String
//    var isMultiline: Bool = false
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Label(title, systemImage: systemImage)
//                .font(.subheadline)
//                .foregroundColor(.secondary)
//            
//            if isMultiline {
//                TextField(placeholder, text: $text, axis: .vertical)
//                    .textFieldStyle(PlainTextFieldStyle())
//                    .lineLimit(2...4)
//                    .padding(12)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(12)
//            } else {
//                TextField(placeholder, text: $text)
//                    .textFieldStyle(PlainTextFieldStyle())
//                    .padding(12)
//                    .background(Color(.systemGray6))
//                    .cornerRadius(12)
//            }
//        }
//    }
//}

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

    var subOptions: [SubOption] {
        switch self {
        case .account:
            return [
                SubOption(id: "profile", title: "Thông tin cá nhân", icon: "person.fill", color: .blue),
                SubOption(id: "security", title: "Bảo mật", icon: "lock.fill", color: .red),
                SubOption(id: "notification", title: "Thông báo", icon: "bell.fill", color: .orange),
                SubOption(id: "privacy", title: "Quyền riêng tư", icon: "hand.raised.fill", color: .purple)
            ]
        case .manageShops:
            return [
                SubOption(id: "shops", title: "Danh sách cửa hàng", icon: "building.2.fill", color: .orange),
                SubOption(id: "menu", title: "Quản lý thực đơn", icon: "list.bullet.rectangle.fill", color: .green),
                SubOption(id: "inventory", title: "Kho hàng", icon: "shippingbox.fill", color: .blue),
                SubOption(id: "staff", title: "Nhân viên", icon: "person.2.fill", color: .purple)
            ]
        default:
            return []
        }
    }
    
    var hasSubOptions: Bool {
        return !subOptions.isEmpty
    }
}

struct SubOption: Identifiable, Hashable {
    let id: String
    let title: String
    let icon: String
    let color: Color
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: SubOption, rhs: SubOption) -> Bool {
        return lhs.id == rhs.id
    }
}

//#Preview {
//    SettingsView(
//        viewModel: SettingsViewModel(environment: AppEnvironment()),
//        coordinator: AppCoordinator()
//    )
//}

