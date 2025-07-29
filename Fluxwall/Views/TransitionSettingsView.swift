import SwiftUI

struct TransitionSettingsView: View {
    @Binding var transitionType: TransitionType
    @Binding var transitionDuration: Double
    
    var hasSelectedFile: Bool
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
        videoFirstFrame: NSImage? = nil,
        videoLastFrame: NSImage? = nil,
        onApplyWallpaper: (() -> Void)? = nil
    ) {
        self._transitionType = transitionType
        self._transitionDuration = transitionDuration
        self.hasSelectedFile = hasSelectedFile
        self.firstFrame = videoFirstFrame
        self.lastFrame = videoLastFrame
        self.onApplyWallpaper = onApplyWallpaper
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(LocalizedStrings.current.transitionSettings)
                .font(.system(size: 14, weight: .semibold))
                .padding(.bottom, 2)
            
            VStack(alignment: .leading, spacing: 6) {
                Text(LocalizedStrings.current.transitionType)
                    .font(.system(size: 12, weight: .medium))
                
                HStack(spacing: 8) {
                    TransitionTypeButton(
                        type: .fade,
                        selectedType: $transitionType,
                        isEnabled: hasSelectedFile
                    )
                    
                    TransitionTypeButton(
                        type: .blackout,
                        selectedType: $transitionType,
                        isEnabled: hasSelectedFile
                    )
                }
            }
            .padding(.horizontal, 4)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(LocalizedStrings.current.transitionDuration)
                        .font(.system(size: 12, weight: .medium))
                    Spacer()
                    Text("\(String(format: "%.1f", transitionDuration))\(LocalizedStrings.current.seconds)")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $transitionDuration, in: 0.5...5.0, step: 0.1)
                    .accentColor(.blue)
                    .disabled(!hasSelectedFile)
                    .scaleEffect(0.9)
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 3)
            
            // 过渡效果预览 - 移到duration下面
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
            
            // Apply Wallpaper 按钮移到最下面
            Button(action: {
                onApplyWallpaper?()
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 12))
                        .foregroundColor(.white)
                    
                    Text(LocalizedStrings.current.applyWallpaper)
                        .font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
            }
            .buttonStyle(BorderlessButtonStyle())
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(hasSelectedFile ? Color.blue : Color.gray.opacity(0.5))
            )
            .foregroundColor(.white)
            .disabled(!hasSelectedFile)
            .padding(.horizontal, 4)
            .padding(.top, 8)
            
            Spacer()
        }
        .onDisappear {
            stopPreview()
        }
    }
    
    // 开始预览动画 - 只播放一次
    private func startPreview() {
        // 如果正在播放，先停止
        stopPreview()
        
        isPreviewPlaying = true
        previewProgress = 0.0
        
        // 根据实际过渡时长计算更新间隔
        let updateInterval = 0.05
        let progressIncrement = updateInterval / transitionDuration
        
        // 创建定时器来更新预览进度
        previewTimer = Timer.scheduledTimer(withTimeInterval: updateInterval, repeats: true) { _ in
            if previewProgress < 1.0 {
                previewProgress += progressIncrement
            } else {
                // 播放完成，停止播放
                stopPreview()
            }
        }
    }
    
    // 停止预览动画
    private func stopPreview() {
        isPreviewPlaying = false
        previewTimer?.invalidate()
        previewTimer = nil
    }
}

// 过渡类型按钮
struct TransitionTypeButton: View {
    let type: TransitionType
    @Binding var selectedType: TransitionType
    let isEnabled: Bool
    @State private var isPressed: Bool = false
    
    var body: some View {
        Button(action: {
            if isEnabled {
                // 添加触觉反馈
                withAnimation(.easeInOut(duration: 0.1)) {
                    isPressed = true
                }
                
                selectedType = type
                
                // 重置按压状态
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
            }
        }) {
            VStack(spacing: 4) {
                // 图标 - 紧凑化，添加动画
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(selectedType == type ? Color.blue.opacity(0.2) : Color(.controlBackgroundColor))
                        .frame(width: 60, height: 40)
                        .scaleEffect(isPressed ? 0.95 : 1.0)
                        .animation(.easeInOut(duration: 0.1), value: isPressed)
                    
                    // 过渡效果示意图 - 紧凑化
                    if type == .fade {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 18, height: 25)
                            
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue.opacity(0.7), Color.green.opacity(0.7)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 24, height: 25)
                            
                            Rectangle()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: 18, height: 25)
                        }
                    } else {
                        HStack(spacing: 0) {
                            Rectangle()
                                .fill(Color.blue.opacity(0.7))
                                .frame(width: 18, height: 25)
                            
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.blue.opacity(0.3),
                                    Color.black,
                                    Color.green.opacity(0.3)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                            .frame(width: 24, height: 25)
                            
                            Rectangle()
                                .fill(Color.green.opacity(0.7))
                                .frame(width: 18, height: 25)
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(selectedType == type ? Color.blue : Color.clear, lineWidth: 1.5)
                        .animation(.easeInOut(duration: 0.2), value: selectedType == type)
                )
                
                // 文本 - 紧凑化
                Text(type.description)
                    .font(.system(size: 10))
                    .foregroundColor(isEnabled ? .primary : .secondary)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .opacity(isEnabled ? 1.0 : 0.5)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
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
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    // 最后一帧（结束状态）- 如果有的话
                    if let lastFrame = lastFrame, lastFrame !== firstFrame {
                        Image(nsImage: lastFrame)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .opacity(calculateLastFrameOpacity())
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
}

#Preview {
    TransitionSettingsView(
        transitionType: .constant(.fade),
        transitionDuration: .constant(1.0),
        hasSelectedFile: true,
        onApplyWallpaper: { print("预览中点击了应用壁纸") }
    )
    .frame(width: 300, height: 400)
    .padding()
}
