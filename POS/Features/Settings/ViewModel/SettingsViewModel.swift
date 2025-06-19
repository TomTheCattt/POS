import Foundation
import Combine

@MainActor
class SettingsViewModel: ObservableObject {
    
    // MARK: - Published Properties
    @Published private(set) var selectedLanguage: AppLanguage = .vietnamese
    @Published private(set) var selectedThemeStyle: AppThemeStyle = .default
    @Published private(set) var previewThemeColors: AppThemeColors = AppThemeStyle.default.colors
    @Published private(set) var isOwnerAuthenticated: Bool = false
    
    @Published var isAccountExpanded: Bool = false
    @Published var isManageShopExpanded: Bool = false
    @Published var authAttempts: Int = 0
    @Published var ownerPassword = ""
    @Published var showPassword: Bool = false
    
    @Published var selectedCategory: SettingsCategory?
    @Published var selectedOption: SettingsOption?
    
    private var source: SourceModel
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    init(source: SourceModel) {
        self.source = source
        setupBindings()
    }
    
    private func setupBindings() {
        source.isOwnerAuthenticatedPublisher
            .sink { [weak self] isOwnerAuthenticated in
                guard let self = self,
                      let isOwnerAuthenticated = isOwnerAuthenticated else { return }
                self.isOwnerAuthenticated = isOwnerAuthenticated
            }
            .store(in: &cancellables)
        source.environment.settingsService.languagePublisher
            .sink { [weak self] language in
                self?.selectedLanguage = language
            }
            .store(in: &cancellables)
        source.themeStylePublisher
            .sink { [weak self] themeStyle in
                self?.selectedThemeStyle = themeStyle
            }
            .store(in: &cancellables)
        source.themeColorsPublisher
            .sink { [weak self] themeColors in
                self?.previewThemeColors = themeColors
            }
            .store(in: &cancellables)
        source.$authAttempts
            .sink { [weak self] authAttempts in
                guard let self = self else { return }
                self.authAttempts = authAttempts
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Methods
    func updateLanguage(_ language: AppLanguage) {
        source.environment.settingsService.setLanguage(language)
    }
    
    func authenticateOwner() {
        if !source.authenticateAsOwner(password: ownerPassword) {
            ownerPassword = ""
        }
    }
    
    func switchShop(to shop: Shop) async {
        await source.switchShop(to: shop)
    }
    
    var hasThemeChanges: Bool {
        selectedThemeStyle != SettingsService.shared.currentThemeStyle
    }

    func previewThemeStyle(_ style: AppThemeStyle) {
        selectedThemeStyle = style
        previewThemeColors = style.colors
    }

    func applySelectedTheme() {
        source.environment.settingsService.setThemeStyle(selectedThemeStyle)
    }
    
    func resetToDefaultTheme() {
        source.environment.settingsService.setThemeStyle(.default)
    }
    
    // MARK: - Navigation Methods
    func selectCategory(_ category: SettingsCategory) {
        selectedCategory = category
        selectedOption = nil
    }
    
    func selectOption(_ option: SettingsOption) {
        selectedOption = option
    }
    
    func clearSelection() {
        selectedCategory = nil
        selectedOption = nil
    }
}


