//
//  View+Modifier.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation
import SwiftUI

enum ToastPosition {
    case top
    case center
    case bottom
}

struct ToastModifier<ToastContent: View>: ViewModifier {
    
    @Binding var isPresented: Bool
    let duration: TimeInterval
    let position: ToastPosition
    let toastContent: () -> ToastContent

    func body(content: Content) -> some View {
        ZStack {
            content
            if isPresented {
                toastView()
                    .transition(.opacity)
                    .zIndex(1)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
                            withAnimation {
                                isPresented = false
                            }
                        }
                    }
            }
        }
    }

    @ViewBuilder
    private func toastView() -> some View {
        GeometryReader { geometry in
            VStack {
                if position == .top {
                    toastContent()
                        .frame(maxWidth: geometry.size.width * 0.9)
                        .padding(.top, 60)
                    Spacer()
                } else if position == .center {
                    Spacer()
                    toastContent()
                        .frame(maxWidth: geometry.size.width * 0.9)
                    Spacer()
                } else if position == .bottom {
                    Spacer()
                    toastContent()
                        .frame(maxWidth: geometry.size.width * 0.9)
                        .padding(.bottom, 60)
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
            .edgesIgnoringSafeArea(.all)
        }
    }
}

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
