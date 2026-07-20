import SwiftUI

struct ResourceCard: View {
    let percentage: Double
    let label: String
    let size: CGFloat
    let lineWidth: CGFloat
    
    @EnvironmentObject var themeManager: ThemeManager
    
    init(
        percentage: Double,
        label: String,
        size: CGFloat = 80,
        lineWidth: CGFloat = 8
    ) {
        self.percentage = min(max(percentage, 0), 100) // Clamp between 0-100
        self.label = label
        self.size = size
        self.lineWidth = lineWidth
    }
    
    var body: some View {
        GlassCard(padding: 12) {
            VStack(spacing: 8) {
                // Circular progress indicator
                ZStack {
                    // Background circle
                    Circle()
                        .stroke(
                            Color(AppColors.glassCardBorder),
                            lineWidth: lineWidth
                        )
                    
                    // Progress circle
                    Circle()
                        .trim(from: 0, to: CGFloat(percentage / 100))
                        .stroke(
                            progressColor,
                            style: StrokeStyle(
                                lineWidth: lineWidth,
                                lineCap: .round
                            )
                        )
                        .rotationEffect(.degrees(-90))
                        .animation(.easeInOut(duration: 0.5), value: percentage)
                    
                    // Percentage text
                    VStack(spacing: 2) {
                        Text("\(Int(percentage))%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        
                        Text(label)
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                }
                .frame(width: size, height: size)
                
                // Label below
                Text(label)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private var progressColor: Color {
        if percentage < 60 {
            // Green for low usage
            return Color(AppColors.success)
        } else if percentage < 80 {
            // Yellow for medium usage
            return Color(AppColors.warning)
        } else {
            // Red for high usage
            return Color(AppColors.error)
        }
    }
}

// Convenience initializer for different resource types
extension ResourceCard {
    /// Create a CPU resource card
    static func cpu(percentage: Double) -> ResourceCard {
        ResourceCard(percentage: percentage, label: "CPU")
    }
    
    /// Create a Memory resource card
    static func memory(percentage: Double) -> ResourceCard {
        ResourceCard(percentage: percentage, label: "内存")
    }
    
    /// Create a Disk resource card
    static func disk(percentage: Double) -> ResourceCard {
        ResourceCard(percentage: percentage, label: "磁盘")
    }
}

#Preview {
    VStack(spacing: 20) {
        HStack(spacing: 16) {
            ResourceCard.cpu(percentage: 45)
            ResourceCard.memory(percentage: 72)
            ResourceCard.disk(percentage: 88)
        }
        
        HStack(spacing: 16) {
            ResourceCard(percentage: 25, label: "Low")
            ResourceCard(percentage: 65, label: "Medium")
            ResourceCard(percentage: 95, label: "High")
        }
    }
    .padding()
    .environmentObject(ThemeManager.shared)
}