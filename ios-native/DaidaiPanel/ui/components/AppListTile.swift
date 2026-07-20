import SwiftUI

struct AppListTile<Trailing: View>: View {
    let icon: String
    let title: String
    var onClick: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing
    
    @EnvironmentObject var themeManager: ThemeManager
    
    init(
        icon: String,
        title: String,
        onClick: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing = { EmptyView() }
    ) {
        self.icon = icon
        self.title = title
        self.onClick = onClick
        self.trailing = trailing
    }
    
    var body: some View {
        Group {
            if let onClick = onClick {
                Button(action: onClick) {
                    tileContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                tileContent
            }
        }
    }
    
    private var tileContent: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(Color(AppColors.primary))
                .frame(width: 24, height: 24)
            
            // Title
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            // Trailing content
            trailing()
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            Group {
                if themeManager.glassMode {
                    // Glass mode with ultra thin material
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.ultraThinMaterial)
                } else {
                    // Classic mode with solid background
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(AppColors.glassCard))
                }
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(AppColors.glassCardBorder), lineWidth: 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// Convenience initializer for simple cases without trailing
extension AppListTile where Trailing == EmptyView {
    init(
        icon: String,
        title: String,
        onClick: (() -> Void)? = nil
    ) {
        self.icon = icon
        self.title = title
        self.onClick = onClick
        self.trailing = { EmptyView() }
    }
}

#Preview {
    VStack(spacing: 8) {
        AppListTile(
            icon: "gear",
            title: "Settings",
            onClick: { print("Tapped settings") }
        )
        
        AppListTile(
            icon: "bell",
            title: "Notifications",
            trailing: {
                Text("3")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.red)
                    .foregroundColor(.white)
                    .clipShape(Capsule())
            }
        )
        
        AppListTile(
            icon: "person",
            title: "Profile"
        )
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}