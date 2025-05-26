import Foundation
import Combine

class SettingsViewModel: BaseViewModel {
    
    // MARK: - Published Properties
    @Published var selectedLanguage: AppLanguage
    @Published var selectedTheme: AppTheme
    
    // MARK: - Initialization
    required init(environment: AppEnvironment) {
        self.selectedLanguage = environment.settingsService.currentLanguage
        self.selectedTheme = environment.settingsService.currentTheme
        super.init()
        setupBindings()
    }
    
    private func setupBindings() {
        environment.settingsService.languagePublisher
            .sink { [weak self] language in
                self?.selectedLanguage = language
            }
            .store(in: &cancellables)
        
        environment.settingsService.themePublisher
            .sink { [weak self] theme in
                self?.selectedTheme = theme
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    func updateLanguage(_ language: AppLanguage) {
        environment.settingsService.setLanguage(language)
    }
    
    func updateTheme(_ theme: AppTheme) {
        environment.settingsService.setTheme(theme)
    }
} 
