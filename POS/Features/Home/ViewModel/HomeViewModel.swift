//
//  HomeViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 1/5/25.
//

import SwiftUI
import Combine

final class HomeViewModel: BaseViewModel {
    var isLoading: Bool = false
    
    var errorMessage: String?
    
    var showError: Bool = false
    
    // MARK: - Dependencies
    let environment: AppEnvironment
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var selectedTab: HomeTab = .menu
    @Published var userName: String = "Unknown User"
    
    // MARK: - Initialization
    required init(environment: AppEnvironment) {
        self.environment = environment
        setupBindings()
    }
    
    private func setupBindings() {
        authService.currentUserPublisher
            .sink { [weak self] user in
                self?.userName = user?.displayName ?? "Unknown User"
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    func signOut() async {
        try? await authService.logout()
    }
}
