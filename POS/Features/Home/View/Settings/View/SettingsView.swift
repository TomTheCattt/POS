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
            HStack {
                // MARK: - Sidebar
                sidebarView(width: geometry.size.width * 0.25)
                
                // MARK: - Content Area
                contentAreaView()
            }
        }
    }
    
    // MARK: - Sidebar View
    private func sidebarView(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(SettingsOption.allCases, id: \.self) { option in
                optionView(for: option)
                Divider()
            }
            Spacer()
        }
        .frame(width: width)
        .background(Color(.systemGroupedBackground))
    }
    
    // MARK: - Option View
    private func optionView(for option: SettingsOption) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            optionButton(for: option)
            
            // Sub-options for Account
            if option == .account, isAccountExpanded {
                subOptionsView(for: option)
            }
        }
    }
    
    // MARK: - Option Button
    private func optionButton(for option: SettingsOption) -> some View {
        Button {
            handleOptionTap(option)
        } label: {
            HStack {
                Text(option.title)
                    .font(.headline)
                Spacer()
                if option == .account {
                    Image(systemName: isAccountExpanded ? "chevron.down" : "chevron.right")
                        .animation(.easeInOut(duration: 0.2), value: isAccountExpanded)
                } else {
                    Image(systemName: "chevron.right")
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(selectedOption == option ? Color.blue.opacity(0.1) : Color.clear)
            )
        }
        .foregroundColor(selectedOption == option ? .blue : .primary)
    }
    
    // MARK: - Sub Options View
    private func subOptionsView(for option: SettingsOption) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(option.subOptions ?? []) { subOption in
                Divider()
                subOptionButton(for: subOption)
            }
        }
    }
    
    // MARK: - Sub Option Button
    private func subOptionButton(for subOption: AccountSubOption) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedSubOption = subOption
                selectedOption = .account
            }
        } label: {
            HStack {
                Text(subOption.title)
                    .padding(.leading, 20)
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
    
    // MARK: - Content Area View
    private func contentAreaView() -> some View {
        ZStack {
            if let selectedOption = selectedOption {
                contentForOption(selectedOption)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing).combined(with: .opacity),
                        removal: .move(edge: .trailing).combined(with: .opacity)
                    ))
            } else {
                placeholderView("Chọn một tùy chọn từ menu")
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemBackground))
    }
    
    // MARK: - Content For Option
    @ViewBuilder
    private func contentForOption(_ option: SettingsOption) -> some View {
        switch option {
        case .account:
            if let subOption = selectedSubOption {
                contentForSubOption(subOption)
            } else {
                placeholderView("Chọn một tùy chọn tài khoản")
            }
        case .manageShops:
            appState.coordinator.makeView(for: .manageShops)
        case .setUpPrinter:
            appState.coordinator.makeView(for: .setUpPrinter)
        case .language:
            appState.coordinator.makeView(for: .language)
        case .theme:
            appState.coordinator.makeView(for: .theme)
        }
    }
    
    // MARK: - Content For Sub Option
    @ViewBuilder
    private func contentForSubOption(_ subOption: AccountSubOption) -> some View {
        switch subOption {
        case .accountDetail:
            appState.coordinator.makeView(for: .accountDetail)
        case .password:
            appState.coordinator.makeView(for: .password)
        }
    }
    
    // MARK: - Placeholder View
    private func placeholderView(_ message: String) -> some View {
        VStack {
            Image(systemName: "gearshape")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            Text(message)
                .font(.title2)
                .foregroundColor(.gray)
                .padding(.top)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Handle Option Tap
    private func handleOptionTap(_ option: SettingsOption) {
        if option == .account {
            withAnimation(.easeInOut(duration: 0.25)) {
                isAccountExpanded.toggle()
                if !isAccountExpanded {
                    selectedSubOption = nil
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedOption = option
                selectedSubOption = nil
                isAccountExpanded = false
            }
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
//
//#Preview {
//    SettingsView(
//        viewModel: SettingsViewModel(environment: AppEnvironment()),
//        coordinator: AppCoordinator()
//    )
//}
