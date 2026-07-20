import Foundation

final class ThemePreferences: ObservableObject {
    static let shared = ThemePreferences()

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let themeMode = "theme_mode"
        static let glassMode = "glass_mode"
        static let backgroundImagePath = "background_image_path"
        static let blurIntensity = "blur_intensity"
    }

    private init() {}

    var themeMode: Int {
        get { defaults.object(forKey: Keys.themeMode) as? Int ?? 0 }
        set {
            defaults.set(newValue, forKey: Keys.themeMode)
            objectWillChange.send()
        }
    }

    var glassMode: Bool {
        get { defaults.object(forKey: Keys.glassMode) as? Bool ?? false }
        set {
            defaults.set(newValue, forKey: Keys.glassMode)
            objectWillChange.send()
        }
    }

    var backgroundImagePath: String? {
        get { defaults.string(forKey: Keys.backgroundImagePath) }
        set {
            defaults.set(newValue, forKey: Keys.backgroundImagePath)
            objectWillChange.send()
        }
    }

    var blurIntensity: Double {
        get { defaults.object(forKey: Keys.blurIntensity) as? Double ?? 20.0 }
        set {
            defaults.set(newValue, forKey: Keys.blurIntensity)
            objectWillChange.send()
        }
    }
}
