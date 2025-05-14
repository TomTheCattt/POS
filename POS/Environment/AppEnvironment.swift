//
//  AppEnvironment.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import Foundation

struct AppEnvironment {
    let authService: AuthServiceProtocol
    let firestoreService: FirestoreServiceProtocol
    let crashlyticsService: CrashlyticsServiceProtocol
    let functionService: FunctionsServiceProtocol
    let messagingService: MessagingServiceProtocol
    let storageService: StorageServiceProtocol
    let connectivity: ConnectivityMonitor
    let homeService: HomeServiceProtocol
    let shopService: ShopServiceProtocol
    let orderService: OrderServiceProtocol
    
    static let `default` = AppEnvironment(
        authService: AuthService(),
        firestoreService: FirestoreService(),
        crashlyticsService: CrashlyticsService(),
        functionService: FunctionsService(),
        messagingService: MessagingService(),
        storageService: StorageService(),
        connectivity: ConnectivityMonitor(),
        homeService: HomeService(),
        shopService: ShopService(),
        orderService: OrderService()
    )
}
