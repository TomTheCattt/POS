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
                    Task {
                        try? await Task.sleep(nanoseconds: 600_000_000)
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


// Press Events Modifier
extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventModifier(onPress: onPress, onRelease: onRelease))
    }
}

struct PressEventModifier: ViewModifier {
    let onPress: () -> Void
    let onRelease: () -> Void
    
    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}
