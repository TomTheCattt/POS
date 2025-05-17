import Foundation
import Combine

class SettingsService: SettingsServiceProtocol {
    
    static let shared = SettingsService()
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let languageKey = "app_language"
    private let themeKey = "app_theme"
    
    @Published private(set) var currentLanguage: AppLanguage = .vietnamese
    @Published private(set) var currentTheme: AppTheme = .system
    
    var languagePublisher: AnyPublisher<AppLanguage, Never> {
        $currentLanguage.eraseToAnyPublisher()
    }
    
    var themePublisher: AnyPublisher<AppTheme, Never> {
        $currentTheme.eraseToAnyPublisher()
    }
    
    // MARK: - Initialization
    init() {
        loadSettings()
    }
    
    // MARK: - Language Methods
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
        saveSettings()
    }
    
    // MARK: - Theme Methods
    func setTheme(_ theme: AppTheme) {
        currentTheme = theme
        saveSettings()
    }
    
    // MARK: - Load & Save
    func loadSettings() {
        if let languageRawValue = userDefaults.string(forKey: languageKey),
           let language = AppLanguage(rawValue: languageRawValue) {
            currentLanguage = language
        }
        
        if let themeRawValue = userDefaults.string(forKey: themeKey),
           let theme = AppTheme(rawValue: themeRawValue) {
            currentTheme = theme
        }
    }
    
    func saveSettings() {
        userDefaults.set(currentLanguage.rawValue, forKey: languageKey)
        userDefaults.set(currentTheme.rawValue, forKey: themeKey)
    }
} 
