//
//  HomeViewModel.swift
//  POS
//
//  Created by Việt Anh Nguyễn on 1/5/25.
//

import SwiftUI
import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    
    private var source: SourceModel
    
    @Published private(set) var selectedTab: HomeTab = .order
    @Published var userName: String = "Unknown User"
    @Published private(set) var isMenuVisible: Bool = false
    @Published private(set) var dragOffset: CGFloat = 0
    @Published private(set) var isDragging: Bool = false
    
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
    
    func selectTab(_ tab: HomeTab) {
        selectedTab = tab
        source.environment.hapticsService.impact(.light)
    }
    
    func isMenuVisible(_ isMenuVisible: Bool) {
        self.isMenuVisible = isMenuVisible
        source.environment.hapticsService.impact(isMenuVisible ? .medium : .light)
    }
    
    func isDragging(_ isDragging: Bool) {
        self.isDragging = isDragging
        source.environment.hapticsService.impact(.light)
    }
    
    func setOffSet(_ offSet: CGFloat) {
        self.dragOffset = offSet
    }
    
    func resetState() {
        isDragging = false
        dragOffset = 0
        isMenuVisible = false
    }
    
    // MARK: - Public Methods
    func signOut() async {
        await source.signOut()
    }
}
