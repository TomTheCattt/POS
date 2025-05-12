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
    let crashlyticsSerivce: CrashlyticsServiceProtocol
    let functionService: FunctionsServiceProtocol
    let messagingService: MessagingServiceProtocol
    let storageService: StorageServiceProtocol
    let connectivity: ConnectivityMonitor
    let homeService: HomeServiceProtocol
    
    static let `default` = AppEnvironment(
        authService: AuthService(),
        firestoreService: FirestoreService(),
        crashlyticsSerivce: CrashlyticsService(),
        functionService: FunctionsService(),
        messagingService: MessagingService(),
        storageService: StorageService(),
        connectivity: ConnectivityMonitor(),
        homeService: HomeService()
    )
}
