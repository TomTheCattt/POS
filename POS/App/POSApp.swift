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
    var appState: AppState?
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        let environment = AppEnvironment()
        appState = AppState()
        
        // Áp dụng ngôn ngữ
        if let languageCode = environment.settingsService.currentLanguage.rawValue as String? {
            UserDefaults.standard.set([languageCode], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
        }
        
        // Đăng ký background fetch
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplication.backgroundFetchIntervalMinimum)
        
        return true
    }
    
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .pad {
            return .landscape
        } else {
            return .portrait
        }
    }
    
    // Xử lý background fetch
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let appState = appState {
            Task {
                if let sessionInfo = appState.sourceModel.restoreSessionState() {
                    await appState.sourceModel.restoreWorkSession(sessionInfo)
                    completionHandler(.newData)
                } else {
                    completionHandler(.noData)
                }
            }
        } else {
            completionHandler(.failed)
        }
    }
}

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var appState: AppState?
    
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        let window = UIWindow(windowScene: windowScene)
        self.window = window
        
        // Lấy sourceModel từ AppDelegate
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate {
            self.appState = appDelegate.appState
        }
        
        window.makeKeyAndVisible()
    }
    
    func sceneDidDisconnect(_ scene: UIScene) {
        // Lưu trạng thái khi scene bị disconnect
        if let appState = appState {
            appState.sourceModel.saveSessionState(
                route: .home, // Thay bằng route hiện tại của bạn
                shopId: appState.sourceModel.activatedShop?.id,
                menuId: appState.sourceModel.activatedMenu?.id,
                orderId: appState.sourceModel.orders?.first?.id
            )
        }
    }
    
    func sceneDidBecomeActive(_ scene: UIScene) {
        // Xử lý khi scene trở thành active
        if let appState = appState {
            Task {
                if let sessionInfo = appState.sourceModel.restoreSessionState() {
                    await appState.sourceModel.restoreWorkSession(sessionInfo)
                }
            }
        }
    }
    
    func sceneWillResignActive(_ scene: UIScene) {
        // Lưu trạng thái khi scene sắp resign active
        if let appState = appState {
            appState.sourceModel.saveSessionState(
                route: .order, // Thay bằng route hiện tại của bạn
                shopId: appState.sourceModel.activatedShop?.id,
                menuId: appState.sourceModel.activatedMenu?.id,
                orderId: appState.sourceModel.orders?.first?.id
            )
        }
    }
    
    func sceneDidEnterBackground(_ scene: UIScene) {
        // Lưu trạng thái khi scene vào background
        if let appState = appState {
            appState.sourceModel.saveSessionState(
                route: .order, // Thay bằng route hiện tại của bạn
                shopId: appState.sourceModel.activatedShop?.id,
                menuId: appState.sourceModel.activatedMenu?.id,
                orderId: appState.sourceModel.orders?.first?.id
            )
        }
    }
    
    func sceneWillEnterForeground(_ scene: UIScene) {
        // Khôi phục trạng thái khi scene sắp vào foreground
        if let appState = appState {
            Task {
                if let sessionInfo = appState.sourceModel.restoreSessionState() {
                    await appState.sourceModel.restoreWorkSession(sessionInfo)
                }
            }
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
                .environmentObject(delegate.appState ?? AppState())
        }
    }
}

let isIphone = UIDevice.current.is_iPhone
