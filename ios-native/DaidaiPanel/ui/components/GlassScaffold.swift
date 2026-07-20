import SwiftUI

struct GlassScaffold<Content: View>: View {
    let backgroundImage: UIImage?
    let blurIntensity: CGFloat
    @ViewBuilder let content: () -> Content
    @EnvironmentObject var themeManager: ThemeManager
    
    init(
        backgroundImage: UIImage? = nil,
        blurIntensity: CGFloat = 10,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.backgroundImage = backgroundImage
        self.blurIntensity = blurIntensity
        self.content = content
    }
    
    var body: some View {
        ZStack {
            // Background layer
            backgroundLayer
            
            // Content
            content()
        }
        .edgesIgnoringSafeArea(.all)
    }
    
    private var backgroundLayer: some View {
        Group {
            if themeManager.glassMode {
                glassBackground
            } else {
                classicBackground
            }
        }
    }
    
    private var glassBackground: some View {
        ZStack {
            // Background image with blur (if provided)
            if let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .blur(radius: blurIntensity)
            } else {
                // Default gradient background for glass mode
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(AppColors.glassBg).opacity(0.8),
                        Color(AppColors.glassBg).opacity(0.4)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            }
            
            // Overlay to ensure content readability
            Color.black.opacity(0.3)
        }
    }
    
    private var classicBackground: some View {
        Group {
            if let image = backgroundImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                Color(AppColors.glassBg)
            }
        }
    }
}

#Preview {
    GlassScaffold {
        VStack {
            Text("Glass Scaffold Preview")
                .font(.title)
                .foregroundColor(.white)
            
            GlassCard {
                Text("Content inside glass card")
                    .foregroundColor(.primary)
            }
            .padding()
        }
    }
    .environmentObject(ThemeManager.shared)
}