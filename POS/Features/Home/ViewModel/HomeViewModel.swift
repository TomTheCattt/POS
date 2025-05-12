//
//  HomeViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 1/5/25.
//

import Foundation

class HomeViewModel: ObservableObject {
    
    private let homeService: HomeServiceProtocol
    private let authManager: AuthManager
    
    init(environment: AppEnvironment = .default,
         authManager: AuthManager) {
        self.homeService = environment.homeService
        self.authManager = authManager
    }
    
    func logout() {
        homeService.logout()
        authManager.logout()
    }
}
