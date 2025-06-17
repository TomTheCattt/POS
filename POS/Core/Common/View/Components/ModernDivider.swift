//
//  ModernDivider.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 14/6/25.
//

import SwiftUI

struct ModernDivider: View {
    let tabThemeColors: TabThemeColor
    let isVertical: Bool
    
    init(tabThemeColors: TabThemeColor, isVertical: Bool = false) {
        self.tabThemeColors = tabThemeColors
        self.isVertical = isVertical
    }
    
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [Color.clear, tabThemeColors.primaryColor.opacity(0.3), Color.clear],
                    startPoint: isVertical ? .top : .leading,
                    endPoint: isVertical ? .bottom : .trailing
                )
            )
            .frame(
                width: isVertical ? 2 : nil,
                height: isVertical ? nil : 2
            )
            .frame(
                maxWidth: isVertical ? nil : .infinity,
                maxHeight: isVertical ? .infinity : nil
            )
    }
}

