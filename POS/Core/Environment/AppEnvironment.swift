import Foundation

final class AppEnvironment: ObservableObject {
    // MARK: - Services
    let authService: AuthService
    let databaseService: DatabaseService
    let networkService: NetworkService
    let storageService: StorageService
    let analyticsService: AnalyticsService
    let crashlyticsService: CrashlyticsService
    let settingsService: SettingsService
    let printerService: PrinterService
    
    // MARK: - Initialization
    init(
        authService: AuthService = .shared,
        databaseService: DatabaseService = .shared,
        networkService: NetworkService = .shared,
        storageService: StorageService = .shared,
        analyticsService: AnalyticsService = .shared,
        crashlyticsService: CrashlyticsService = .shared,
        settingsService: SettingsService = .shared,
        printerService: PrinterService = .shared
    ) {
        self.authService = authService
        self.databaseService = databaseService
        self.networkService = networkService
        self.storageService = storageService
        self.analyticsService = analyticsService
        self.crashlyticsService = crashlyticsService
        self.settingsService = settingsService
        self.printerService = printerService
    }
}
