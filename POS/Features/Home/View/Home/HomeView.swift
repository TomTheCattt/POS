//
//  HomeView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import SwiftUI

enum HomeTab: String, CaseIterable, Identifiable {
    case menu, history, inventory, analytics, settings
    
    var id: String { self.rawValue }

    var icon: String {
        switch self {
        case .menu:
            return "list.bullet.rectangle"
        case .history:
            return "clock.arrow.circlepath"
        case .inventory:
            return "shippingbox"
        case .analytics:
            return "chart.bar"
        case .settings:
            return "gearshape"
        }
    }

    var title: String {
        switch self {
        case .menu:
            return "Menu"
        case .history:
            return "History"
        case .inventory:
            return "Inventory"
        case .analytics:
            return "Analytics"
        case .settings:
            return "Settings"
        }
    }
}


struct HomeView: View {
    
    @State private var isMenuVisible: Bool = false
    @State private var selectedTab: HomeTab = HomeTab.allCases.first!
    @State private var measuredMenuWidth: CGFloat = 0
    @ObservedObject var viewModel: HomeViewModel
    @EnvironmentObject var appState: AppState
    
    private let isIphone = UIDevice.current.userInterfaceIdiom == .phone
//    private let viewModelFactory = ViewModelFactory.shared
    
    var body: some View {
        GeometryReader { geometry in
            let sideMenuWidth = isIphone ? geometry.size.width * 0.8 : geometry.size.width * 0.1
            if isIphone {
                ZStack(alignment: .leading) {
                    contentView(for: selectedTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    
                    VStack {
                        Button {
                            withAnimation {
                                isMenuVisible.toggle()
                            }
                        } label: {
                            Image(systemName: "line.horizontal.3")
                                .padding()
                        }
                        .padding(.top)
                        Spacer()
                    }
                    
                    if isMenuVisible {
                        Color.black.opacity(0.3)
                            .onTapGesture {
                                withAnimation {
                                    isMenuVisible = false
                                }
                            }
                            .ignoresSafeArea()
                    }
                    
                    SideMenuView(selectedTab: $selectedTab, sideMenuWidth: sideMenuWidth, viewModel: viewModel)
                        .frame(width: sideMenuWidth)
                        .frame(maxHeight: .infinity)
                        .background(Color(.systemGray6))
                        .offset(x: isMenuVisible ? 0 : -sideMenuWidth)
                        .animation(.easeInOut(duration: 0.25), value: isMenuVisible)
                }
            } else {
                HStack(spacing: 0) {
                    SideMenuView(selectedTab: $selectedTab, sideMenuWidth: sideMenuWidth, viewModel: viewModel)
                        .frame(width: sideMenuWidth)
                        .background(Color(.systemGray6))
                    
                    Divider()
                    
                    contentView(for: selectedTab)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
        }
    }
    
    @ViewBuilder
    private func contentView(for tab: HomeTab) -> some View {
        Group {
            switch tab {
            case .menu:
                appState.coordinator.makeView(for: .order)
            case .history:
                appState.coordinator.makeView(for: .ordersHistory)
            case .inventory:
                appState.coordinator.makeView(for: .inventory)
            case .analytics:
                appState.coordinator.makeView(for: .analytics)
            case .settings:
                appState.coordinator.makeView(for: .settings)
            }
        }
    }
}

struct SideMenuView: View {
    
    @Binding var selectedTab: HomeTab
    @State var sideMenuWidth: CGFloat
    @ObservedObject var viewModel: HomeViewModel
    
    private let isIphone = UIDevice.current.userInterfaceIdiom == .phone
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(HomeTab.allCases, id: \.self) { tab in
                let isSelected = selectedTab == tab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon)
                            .resizable()
                            .scaledToFit()
                            .frame(width: isIphone ? 24 : 32, height: isIphone ? 24 : 32)
                        
                        Text(tab.title)
                            .font(.system(size: isIphone ? 14 : 18, weight: .medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .minimumScaleFactor(0.8)
                    }
                    .padding(.vertical, isIphone ? 8 : 12)
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, isIphone ? 8 : 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue : Color.clear)
                    )
                }
                .foregroundColor(isSelected ? .white : .primary)
                .animation(.easeInOut, value: isSelected)
            }
            
            Spacer()
            
            Button {
                Task {
                    do {
                        await viewModel.signOut()
                    }
                }
            } label: {
                VStack(spacing: 6) {
                    Image(systemName: "door.left.hand.open")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isIphone ? 24 : 32, height: isIphone ? 24 : 32)
                    
                    Text("Log Out")
                        .font(.system(size: isIphone ? 14 : 18, weight: .medium))
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .minimumScaleFactor(0.8)
                }
            }
            .foregroundStyle(Color.red)
        }
        .padding(.horizontal)
        .padding(.vertical, 20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
    }
}

// Uncomment for preview
//#Preview {
//    HomeView(viewModel: HomeViewModel(), coordinator: AppCoordinator())
//}
