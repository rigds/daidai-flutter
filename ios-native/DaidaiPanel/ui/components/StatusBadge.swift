import SwiftUI

enum StatusType {
    case success
    case failed
    case running
    case disabled
    case queued
    
    var color: Color {
        switch self {
        case .success:
            return Color(AppColors.success)
        case .failed:
            return Color(AppColors.error)
        case .running:
            return Color(AppColors.primary)
        case .disabled:
            return Color(AppColors.disabled)
        case .queued:
            return Color(AppColors.warning)
        }
    }
    
    var icon: String {
        switch self {
        case .success:
            return "checkmark.circle.fill"
        case .failed:
            return "xmark.circle.fill"
        case .running:
            return "arrow.clockwise"
        case .disabled:
            return "pause.circle.fill"
        case .queued:
            return "clock.fill"
        }
    }
    
    var label: String {
        switch self {
        case .success:
            return "成功"
        case .failed:
            return "失败"
        case .running:
            return "运行中"
        case .disabled:
            return "已禁用"
        case .queued:
            return "排队中"
        }
    }
}

struct StatusBadge: View {
    let status: StatusType
    let showIcon: Bool
    let showLabel: Bool
    let size: BadgeSize
    
    @State private var isAnimating = false
    
    init(
        status: StatusType,
        showIcon: Bool = true,
        showLabel: Bool = true,
        size: BadgeSize = .medium
    ) {
        self.status = status
        self.showIcon = showIcon
        self.showLabel = showLabel
        self.size = size
    }
    
    var body: some View {
        HStack(spacing: size.spacing) {
            if showIcon {
                iconView
            }
            
            if showLabel {
                Text(status.label)
                    .font(size.font)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
            }
        }
        .padding(.horizontal, size.horizontalPadding)
        .padding(.vertical, size.verticalPadding)
        .background(
            Capsule()
                .fill(status.color.opacity(0.9))
        )
        .clipShape(Capsule())
    }
    
    private var iconView: some View {
        Group {
            if status == .running {
                Image(systemName: status.icon)
                    .font(size.iconFont)
                    .foregroundColor(.white)
                    .rotationEffect(.degrees(isAnimating ? 360 : 0))
                    .animation(
                        Animation.linear(duration: 1)
                            .repeatForever(autoreverses: false),
                        value: isAnimating
                    )
                    .onAppear {
                        isAnimating = true
                    }
                    .onDisappear {
                        isAnimating = false
                    }
            } else {
                Image(systemName: status.icon)
                    .font(size.iconFont)
                    .foregroundColor(.white)
            }
        }
    }
}

enum BadgeSize {
    case small
    case medium
    case large
    
    var font: Font {
        switch self {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .footnote
        }
    }
    
    var iconFont: Font {
        switch self {
        case .small:
            return .caption2
        case .medium:
            return .caption
        case .large:
            return .footnote
        }
    }
    
    var spacing: CGFloat {
        switch self {
        case .small:
            return 2
        case .medium:
            return 4
        case .large:
            return 6
        }
    }
    
    var horizontalPadding: CGFloat {
        switch self {
        case .small:
            return 6
        case .medium:
            return 8
        case .large:
            return 12
        }
    }
    
    var verticalPadding: CGFloat {
        switch self {
        case .small:
            return 2
        case .medium:
            return 4
        case .large:
            return 6
        }
    }
}

// Convenience initializers
extension StatusBadge {
    /// Create a success badge
    static func success(showIcon: Bool = true, showLabel: Bool = true, size: BadgeSize = .medium) -> StatusBadge {
        StatusBadge(status: .success, showIcon: showIcon, showLabel: showLabel, size: size)
    }
    
    /// Create a failed badge
    static func failed(showIcon: Bool = true, showLabel: Bool = true, size: BadgeSize = .medium) -> StatusBadge {
        StatusBadge(status: .failed, showIcon: showIcon, showLabel: showLabel, size: size)
    }
    
    /// Create a running badge
    static func running(showIcon: Bool = true, showLabel: Bool = true, size: BadgeSize = .medium) -> StatusBadge {
        StatusBadge(status: .running, showIcon: showIcon, showLabel: showLabel, size: size)
    }
    
    /// Create a disabled badge
    static func disabled(showIcon: Bool = true, showLabel: Bool = true, size: BadgeSize = .medium) -> StatusBadge {
        StatusBadge(status: .disabled, showIcon: showIcon, showLabel: showLabel, size: size)
    }
    
    /// Create a queued badge
    static func queued(showIcon: Bool = true, showLabel: Bool = true, size: BadgeSize = .medium) -> StatusBadge {
        StatusBadge(status: .queued, showIcon: showIcon, showLabel: showLabel, size: size)
    }
}

#Preview {
    VStack(spacing: 20) {
        // Different status types
        HStack(spacing: 12) {
            StatusBadge.success()
            StatusBadge.failed()
            StatusBadge.running()
            StatusBadge.disabled()
            StatusBadge.queued()
        }
        
        // Different sizes
        HStack(spacing: 12) {
            StatusBadge(status: .success, size: .small)
            StatusBadge(status: .success, size: .medium)
            StatusBadge(status: .success, size: .large)
        }
        
        // Icon only
        HStack(spacing: 12) {
            StatusBadge(status: .success, showLabel: false)
            StatusBadge(status: .failed, showLabel: false)
            StatusBadge(status: .running, showLabel: false)
        }
        
        // Label only
        HStack(spacing: 12) {
            StatusBadge(status: .success, showIcon: false)
            StatusBadge(status: .failed, showIcon: false)
            StatusBadge(status: .running, showIcon: false)
        }
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}