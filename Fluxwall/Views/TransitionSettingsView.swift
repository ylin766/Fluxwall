import SwiftUI

// MARK: - Animated Apply Button Component
struct AnimatedApplyButton: View {
    let action: () -> Void
    let isEnabled: Bool
    
    @State private var isHovered = false
    @State private var isSuccess = false
    @State private var showSuccess = false
    
    var body: some View {
        Button(action: {
            guard isEnabled else { return }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                isSuccess = true
                showSuccess = true
            }
            
            action()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    isSuccess = false
                    showSuccess = false
                }
            }
        }) {
            HStack(spacing: 6) {
                Image(systemName: isSuccess ? "checkmark" : "photo.on.rectangle.angled")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.buttonTextActive)
                
                Text(isSuccess ? LocalizedStrings.current.wallpaperApplied : LocalizedStrings.current.applyWallpaper)
                    .font(.system(size: 12, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(
                        LinearGradient(
                            colors: isEnabled ? (isSuccess ? [
                                ModernDesignSystem.Colors.successColor.opacity(0.9),
                                ModernDesignSystem.Colors.successColor.opacity(0.7)
                            ] : [
                                ModernDesignSystem.Colors.infoColor.opacity(0.9),
                                ModernDesignSystem.Colors.infoColor.opacity(0.7)
                            ]) : [
                                ModernDesignSystem.Colors.tertiaryText.opacity(0.3),
                                ModernDesignSystem.Colors.tertiaryText.opacity(0.2)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(
                        color: isEnabled ? (isSuccess ? ModernDesignSystem.Colors.successColor.opacity(0.4) : ModernDesignSystem.Colors.infoColor.opacity(0.4)) : Color.clear,
                        radius: isHovered ? 8 : 4,
                        x: 0,
                        y: isHovered ? 4 : 2
                    )
                    .animation(.easeInOut(duration: 0.3), value: isSuccess)
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
            )
            .scaleEffect(isHovered && isEnabled ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(ModernDesignSystem.Colors.buttonTextActive)
        .disabled(!isEnabled)
        .onHover { hovering in
            guard isEnabled else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct TransitionSettingsView: View {
    @Binding var transitionType: TransitionType
    @Binding var transitionDuration: Double
    @StateObject private var languageSettings = LanguageSettings.shared
    
    var hasSelectedFile: Bool
    var isBuiltInWallpaper: Bool = false
    var firstFrame: NSImage?
    var lastFrame: NSImage?
    var onApplyWallpaper: (() -> Void)?
    
    @State private var isPreviewPlaying: Bool = false
    @State private var previewProgress: Double = 0.0
    @State private var previewTimer: Timer?
    
    init(
        transitionType: Binding<TransitionType>,
        transitionDuration: Binding<Double>,
        hasSelectedFile: Bool,
        isBuiltInWallpaper: Bool = false,
        videoFirstFrame: NSImage? = nil,
        videoLastFrame: NSImage? = nil,
        onApplyWallpaper: (() -> Void)? = nil
    ) {
        self._transitionType = transitionType
        self._transitionDuration = transitionDuration
        self.hasSelectedFile = hasSelectedFile
        self.isBuiltInWallpaper = isBuiltInWallpaper
        self.firstFrame = videoFirstFrame
        self.lastFrame = videoLastFrame
        self.onApplyWallpaper = onApplyWallpaper
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStrings.current.transitionSettings)
                .font(.system(size: 14, weight: .semibold))
                .padding(.bottom, 2)
            
            VStack(alignment: .leading, spacing: 8) {
                Text(LocalizedStrings.current.transitionType)
                    .font(.system(size: 12, weight: .medium))
                
                HStack(spacing: 6) {
                    TransitionTypeButton(
                        type: .none,
                        selectedType: $transitionType,
                        isEnabled: hasSelectedFile
                    )
                    .frame(maxWidth: .infinity)
                    
                    TransitionTypeButton(
                        type: .fade,
                        selectedType: $transitionType,
                        isEnabled: hasSelectedFile && !isBuiltInWallpaper
                    )
                    .frame(maxWidth: .infinity)
                    
                    TransitionTypeButton(
                        type: .blackout,
                        selectedType: $transitionType,
                        isEnabled: hasSelectedFile && !isBuiltInWallpaper
                    )
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(LocalizedStrings.current.transitionDuration)
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(String(format: "%.1f", transitionDuration))\(LocalizedStrings.current.seconds)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(ModernDesignSystem.Colors.primaryText)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(ModernDesignSystem.Colors.cardBackground)
                        )
                }
                
                Slider(value: $transitionDuration, in: 0.5...5.0, step: 0.1)
                    .accentColor(ModernDesignSystem.Colors.gradientBlueStart)
                    .disabled(!hasSelectedFile)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 6)
            
            if hasSelectedFile {
                VStack(alignment: .leading, spacing: 6) {
                    Text(LocalizedStrings.current.effectPreview)
                        .font(.system(size: 12, weight: .medium))
                    
                    TransitionEffectPreview(
                        transitionType: transitionType,
                        progress: previewProgress,
                        isPlaying: isPreviewPlaying,
                        firstFrame: firstFrame,
                        lastFrame: lastFrame,
                        onTap: {
                            startPreview()
                        }
                    )
                    .frame(height: 120)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .padding(.horizontal, 4)
                .padding(.top, 6)
            }
            
            AnimatedApplyButton(
                action: {
                    onApplyWallpaper?()
                },
                isEnabled: hasSelectedFile
            )
            .padding(.horizontal, 4)
            .padding(.top, 8)
            
            Spacer()
        }
        .onDisappear {
            stopPreview()
        }
        .onChange(of: isBuiltInWallpaper) { newValue in
            if newValue {
                transitionType = .none
            }
        }
    }
    
    private func startPreview() {
        stopPreview()
        
        isPreviewPlaying = true
        previewProgress = 0.0
        
        let updateInterval = 0.05
        let progressIncrement = updateInterval / transitionDuration
        
        previewTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            if previewProgress < 1.0 {
                previewProgress += progressIncrement
            } else {
                stopPreview()
            }
        }
    }
    
    private func stopPreview() {
        isPreviewPlaying = false
        previewTimer?.invalidate()
        previewTimer = nil
    }
    

}

struct TransitionTypeButton: View {
    let type: TransitionType
    @Binding var selectedType: TransitionType
    let isEnabled: Bool
    @StateObject private var languageSettings = LanguageSettings.shared
    
    var body: some View {
        Button(action: {
            if isEnabled {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    selectedType = type
                }
            }
        }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(ModernDesignSystem.Colors.cardBackground)
                        .frame(height: 45)
                        .frame(maxWidth: .infinity)
                    
                    getTransitionIcon()
                        .foregroundColor(selectedType == type ? ModernDesignSystem.Colors.buttonTextActive : ModernDesignSystem.Colors.primaryText)
                }
                
                Text(getTransitionTypeName(type))
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(selectedType == type ? ModernDesignSystem.Colors.buttonTextActive : ModernDesignSystem.Colors.primaryText)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .animatedToggleButton(
            isSelected: selectedType == type,
            cornerRadius: ModernDesignSystem.CornerRadius.medium
        )
        .opacity(isEnabled ? 1.0 : 0.5)
        .disabled(!isEnabled)
    }
    
    @ViewBuilder
    private func getTransitionIcon() -> some View {
        switch type {
        case .none:
            Image(systemName: "rectangle.2.swap")
                .font(.system(size: 18, weight: .medium))
        case .fade:
            Image(systemName: "circle.righthalf.filled")
                .font(.system(size: 18, weight: .medium))
        case .blackout:
            Image(systemName: "moon.fill")
                .font(.system(size: 18, weight: .medium))
        }
    }
    
    private func getTransitionTypeName(_ type: TransitionType) -> String {
        switch type {
        case .none:
            return LocalizedStrings.current.transitionNone
        case .fade:
            return LocalizedStrings.current.transitionFade
        case .blackout:
            return LocalizedStrings.current.transitionBlackout
        }
    }
}

// 过渡效果预览组件
struct TransitionEffectPreview: View {
    let transitionType: TransitionType
    let progress: Double
    let isPlaying: Bool
    let firstFrame: NSImage?
    let lastFrame: NSImage?
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
            onTap()
        }) {
            ZStack {
                // 背景
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color(.controlBackgroundColor))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color(.separatorColor), lineWidth: 0.5)
                    )
                
                if let firstFrame = firstFrame {
                    // 第一帧（开始状态）
                    Image(nsImage: firstFrame)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .opacity(calculateFirstFrameOpacity())
                        .offset(calculateFirstFrameOffset())
                        .scaleEffect(calculateFirstFrameScale())
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // 最后一帧（结束状态）- 如果有的话
                    if let lastFrame = lastFrame, lastFrame !== firstFrame {
                        Image(nsImage: lastFrame)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(calculateLastFrameOpacity())
                            .offset(calculateLastFrameOffset())
                            .scaleEffect(calculateLastFrameScale())
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    
                    // 黑幕效果（仅用于blackout过渡）
                    if transitionType == .blackout {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.black)
                            .opacity(calculateBlackoutOpacity())
                    }
                } else {
                    // 没有图片时显示占位符
                    VStack(spacing: 8) {
                        Image(systemName: "photo")
                            .font(.system(size: 24))
                            .foregroundColor(.secondary)
                        Text(LocalizedStrings.current.effectPreview)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                }
                
                // 进度指示器
                if isPlaying {
                    VStack {
                        Spacer()
                        HStack {
                            Rectangle()
                                .fill(Color.white.opacity(0.9))
                                .frame(height: 3)
                                .scaleEffect(x: progress, anchor: .leading)
                                .clipShape(RoundedRectangle(cornerRadius: 1.5))
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        .padding(.bottom, 4)
                    }
                }
                
                // 播放覆盖层（当没有播放时显示）
                if !isPlaying && firstFrame != nil {
                    Circle()
                        .fill(Color.black.opacity(0.6))
                        .frame(width: 40, height: 40)
                        .overlay(
                            Image(systemName: "play.fill")
                                .font(.system(size: 16))
                                .foregroundColor(.white)
                        )
                        .opacity(0.8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.linear(duration: 0.05), value: progress)
    }
    
    private func calculateFirstFrameOpacity() -> Double {
        switch transitionType {
        case .none:
            return 1.0  // 无效果时始终显示第一帧
        case .fade:
            return 1.0 - progress
        case .blackout:
            if progress < 0.5 {
                return 1.0 - (progress * 2)  // 前半段淡出
            } else {
                return 0.0  // 后半段保持透明
            }
        }
    }
    
    private func calculateLastFrameOpacity() -> Double {
        switch transitionType {
        case .none:
            return 0.0  // 无效果时不显示第二帧
        case .fade:
            return progress
        case .blackout:
            if progress < 0.5 {
                return 0.0  // 前半段保持透明
            } else {
                return (progress - 0.5) * 2  // 后半段淡入
            }
        }
    }
    
    private func calculateBlackoutOpacity() -> Double {
        if transitionType == .blackout {
            // 在中间时刻达到最大黑幕
            if progress < 0.5 {
                return progress * 2
            } else {
                return (1.0 - progress) * 2
            }
        }
        return 0.0
    }
    
    private func calculateFirstFrameOffset() -> CGSize {
        return CGSize.zero
    }
    
    private func calculateLastFrameOffset() -> CGSize {
        return CGSize.zero
    }
    
    private func calculateFirstFrameScale() -> Double {
        return 1.0
    }
    
    private func calculateLastFrameScale() -> Double {
        return 1.0
    }
}

#Preview {
    TransitionSettingsView(
        transitionType: .constant(.fade),
        transitionDuration: .constant(1.0),
        hasSelectedFile: true,
        isBuiltInWallpaper: false,
        onApplyWallpaper: { print("预览中点击了应用壁纸") }
    )
    .frame(width: 300, height: 400)
    .padding()
}
