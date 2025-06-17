import Foundation

final class AppEnvironment: ObservableObject {
    // MARK: - Services
    let hapticsService: HapticsService
    let authService: AuthService
    let databaseService: DatabaseService
    let networkService: NetworkService
    let storageService: StorageService
    let revenueRecordService: AnalyticsService
    let crashlyticsService: CrashlyticsService
    let settingsService: SettingsService
    let printerService: PrinterService
    
    // MARK: - Initialization
    init(
        hapticsService: HapticsService = .shared,
        authService: AuthService = .shared,
        databaseService: DatabaseService = .shared,
        networkService: NetworkService = .shared,
        storageService: StorageService = .shared,
        revenueRecordService: AnalyticsService = .shared,
        crashlyticsService: CrashlyticsService = .shared,
        settingsService: SettingsService = .shared,
        printerService: PrinterService = .shared
    ) {
        self.hapticsService = hapticsService
        self.authService = authService
        self.databaseService = databaseService
        self.networkService = networkService
        self.storageService = storageService
        self.revenueRecordService = revenueRecordService
        self.crashlyticsService = crashlyticsService
        self.settingsService = settingsService
        self.printerService = printerService
    }
}
