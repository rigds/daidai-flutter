import SwiftUI

struct AppBackground: View {
    let backgroundImage: UIImage?
    let blurRadius: CGFloat
    let overlayOpacity: Double
    @EnvironmentObject var themeManager: ThemeManager
    
    init(
        backgroundImage: UIImage? = nil,
        blurRadius: CGFloat = 10,
        overlayOpacity: Double = 0.3
    ) {
        self.backgroundImage = backgroundImage
        self.blurRadius = blurRadius
        self.overlayOpacity = overlayOpacity
    }
    
    var body: some View {
        ZStack {
            // Background layer
            backgroundLayer
            
            // Overlay for better content readability
            overlayLayer
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private var backgroundLayer: some View {
        Group {
            if let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: blurRadius)
            } else {
                // Default background based on theme mode
                if themeManager.glassMode {
                    // Glass mode: gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color(AppColors.glassBg).opacity(0.8),
                            Color(AppColors.glassBg).opacity(0.6)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                } else {
                    // Classic mode: solid background
                    Color(AppColors.glassBg)
                }
            }
        }
    }
    
    private var overlayLayer: some View {
        Group {
            if backgroundImage != nil {
                // Add overlay when using background image
                Color.black.opacity(overlayOpacity)
            } else {
                // No overlay for solid backgrounds
                Color.clear
            }
        }
    }
}

// Convenience initializer for different background types
extension AppBackground {
    /// Create a glass background with default settings
    static var glass: some View {
        AppBackground()
            .environmentObject(ThemeManager.shared)
    }
    
    /// Create a classic background with default settings
    static var classic: some View {
        AppBackground()
            .environmentObject(ThemeManager.shared)
    }
}

#Preview {
    ZStack {
        AppBackground(
            backgroundImage: nil,
            blurRadius: 10,
            overlayOpacity: 0.3
        )
        
        VStack {
            Text("App Background Preview")
                .font(.title)
                .foregroundColor(.white)
            
            Text("With glass effect")
                .foregroundColor(.white.opacity(0.8))
        }
    }
    .environmentObject(ThemeManager.shared)
}