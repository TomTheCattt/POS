import Foundation
import Combine

class SettingsViewModel: BaseViewModel {
    // MARK: - Properties
    var isLoading: Bool = false
    var errorMessage: String?
    var showError: Bool = false
    
    // MARK: - Dependencies
    let environment: AppEnvironment
    var cancellables = Set<AnyCancellable>()
    
    // MARK: - Published Properties
    @Published var selectedLanguage: AppLanguage
    @Published var selectedTheme: AppTheme
    
    // MARK: - Initialization
    required init(environment: AppEnvironment) {
        self.environment = environment
        self.selectedLanguage = environment.settingsService.currentLanguage
        self.selectedTheme = environment.settingsService.currentTheme
        
        // Subscribe to changes
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
