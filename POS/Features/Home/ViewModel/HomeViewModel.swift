//
//  HomeViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 1/5/25.
//

import SwiftUI
import Combine

final class HomeViewModel: BaseViewModel {
    @Published var selectedTab: HomeTab = .menu
    @Published var userName: String = "Unknown User"
    
    // MARK: - Initialization
    required init(environment: AppEnvironment) {
        super.init()
        setupBindings()
    }
    
    private func setupBindings() {
//        currentUserPublisher
//            .sink { [weak self] user in
//                self?.userName = user?.displayName ?? "Unknown User"
//            }
//            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func signOut() async {
        try? await environment.authService.logout()
        await MainActor.run {
            self.userId = ""
        }
    }
}
