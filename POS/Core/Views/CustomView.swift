//
//  CustomView.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 3/6/25.
//

import SwiftUI

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    let minHeight: CGFloat
    
    init(minHeight: CGFloat = 50) {
        self.minHeight = minHeight
    }
    
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .frame(minHeight: minHeight)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
            )
            .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
    }
}
