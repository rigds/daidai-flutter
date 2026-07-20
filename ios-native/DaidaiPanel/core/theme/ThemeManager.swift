import SwiftUI
import Combine

enum ThemeMode: Int, CaseIterable {
    case system = 0
    case light = 1
    case dark = 2

    var displayName: String {
        switch self {
        case .system: return "跟随系统"
        case .light: return "浅色模式"
        case .dark: return "深色模式"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

@MainActor
final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    private let preferences: ThemePreferences

    @Published var themeMode: ThemeMode {
        didSet {
            preferences.themeMode = themeMode.rawValue
        }
    }

    @Published var glassMode: Bool {
        didSet {
            preferences.glassMode = glassMode
        }
    }

    @Published var backgroundImagePath: String? {
        didSet {
            preferences.backgroundImagePath = backgroundImagePath
        }
    }

    @Published var blurIntensity: Double {
        didSet {
            preferences.blurIntensity = blurIntensity
        }
    }

    private init() {
        let prefs = ThemePreferences.shared
        self.preferences = prefs
        self.themeMode = ThemeMode(rawValue: prefs.themeMode) ?? .system
        self.glassMode = prefs.glassMode
        self.backgroundImagePath = prefs.backgroundImagePath
        self.blurIntensity = prefs.blurIntensity
    }

    var resolvedColorScheme: ColorScheme? {
        themeMode.colorScheme
    }

    func setThemeMode(_ mode: ThemeMode) {
        themeMode = mode
    }

    func toggleGlassMode() {
        glassMode.toggle()
    }

    func setBackgroundImage(_ path: String?) {
        backgroundImagePath = path
    }

    func setBlurIntensity(_ intensity: Double) {
        blurIntensity = max(0, min(50, intensity))
    }
}
