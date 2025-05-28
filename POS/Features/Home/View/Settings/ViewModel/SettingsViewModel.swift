import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published var selectedLanguage: AppLanguage
    @Published var selectedTheme: AppTheme
    
    private var source: SourceModel
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        self.selectedLanguage = source.environment.settingsService.currentLanguage
        self.selectedTheme = source.environment.settingsService.currentTheme
        
        setupBindings()
    }
    
    private func setupBindings() {
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
