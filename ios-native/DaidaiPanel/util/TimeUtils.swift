import Foundation

enum TimeUtils {
    private static let relativeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.unitsStyle = .full
        return f
    }()

    private static let cnDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年MM月dd日 HH:mm:ss"
        return f
    }()

    private static let cnShortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "yyyy年MM月dd日"
        return f
    }()

    private static let cnTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "zh_CN")
        f.dateFormat = "HH:mm:ss"
        return f
    }()

    private static let isoFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()

    static func formatTimeCn(_ date: Date?) -> String {
        guard let date else { return "-" }

        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            return "今天 \(cnTimeFormatter.string(from: date))"
        }
        if calendar.isDateInYesterday(date) {
            return "昨天 \(cnTimeFormatter.string(from: date))"
        }

        let now = Date()
        let components = calendar.dateComponents([.year], from: date, to: now)
        if let years = components.year, years < 1 {
            let monthDay = DateFormatter()
            monthDay.locale = Locale(identifier: "zh_CN")
            monthDay.dateFormat = "MM月dd日 HH:mm"
            return monthDay.string(from: date)
        }

        return cnDateFormatter.string(from: date)
    }

    static func formatRelative(_ date: Date?) -> String {
        guard let date else { return "-" }
        return relativeFormatter.localizedString(for: date, relativeTo: Date())
    }

    static func formatDuration(_ seconds: Double?) -> String {
        guard let seconds else { return "-" }
        if seconds < 1 { return "\(Int(seconds * 1000))ms" }
        if seconds < 60 { return String(format: "%.1fs", seconds) }
        let minutes = Int(seconds / 60)
        let secs = Int(seconds.truncatingRemainder(dividingBy: 60))
        return "\(minutes)m\(secs)s"
    }

    static func formatISO(_ date: Date?) -> String? {
        guard let date else { return nil }
        return isoFormatter.string(from: date)
    }

    static func formatFileSize(_ bytes: Int64?) -> String {
        guard let bytes, bytes > 0 else { return "0 B" }
        let units = ["B", "KB", "MB", "GB", "TB"]
        var value = Double(bytes)
        var unitIndex = 0
        while value >= 1024 && unitIndex < units.count - 1 {
            value /= 1024
            unitIndex += 1
        }
        if unitIndex == 0 { return "\(bytes) B" }
        return String(format: "%.1f %@", value, units[unitIndex])
    }
}
