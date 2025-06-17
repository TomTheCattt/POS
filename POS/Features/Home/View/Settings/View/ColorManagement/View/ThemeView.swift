//
//  ThemeView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 17/5/25.
//

import SwiftUI

struct ThemeView: View {
    @ObservedObject private var viewModel: SettingsViewModel
    @EnvironmentObject private var appState: AppState
    @Environment(\.colorScheme) private var colorScheme
    
    init(viewModel: SettingsViewModel) {
        self.viewModel = viewModel
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            if !isIphone {
                Text("Giao diện")
                    .font(.title)
                    .bold()
                    .padding(.horizontal)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    ForEach(AppThemeStyle.allCases, id: \.self) { style in
                        ThemePreviewCard(
                            style: style,
                            isSelected: viewModel.selectedThemeStyle == style,
                            onSelect: {
                                withAnimation(.easeInOut(duration: 0.3)) {
                                    viewModel.previewThemeStyle(style)
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            VStack(spacing: 16) {
                Button {
                    viewModel.applySelectedTheme() 
                } label: {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Áp dụng thay đổi")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(
                        appState.currentTabThemeColors.gradient(for: colorScheme)
                    )
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.hasThemeChanges)
                .opacity(viewModel.hasThemeChanges ? 1 : 0.6)
                
                Button {
                    viewModel.resetToDefaultTheme()
                } label: {
                    Text("Khôi phục giao diện mặc định")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                }
            }
            .padding()
        }
        .background(appState.currentTabThemeColors.softGradient(for: colorScheme))
    }
}
