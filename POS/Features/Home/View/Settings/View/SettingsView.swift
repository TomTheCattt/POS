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

    @State private var isUpdateShopExpanded: Bool = false
    @State private var selectedOption: SettingsOption?
    @State private var selectedSubOption: UpdateShopSubOption?

    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // MARK: - Sidebar
                sidebarView(width: geometry.size.width * 0.25)
                
                // MARK: - Content Area
                Divider()
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
            
            // Sub-options for Update Shop
            if option == .updateShop, isUpdateShopExpanded {
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
                if option == .updateShop {
                    Image(systemName: isUpdateShopExpanded ? "chevron.down" : "chevron.right")
                        .animation(.easeInOut(duration: 0.2), value: isUpdateShopExpanded)
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
    private func subOptionButton(for subOption: UpdateShopSubOption) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedSubOption = subOption
                selectedOption = .updateShop
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
        case .setUpPrinter:
            appState.coordinator.makeView(for: .setUpPrinter)
        case .language:
            appState.coordinator.makeView(for: .language)
        case .theme:
            appState.coordinator.makeView(for: .theme)
        case .updateShop:
            if let subOption = selectedSubOption {
                contentForSubOption(subOption)
            } else {
                placeholderView("Chọn một tùy chọn cập nhật")
            }
        }
    }
    
    // MARK: - Content For Sub Option
    @ViewBuilder
    private func contentForSubOption(_ subOption: UpdateShopSubOption) -> some View {
        switch subOption {
        case .updateInventory:
            appState.coordinator.makeView(for: .updateInventory)
        case .updateMenu:
            appState.coordinator.makeView(for: .updateMenu)
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
        if option == .updateShop {
            withAnimation(.easeInOut(duration: 0.25)) {
                isUpdateShopExpanded.toggle()
                if !isUpdateShopExpanded {
                    selectedSubOption = nil
                }
            }
        } else {
            withAnimation(.easeInOut(duration: 0.25)) {
                selectedOption = option
                selectedSubOption = nil
                isUpdateShopExpanded = false
            }
        }
    }
}

enum SettingsOption: CaseIterable {
    case updateShop, setUpPrinter, language, theme
    
    var title: String {
        switch self {
        case .updateShop: return "Update Shop"
        case .setUpPrinter: return "Set Up Printer"
        case .language: return "Language"
        case .theme: return "Theme"
        }
    }

    /// Các tùy chọn con (chỉ áp dụng cho updateShop)
    var subOptions: [UpdateShopSubOption]? {
        switch self {
        case .updateShop:
            return UpdateShopSubOption.allCases
        default:
            return nil
        }
    }
}

enum UpdateShopSubOption: String, CaseIterable, Identifiable {
    case updateInventory
    case updateMenu

    var id: String { rawValue }

    var title: String {
        switch self {
        case .updateInventory: return "Update Inventory"
        case .updateMenu: return "Update Menu"
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
