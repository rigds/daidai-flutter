import SwiftUI

struct AppColors {
    // MARK: - Primary

    static let primary = Color(hex: 0x10B981)
    static let primaryLight = Color(hex: 0xD1FAE5)
    static let primaryDark = Color(hex: 0x059669)

    // MARK: - Slate

    static let slate50 = Color(hex: 0xF8FAFC)
    static let slate100 = Color(hex: 0xF1F5F9)
    static let slate200 = Color(hex: 0xE2E8F0)
    static let slate300 = Color(hex: 0xCBD5E1)
    static let slate400 = Color(hex: 0x94A3B8)
    static let slate500 = Color(hex: 0x64748B)
    static let slate600 = Color(hex: 0x475569)
    static let slate700 = Color(hex: 0x334155)
    static let slate800 = Color(hex: 0x1E293B)
    static let slate900 = Color(hex: 0x0F172A)
    static let slate950 = Color(hex: 0x020617)

    // MARK: - Glass

    static let glassBg = Color(hex: 0xF2F2F7)
    static let glassCard = Color.white
    static let glassCardBorder = Color(hex: 0xE5E5EA)
    static let glassDivider = Color(hex: 0xE5E5EA)

    // MARK: - Blue

    static let blue100 = Color(hex: 0xDBEAFE)
    static let blue500 = Color(hex: 0x3B82F6)
    static let blue600 = Color(hex: 0x2563EB)

    // MARK: - Purple

    static let purple100 = Color(hex: 0xEDE9FE)
    static let purple500 = Color(hex: 0x8B5CF6)
    static let purple600 = Color(hex: 0x7C3AED)

    // MARK: - Red

    static let red50 = Color(hex: 0xFEF2F2)
    static let red100 = Color(hex: 0xFEE2E2)
    static let red500 = Color(hex: 0xEF4444)
    static let red600 = Color(hex: 0xDC2626)

    // MARK: - Amber

    static let amber500 = Color(hex: 0xF59E0B)

    // MARK: - Terminal

    static let termBg = Color(hex: 0x1E1E1E)
    static let termFg = Color(hex: 0xD4D4D4)
    static let termGreen = Color(hex: 0x6A9955)
    static let termRed = Color(hex: 0xF44747)
    static let termYellow = Color(hex: 0xD7BA7D)
    static let termBlue = Color(hex: 0x569CD6)
    static let termCyan = Color(hex: 0x4EC9B0)
    static let termMagenta = Color(hex: 0xC586C0)

    // MARK: - Semantic

    static let success = primary
    static let warning = amber500
    static let error = red500
    static let info = blue500
    static let disabled = slate400

    // MARK: - Dynamic (for light/dark mode)

    static func background(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? slate900 : slate50
    }

    static func cardBackground(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? slate800 : .white
    }

    static func textPrimary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? slate50 : slate900
    }

    static func textSecondary(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? slate400 : slate500
    }

    static func border(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? slate700 : slate200
    }
}

extension Color {
    init(hex: UInt, alpha: Double = 1.0) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: alpha
        )
    }
}
