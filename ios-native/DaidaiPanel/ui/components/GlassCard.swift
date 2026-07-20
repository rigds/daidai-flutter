import SwiftUI

struct GlassCard<Content: View>: View {
    let cornerRadius: CGFloat
    let padding: CGFloat
    var onClick: (() -> Void)?
    @ViewBuilder let content: () -> Content
    @EnvironmentObject var themeManager: ThemeManager
    
    init(
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 16,
        onClick: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.onClick = onClick
        self.content = content
    }
    
    var body: some View {
        Group {
            if let onClick = onClick {
                Button(action: onClick) {
                    cardContent
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                cardContent
            }
        }
    }
    
    private var cardContent: some View {
        content()
            .padding(padding)
            .background(
                Group {
                    if themeManager.glassMode {
                        // iOS 26 liquid glass effect
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(.ultraThinMaterial)
                    } else {
                        // Classic mode with solid background
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(Color(AppColors.glassCard))
                    }
                }
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color(AppColors.glassCardBorder), lineWidth: 0.5)
            )
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
    }
}

#Preview {
    VStack(spacing: 16) {
        GlassCard {
            Text("Glass Card Preview")
                .foregroundColor(.primary)
        }
        
        GlassCard(cornerRadius: 20, padding: 20) {
            VStack {
                Text("Custom Corner Radius")
                    .font(.headline)
                Text("With more padding")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        
        GlassCard(onClick: { print("Tapped") }) {
            Text("Clickable Card")
                .foregroundColor(.blue)
        }
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}