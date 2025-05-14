//
//  HomeViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 1/5/25.
//

import SwiftUI

class HomeViewModel: ObservableObject {
    
    private let homeService: HomeServiceProtocol
    @ObservedObject private var authManager: AuthManager
    
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
