//
//  HomeView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import SwiftUI

struct HomeView: View {
    
    @State private var isMenuVisible: Bool = false
    @State private var selectedTab: HomeTab = HomeTab.allCases.first!
    @ObservedObject var viewModel: HomeViewModel
    @ObservedObject var coordinator: AppCoordinator
    @State private var measuredMenuWidth: CGFloat = 0
    
    @Environment(\.isIphone) private var isIphone
    
    var body: some View {
        GeometryReader { geometry in
            let sideMenuWidth = UIDevice.current.is_iPhone ? geometry.size.width * 0.8 : geometry.size.width * 0.08
            if isIphone {
                ZStack(alignment: .leading) {
                    VStack {
                        Button {
                            withAnimation {
                                isMenuVisible.toggle()
                            }
                        } label: {
                            Image(systemName: "line.horizontal.3")
                                .padding()
                        }
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
                    
                    SideMenuView(selectedTab: $selectedTab, sideMenuWidth: sideMenuWidth)
                        .frame(width: sideMenuWidth)
                        .frame(maxHeight: .infinity)
                        .background(Color(.systemGray6))
                        .offset(x: isMenuVisible ? 0 : -sideMenuWidth)
                        .animation(.easeInOut(duration: 0.25), value: isMenuVisible)
                }
            } else {
                HStack(spacing: 0) {
                    SideMenuView(selectedTab: $selectedTab, sideMenuWidth: sideMenuWidth)
                        .frame(minWidth: sideMenuWidth * 0.8, idealWidth: sideMenuWidth, maxWidth: sideMenuWidth * 1.2)
                        .background(Color(.systemGray6))
                    
                    Divider()
                    switch selectedTab {
                    case .menu:
                        ViewFactory(coordinator: coordinator)
                            .viewForDestination(.homeTab(.menu))
                    case .history:
                        ViewFactory(coordinator: coordinator)
                            .viewForDestination(.homeTab(.history))
                    case .inventory:
                        ViewFactory(coordinator: coordinator)
                            .viewForDestination(.homeTab(.inventory))
                    case .analytics:
                        ViewFactory(coordinator: coordinator)
                            .viewForDestination(.homeTab(.analytics))
                    case .settings:
                        ViewFactory(coordinator: coordinator)
                            .viewForDestination(.homeTab(.settings))
                    }
                }
            }
        }
    }
}

struct SideMenuView: View {
    
    @Binding var selectedTab: HomeTab
    @State var sideMenuWidth: CGFloat
    
    @Environment(\.isIphone) private var isIphone
    
    var body: some View {
        VStack(spacing: 15) {
            ForEach(HomeTab.allCases) { tab in
                let isSelected = selectedTab == tab
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 6) {
                        Image(systemName: tab.icon.name)
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
        }
        .padding(.horizontal)
        .frame(maxWidth: isIphone ? sideMenuWidth : .infinity, alignment: .leading)
        .background(Color(.systemGray6))
    }
}


#Preview {
    HomeView(viewModel: HomeViewModel(authManager: AuthManager()), coordinator: AppCoordinator())
}
