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
            let outerHeight = screenHeight + 80 // 增加壳体下边距

            VStack(spacing: 0) {
                ZStack(alignment: .top) {
                    // ✅ 外层壳体
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: screenSize.width + 32, height: outerHeight)
                        .shadow(radius: 6)

                    VStack(spacing: 0) {
                        Spacer(minLength: 20) // ✅ 内容上方留白

                        // ✅ 内容区域
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

                        Spacer(minLength: 12)

                        // ✅ logo 放大并靠近底部
                        Text("")
                            .font(.system(size: 36, weight: .medium))
                            .foregroundColor(.gray)
                            .padding(.bottom, 30)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
