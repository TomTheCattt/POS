import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedLanguage: AppLanguage
    @Published var selectedTheme: AppTheme
    @Published var isOwnerAuthenticated: Bool = false
    
    private var source: SourceModel
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        self.selectedLanguage = source.environment.settingsService.currentLanguage
        self.selectedTheme = source.environment.settingsService.currentTheme
        
        setupBindings()
    }
    
    private func setupBindings() {
        source.isOwnerAuthenticatedPublisher
            .sink { [weak self] isOwnerAuthenticated in
                guard let self = self,
                      let isOwnerAuthenticated = isOwnerAuthenticated else { return }
                self.isOwnerAuthenticated = isOwnerAuthenticated
            }
            .store(in: &source.cancellables)
        source.environment.settingsService.languagePublisher
            .sink { [weak self] language in
                self?.selectedLanguage = language
            }
            .store(in: &source.cancellables)
        
        source.environment.settingsService.themePublisher
            .sink { [weak self] theme in
                self?.selectedTheme = theme
            }
            .store(in: &source.cancellables)
    }
    
    // MARK: - Methods
    func updateLanguage(_ language: AppLanguage) {
        source.environment.settingsService.setLanguage(language)
    }
    
    func updateTheme(_ theme: AppTheme) {
        source.environment.settingsService.setTheme(theme)
    }
} 
