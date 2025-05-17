//
//  POSApp.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI
import FirebaseCore
import Combine

class AppDelegate: NSObject, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        let environment = AppEnvironment()
        
        // Áp dụng theme
        switch environment.settingsService.currentTheme {
        case .light:
            window?.overrideUserInterfaceStyle = .light
        case .dark:
            window?.overrideUserInterfaceStyle = .dark
        case .system:
            window?.overrideUserInterfaceStyle = .unspecified
        }
        
        // Áp dụng ngôn ngữ
        if let languageCode = environment.settingsService.currentLanguage.rawValue as String? {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
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
    // MARK: - Properties
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    // MARK: - Body
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
