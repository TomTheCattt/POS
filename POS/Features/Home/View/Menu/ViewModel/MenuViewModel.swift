//
//  MenuViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 16/4/25.
//

import SwiftUI
import Combine

final class MenuViewModel: ObservableObject {

    private let shopService: ShopServiceProtocol
    private let orderService: OrderServiceProtocol
    private let crashlyticsService: CrashlyticsServiceProtocol
    @ObservedObject private var authManager: AuthManager

    @Published var displayName: String = "Unknown User"

    private var cancellables = Set<AnyCancellable>()

    init(environment: AppEnvironment = .default, authManager: AuthManager = AuthManager()) {
        self.shopService = environment.shopService
        self.orderService = environment.orderService
        self.crashlyticsService = environment.crashlyticsService
        self.authManager = authManager

        authManager.$currentUser
            .receive(on: RunLoop.main)
            .sink { [weak self] user in
                self?.displayName = user?.displayName ?? "Unknown User"
            }
            .store(in: &cancellables)
    }

    func getDisplayName() -> String {
        return displayName
    }
}

