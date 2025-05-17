//
//  View+Modifier.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import SwiftUI

struct ShakeEffect: ViewModifier {
    @Binding var shake: Bool
    @State private var animationAmount: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .offset(x: shake ? animationAmount : 0)
            .onChange(of: shake) { newValue in
                if newValue {
                    withAnimation(
                        Animation
                            .easeInOut(duration: 0.1)
                            .repeatCount(5, autoreverses: true)
                    ) {
                        animationAmount = -10
                    }
                    
                    // Use a delayed action to reset the state
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        animationAmount = 0
                        if self.shake {
                            self.shake = false
                        }
                    }
                } else {
                    withAnimation(.easeOut(duration: 0.1)) {
                        animationAmount = 0
                    }
                }
            }
    }
}
