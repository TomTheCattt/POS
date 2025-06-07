//
//  HomeViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 1/5/25.
//

import SwiftUI
import Combine

final class HomeViewModel: ObservableObject {
    
    private var source: SourceModel
    
    @Published var selectedTab: HomeTab = .menu
    @Published var userName: String = "Unknown User"
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
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
        try? await source.environment.authService.signOut()
    }
}
