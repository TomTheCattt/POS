//
//  ThemeView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

enum AppTheme: String, CaseIterable {
    case system
    case light
    case dark
    
    var displayName: String {
        switch self {
        case .system: return "Theo hệ thống"
        case .light: return "Sáng"
        case .dark: return "Tối"
        }
    }
    
    var iconName: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        }
    }
}

struct ThemeView: View {
    @ObservedObject var viewModel: SettingsViewModel
    @EnvironmentObject var appState: AppState
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Chọn giao diện")
                .font(.largeTitle.bold())
                .padding(.top)
            
            ForEach(AppTheme.allCases, id: \.self) { theme in
                RadioButtonRow(label: theme.displayName, useText: false, isSelected: viewModel.selectedTheme == theme, icon: theme.iconName) {
                    viewModel.selectedTheme = theme
                    viewModel.updateTheme(theme)
                }
            }
            
            Spacer()
        }
        .padding()
    }
}

struct RadioButtonRow: View {
    let label: String
    var useText: Bool = false
    let isSelected: Bool
    var icon: String = ""
    var textIcon: String = ""
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                if useText {
                    Text(textIcon)
                        .font(.title3)
                } else {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(isSelected ? Color.accentColor : .primary)
                }
                
                Text(label)
                    .font(.title3)
                
                Spacer()
                
                ZStack {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2)
                        .frame(width: 24, height: 24)
                    
                    if isSelected {
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor.opacity(0.1) : Color(.systemBackground))
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
//
//#Preview {
//    ThemeView(
//        viewModel: SettingsViewModel(environment: AppEnvironment()),
//        coordinator: AppCoordinator()
//    )
//}
