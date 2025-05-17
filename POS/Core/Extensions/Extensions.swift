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
