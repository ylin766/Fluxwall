import SwiftUI

struct ComputerFrameView<Content: View>: View {
    let displaySize: CGSize
    let content: () -> Content

    init(displaySize: CGSize = CGSize(width: 1920, height: 1080),
         @ViewBuilder content: @escaping () -> Content) {
        self.displaySize = displaySize
        self.content = content
    }

    var body: some View {
        GeometryReader { geometry in
            let maxWidth = geometry.size.width - 32
            let aspectRatio = displaySize.width / displaySize.height
            let screenHeight = maxWidth / aspectRatio
            let screenSize = CGSize(width: maxWidth, height: screenHeight)
            let bottomMargin: CGFloat = 80
            let outerHeight = screenHeight + bottomMargin
            
            // Calculate logo position and size based on actual layout
            let bottomPadding: CGFloat = 30 // Padding from frame bottom edge
            let availableSpaceForLogo = bottomMargin - bottomPadding // Space between screen bottom and frame bottom minus padding
            let logoHeight = availableSpaceForLogo * 0.6 // Logo takes 60% of available space
            let spaceAboveLogo = (availableSpaceForLogo - logoHeight) / 2 // Center logo in available space
            let spaceBelow = bottomPadding // Fixed bottom padding

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    // Outer shell
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: screenSize.width + 32, height: outerHeight)
                        .shadow(radius: 6)

                    VStack(spacing: 0) {
                        Spacer(minLength: 20) // Top spacing for content

                        // Content area
                        ZStack {
                            content()
                                .frame(width: screenSize.width, height: screenSize.height)
                                .clipped()
                                .cornerRadius(10)

                            RoundedRectangle(cornerRadius: 10)
                                .stroke(style: StrokeStyle(lineWidth: 1, dash: [6]))
                                .foregroundColor(.gray.opacity(0.6))
                                .allowsHitTesting(false)
                        }
                        .frame(width: screenSize.width, height: screenSize.height)

                        // Fixed spacing above logo
                        Spacer()
                            .frame(height: spaceAboveLogo)

                        // Apple logo with calculated size positioned in center of remaining space
                        Image(systemName: "applelogo")
                            .font(.system(size: logoHeight * 0.8, weight: .medium))
                            .foregroundColor(.gray.opacity(0.7))
                        
                        // Fixed spacing below logo to ensure bottom padding
                        Spacer()
                            .frame(height: spaceBelow)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}