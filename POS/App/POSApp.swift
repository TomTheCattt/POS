//
//  POSApp.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI
import FirebaseCore

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .landscape
        } else {
            return .portrait
        }
    }
}

@main
struct POSApp: App {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.isIphone, UIDevice.current.userInterfaceIdiom == .phone)
        }
    }
}

struct IsIphoneKey: EnvironmentKey {
    static let defaultValue: Bool = UIDevice.current.userInterfaceIdiom == .phone
}

extension EnvironmentValues {
    var isIphone: Bool {
        get { self[IsIphoneKey.self] }
        set { self[IsIphoneKey.self] = newValue }
    }
}

struct MenuWidthPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
