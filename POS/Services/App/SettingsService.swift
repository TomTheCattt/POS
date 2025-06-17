import Foundation
import Combine
import SwiftUI

// MARK: - Theme Models
struct TabThemeColor: Codable {
    private var primaryColorHex: String
    private var secondaryColorHex: String
    private var accentColorHex: String
    
    var primaryColor: Color {
        Color(hex: primaryColorHex)
    }
    
    var secondaryColor: Color {
        Color(hex: secondaryColorHex)
    }
    
    var accentColor: Color {
        Color(hex: accentColorHex)
    }
    
    init(primaryColor: String, secondaryColor: String, accentColor: String) {
        self.primaryColorHex = primaryColor
        self.secondaryColorHex = secondaryColor
        self.accentColorHex = accentColor
    }
    
    // MARK: - Adaptive Methods với ColorScheme
    
    // Gradient chính - tự động điều chỉnh theo colorScheme
    func gradient(for colorScheme: ColorScheme) -> LinearGradient {
        let opacity: Double = colorScheme == .dark ? 0.9 : 1.0
        return LinearGradient(
            colors: [
                primaryColor.opacity(opacity),
                secondaryColor.opacity(opacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Gradient nhẹ nhàng với opacity adaptive
    func softGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let baseOpacity: Double = colorScheme == .dark ? 0.3 : 0.2
        return LinearGradient(
            colors: [
                primaryColor.opacity(baseOpacity),
                secondaryColor.opacity(baseOpacity - 0.05),
                accentColor.opacity(baseOpacity - 0.1)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Gradient động với hiệu ứng tối ưu cho từng chế độ
    func animatedGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let intensity: Double = colorScheme == .dark ? 0.8 : 1.0
        let fadeOpacity: Double = colorScheme == .dark ? 0.6 : 0.8
        
        return LinearGradient(
            colors: [
                primaryColor.opacity(intensity),
                secondaryColor.opacity(intensity),
                accentColor.opacity(intensity),
                primaryColor.opacity(fadeOpacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // Gradient ngược cho hiệu ứng đặc biệt
    func reverseGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let opacity: Double = colorScheme == .dark ? 0.85 : 1.0
        return LinearGradient(
            colors: [
                secondaryColor.opacity(opacity),
                primaryColor.opacity(opacity)
            ],
            startPoint: .bottomTrailing,
            endPoint: .topLeading
        )
    }
    
    // Gradient tròn với adaptive opacity
    func radialGradient(for colorScheme: ColorScheme) -> RadialGradient {
        let centerOpacity: Double = colorScheme == .dark ? 0.9 : 1.0
        let edgeOpacity: Double = colorScheme == .dark ? 0.5 : 0.6
        
        return RadialGradient(
            colors: [
                primaryColor.opacity(centerOpacity),
                secondaryColor.opacity(centerOpacity),
                accentColor.opacity(edgeOpacity)
            ],
            center: .center,
            startRadius: 0,
            endRadius: 100
        )
    }
    
    // Background color adaptive
    func backgroundColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? primaryColor.opacity(0.1)
            : primaryColor.opacity(0.05)
    }
    
    // Text color với contrast tốt
    func textColor(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark
            ? primaryColor.opacity(0.9)
            : primaryColor.opacity(0.8)
    }
    
    func textGradient(for colorScheme: ColorScheme) -> LinearGradient {
        let intensity: Double = colorScheme == .dark ? 0.8 : 1.0
        let fadeOpacity: Double = colorScheme == .dark ? 0.6 : 0.8
        let systemColor: Color = colorScheme == .dark ? .white : .black.opacity(0.6)
        
        return LinearGradient(
            colors: [
                primaryColor.opacity(intensity),
                systemColor.opacity(fadeOpacity)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
    
    // MARK: - Codable
    private enum CodingKeys: String, CodingKey {
        case primaryColorHex = "primaryColor"
        case secondaryColorHex = "secondaryColor"
        case accentColorHex = "accentColor"
    }
}

struct AppThemeColors: Codable {
    var global: TabThemeColor
    var order: TabThemeColor
    var history: TabThemeColor
    var expense: TabThemeColor
    var revenue: TabThemeColor
    var settings: TabThemeColor
}

enum AppThemeStyle: String, CaseIterable, Codable { 
    case `default` = "Default"
    case lightPastel = "Light & Pastel"
    case darkBold = "Dark & Bold"
    case nature = "Nature"
    
    var displayName: String { rawValue }
    
    var colors: AppThemeColors {
        switch self {
        case .default:
            return AppThemeColors(
                global: TabThemeColor(
                    primaryColor: "007AFF",
                    secondaryColor: "D1D1D6",
                    accentColor: "F2F2F7"
                ),
                order: TabThemeColor(
                    primaryColor: "D295BF",
                    secondaryColor: "E8C4DD",
                    accentColor: "FAF0F7"
                ),
                history: TabThemeColor(
                    primaryColor: "B99099",
                    secondaryColor: "E5D5C8",
                    accentColor: "F4E4D6"
                ),
                expense: TabThemeColor(
                    primaryColor: "D183A9",
                    secondaryColor: "C8B5E8",
                    accentColor: "E3F2FD"
                ),
                revenue: TabThemeColor(
                    primaryColor: "71557A",
                    secondaryColor: "9B8AA3",
                    accentColor: "E8DFF0"
                ),
                settings: TabThemeColor(
                    primaryColor: "762E3F",
                    secondaryColor: "A67C7C",
                    accentColor: "F2E8E8"
                )
            )
            
        case .lightPastel:
            return AppThemeColors(
                global: TabThemeColor(
                    primaryColor: "007AFF",
                    secondaryColor: "D1D1D6",
                    accentColor: "F2F2F7"
                ),
                order: TabThemeColor(
                    primaryColor: "B5D8EB",
                    secondaryColor: "D4E5F7",
                    accentColor: "E8F4F8"
                ),
                history: TabThemeColor(
                    primaryColor: "FFB5B5",
                    secondaryColor: "FFD1D1",
                    accentColor: "FFE2E2"
                ),
                expense: TabThemeColor(
                    primaryColor: "B5EBD3",
                    secondaryColor: "D4F7E5",
                    accentColor: "E8F8F1"
                ),
                revenue: TabThemeColor(
                    primaryColor: "E2B5EB",
                    secondaryColor: "EFD4F7",
                    accentColor: "F6E8F8"
                ),
                settings: TabThemeColor(
                    primaryColor: "EBB5B5",
                    secondaryColor: "F7D4D4",
                    accentColor: "F8E8E8"
                )
            )
            
        case .darkBold:
            return AppThemeColors(
                global: TabThemeColor(
                    primaryColor: "007AFF",
                    secondaryColor: "D1D1D6",
                    accentColor: "F2F2F7"
                ),
                order: TabThemeColor(
                    primaryColor: "1E3D59",
                    secondaryColor: "2E5A88",
                    accentColor: "4B7CB3"
                ),
                history: TabThemeColor(
                    primaryColor: "8B1E3F",
                    secondaryColor: "B32E59",
                    accentColor: "CC4B7C"
                ),
                expense: TabThemeColor(
                    primaryColor: "1E8B3F",
                    secondaryColor: "2EB359",
                    accentColor: "4BCC7C"
                ),
                revenue: TabThemeColor(
                    primaryColor: "3F1E8B",
                    secondaryColor: "592EB3",
                    accentColor: "7C4BCC"
                ),
                settings: TabThemeColor(
                    primaryColor: "8B3F1E",
                    secondaryColor: "B3592E",
                    accentColor: "CC7C4B"
                )
            )
            
        case .nature:
            return AppThemeColors(
                global: TabThemeColor(
                    primaryColor: "007AFF",
                    secondaryColor: "D1D1D6",
                    accentColor: "F2F2F7"
                ),
                order: TabThemeColor(
                    primaryColor: "2E7D32",
                    secondaryColor: "4CAF50",
                    accentColor: "81C784"
                ),
                history: TabThemeColor(
                    primaryColor: "795548",
                    secondaryColor: "8D6E63",
                    accentColor: "A1887F"
                ),
                expense: TabThemeColor(
                    primaryColor: "00695C",
                    secondaryColor: "00897B",
                    accentColor: "26A69A"
                ),
                revenue: TabThemeColor(
                    primaryColor: "5D4037",
                    secondaryColor: "6D4C41",
                    accentColor: "8D6E63"
                ),
                settings: TabThemeColor(
                    primaryColor: "33691E",
                    secondaryColor: "558B2F",
                    accentColor: "7CB342"
                )
            )
        }
    }
}

class SettingsService {
    static let shared = SettingsService()
    
    // MARK: - Properties
    private let userDefaults = UserDefaults.standard
    private let languageKey = "app_language"
    private let themeKey = "app_theme"
    private let themeColorsKey = "app_theme_colors"
    private let themeStyleKey = "app_theme_style"
    
    // MARK: - Subjects
    private let languageSubject = CurrentValueSubject<AppLanguage, Never>(.vietnamese)
    private let themeStyleSubject = CurrentValueSubject<AppThemeStyle, Never>(.default)
    private let themeColorsSubject = CurrentValueSubject<AppThemeColors, Never>(AppThemeStyle.default.colors)
    
    // MARK: - Publishers
    var languagePublisher: AnyPublisher<AppLanguage, Never> {
        languageSubject.eraseToAnyPublisher()
    }
    
    var themeStylePublisher: AnyPublisher<AppThemeStyle, Never> {
        themeStyleSubject.eraseToAnyPublisher()
    }
    
    var themeColorsPublisher: AnyPublisher<AppThemeColors, Never> {
        themeColorsSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Current Values
    var currentLanguage: AppLanguage {
        languageSubject.value
    }
    
    var currentThemeStyle: AppThemeStyle {
        themeStyleSubject.value
    }
    
    var currentThemeColors: AppThemeColors {
        themeColorsSubject.value
    }
    
    // MARK: - Initialization
    init() {
        loadSettings()
    }
    
    // MARK: - Public Methods
    func setThemeStyle(_ style: AppThemeStyle) {
        themeStyleSubject.send(style)
        themeColorsSubject.send(style.colors)
        saveThemeColors()
    }
    
    func setLanguage(_ language: AppLanguage) {
        languageSubject.send(language)
        saveSettings()
    }
    
    func resetToDefaultTheme() {
        themeStyleSubject.send(.default)
        themeColorsSubject.send(AppThemeStyle.default.colors)
        saveThemeColors()
    }
    
    // MARK: - Private Methods
    private func loadSettings() {
        if let languageRawValue = userDefaults.string(forKey: languageKey),
           let language = AppLanguage(rawValue: languageRawValue) {
            languageSubject.send(language)
        }
        
        loadThemeColors()
    }
    
    private func loadThemeColors() {
        if let themeData = userDefaults.string(forKey: themeColorsKey),
           let data = themeData.data(using: .utf8),
           let themeColors = try? JSONDecoder().decode(AppThemeColors.self, from: data) {
            themeColorsSubject.send(themeColors)
        }
        
        if let styleRawValue = userDefaults.string(forKey: themeStyleKey),
           let style = AppThemeStyle(rawValue: styleRawValue) {
            themeStyleSubject.send(style)
        }
    }
    
    private func saveSettings() {
        userDefaults.set(currentLanguage.rawValue, forKey: languageKey)
        saveThemeColors()
    }
    
    private func saveThemeColors() {
        if let themeData = try? JSONEncoder().encode(currentThemeColors),
           let themeString = String(data: themeData, encoding: .utf8) {
            userDefaults.set(themeString, forKey: themeColorsKey)
            userDefaults.set(currentThemeStyle.rawValue, forKey: themeStyleKey)
        }
    }
} 
