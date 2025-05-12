//
//  Extensions.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 19/4/25.
//

import Foundation
import SwiftUI

extension UIWindow {
    static var current: UIWindow? {
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                if window.isKeyWindow { return window }
            }
        }
        return nil
    }
}

extension UIScreen {
    static var current: UIScreen? {
        UIWindow.current?.screen
    }
    
    static let screenWidth = UIScreen.current?.bounds.width
    static let screenHeight = UIScreen.current?.bounds.height
}

extension UIDevice {
    var is_iPhone: Bool {
        return UIDevice.current.userInterfaceIdiom == .phone
    }
}

extension View {
    func toast<Content: View>(
        isPresented: Binding<Bool>,
        duration: TimeInterval = 2.0,
        position: ToastPosition = .bottom,
        @ViewBuilder content: @escaping () -> Content
    ) -> some View {
        self.modifier(ToastModifier(isPresented: isPresented, duration: duration, position: position, toastContent: content))
    }
    
    func dismissKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    public func addBorder<S>(_ content: S, width: CGFloat = 1, cornerRadius: CGFloat) -> some View where S : ShapeStyle {
        let roundedRect = RoundedRectangle(cornerRadius: cornerRadius)
        return clipShape(roundedRect)
            .overlay(roundedRect.strokeBorder(content, lineWidth: width))
    }
}
