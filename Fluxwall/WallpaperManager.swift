import Cocoa
import AVFoundation

class DesktopOverlayWindow: NSWindow {
    private let windowId = UUID().uuidString
    
    private var playerA: AVPlayer?
    private var playerB: AVPlayer?
    private var playerLayerA: AVPlayerLayer?
    private var playerLayerB: AVPlayerLayer?
    
    private var currentVideoURL: URL?
    private var isPlayerAActive = true
    private var isTransitioning = false
    private var timeObserver: Any?
    
    deinit {
        print("[LIFECYCLE] ⚠️ DesktopOverlayWindow 析构开始 - ID: \(windowId)")
        
        if playerA != nil {
            print("[LIFECYCLE] ⚠️ 析构时发现playerA未清理 - ID: \(windowId)")
        }
        if playerB != nil {
            print("[LIFECYCLE] ⚠️ 析构时发现playerB未清理 - ID: \(windowId)")
        }
        if timeObserver != nil {
            print("[LIFECYCLE] ⚠️ 析构时发现timeObserver未清理 - ID: \(windowId)")
        }
        if playerLayerA != nil {
            print("[LIFECYCLE] ⚠️ 析构时发现playerLayerA未清理 - ID: \(windowId)")
        }
        if playerLayerB != nil {
            print("[LIFECYCLE] ⚠️ 析构时发现playerLayerB未清理 - ID: \(windowId)")
        }
        
        print("[LIFECYCLE] ✅ DesktopOverlayWindow 析构完成 - ID: \(windowId)")
    }
    
    var transitionType: TransitionType = .fade
    var transitionDuration: Double = 1.0
    
    var targetDisplayID: CGDirectDisplayID?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSScreen.main?.frame ?? .zero, styleMask: [.borderless], backing: .buffered, defer: true)
        print("[LIFECYCLE] DesktopOverlayWindow 初始化开始 - ID: \(windowId)")
        setupWindow()
        print("[LIFECYCLE] DesktopOverlayWindow 初始化完成 - ID: \(windowId)")
    }
    
    convenience init() {
        print("[LIFECYCLE] DesktopOverlayWindow convenience init 开始")
        self.init(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        print("[LIFECYCLE] DesktopOverlayWindow convenience init 完成 - ID: \(windowId)")
    }
    
    convenience init(for displayID: CGDirectDisplayID) {
        print("[LIFECYCLE] DesktopOverlayWindow 为显示器 \(displayID) 初始化开始")
        self.init(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        self.targetDisplayID = displayID
        setupWindowForDisplay(displayID)
        print("[LIFECYCLE] DesktopOverlayWindow 为显示器 \(displayID) 初始化完成 - ID: \(windowId)")
    }
    
    private func setupWindow() {
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) - 1)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.hidesOnDeactivate = false
        self.canHide = false
        
        if let mainScreen = NSScreen.main {
            self.setFrame(mainScreen.frame, display: false)
        }
        
        let contentView = NSView(frame: self.frame)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        self.contentView = contentView
    }
    
    private func setupWindowForDisplay(_ displayID: CGDirectDisplayID) {
        self.level = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopWindow)) - 1)
        self.isOpaque = false
        self.backgroundColor = .clear
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        self.hidesOnDeactivate = false
        self.canHide = false
        
        if let targetScreen = findScreenForDisplay(displayID) {
            print("[DEBUG] 为显示器 \(displayID) 设置窗口frame: \(targetScreen.frame)")
            self.setFrame(targetScreen.frame, display: false)
        } else {
            print("[WARNING] 找不到显示器 \(displayID)，使用主屏幕")
            if let mainScreen = NSScreen.main {
                self.setFrame(mainScreen.frame, display: false)
            }
        }
        
        let contentView = NSView(frame: self.frame)
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        self.contentView = contentView
    }
    
    private func findScreenForDisplay(_ displayID: CGDirectDisplayID) -> NSScreen? {
        return NSScreen.screens.first { screen in
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            return screenNumber == displayID
        }
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
    
    func setupVideoPlayer(with url: URL, scale: CGFloat = 1.0, offset: CGSize = .zero) {
        if isBeingClosed {
            print("[WARNING] 窗口正在关闭中，跳过视频播放器设置 - 窗口ID: \(windowId)")
            return
        }
        
        print("[INFO] 开始设置视频播放器 - URL: \(url.lastPathComponent) - 窗口ID: \(windowId)")
        
        print("[LIFECYCLE] === 设置视频播放器前的对象状态 ===")
        trackObjectLifecycle()
        
        if !FileManager.default.fileExists(atPath: url.path) {
            print("[ERROR] 设置视频播放器失败 - 文件不存在: \(url.path) - 窗口ID: \(windowId)")
            return
        }
        
        guard let contentView = self.contentView else {
            print("[ERROR] 设置视频播放器失败 - contentView为空 - 窗口ID: \(windowId)")
            return
        }
        
        print("[DEBUG] contentView尺寸: \(contentView.bounds.size) - 窗口ID: \(windowId)")
        
        if contentView.layer == nil {
            print("[DEBUG] 为contentView设置wantsLayer=true - 窗口ID: \(windowId)")
            contentView.wantsLayer = true
        }
        
        if playerA != nil || playerB != nil || timeObserver != nil {
            print("[DEBUG] 清理现有播放器资源 - 窗口ID: \(windowId)")
            cleanupVideoPlayerSync()
        } else {
            print("[DEBUG] 没有现有播放器需要清理 - 窗口ID: \(windowId)")
        }
        
        currentVideoURL = url
        print("[DEBUG] 已保存视频URL: \(url.lastPathComponent) - 窗口ID: \(windowId)")
        
        do {
            print("[DEBUG] 开始创建双播放器系统 - 窗口ID: \(windowId)")
            try setupDualPlayerSystem(with: url, in: contentView, scale: scale, offset: offset)
            
            print("[LIFECYCLE] === 设置视频播放器后的对象状态 ===")
            trackObjectLifecycle()
            
            print("[INFO] 视频播放器设置完成 - 过渡类型: \(transitionType.rawValue), 过渡时间: \(transitionDuration)秒 - 窗口ID: \(windowId)")
        } catch VideoPlayerError.playerCreationFailed {
            print("[ERROR] 创建播放器失败 - 窗口ID: \(windowId)")
        } catch VideoPlayerError.layerCreationFailed {
            print("[ERROR] 创建播放器层失败 - 窗口ID: \(windowId)")
        } catch VideoPlayerError.contentViewLayerMissing {
            print("[ERROR] contentView的layer缺失 - 窗口ID: \(windowId)")
        } catch {
            print("[ERROR] 创建双播放器系统失败: \(error) - 窗口ID: \(windowId)")
        }
    }
    
    enum VideoPlayerError: Error {
        case playerCreationFailed
        case layerCreationFailed
        case contentViewLayerMissing
    }
    
    private func setupDualPlayerSystem(with url: URL, in contentView: NSView, scale: CGFloat, offset: CGSize) throws {
        print("[DEBUG] 开始创建双播放器系统 - URL: \(url.lastPathComponent) - 窗口ID: \(windowId)")
        
        if contentView.layer == nil {
            print("[ERROR] contentView没有layer - 窗口ID: \(windowId)")
            contentView.wantsLayer = true
            if contentView.layer == nil {
                print("[ERROR] 无法为contentView创建layer - 窗口ID: \(windowId)")
                throw VideoPlayerError.contentViewLayerMissing
            }
        }
        
        print("[DEBUG] 🎬 创建播放器A - 窗口ID: \(windowId)")
        let playerItemA = AVPlayerItem(url: url)
        playerA = AVPlayer(playerItem: playerItemA)
        
        if let player = playerA {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            print("[LIFECYCLE] ✅ 播放器A创建成功 - 内存地址: \(playerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[ERROR] ❌ 播放器A创建失败 - 窗口ID: \(windowId)")
            throw VideoPlayerError.playerCreationFailed
        }
        
        print("[DEBUG] 🎬 创建播放器B - 窗口ID: \(windowId)")
        let playerItemB = AVPlayerItem(url: url)
        playerB = AVPlayer(playerItem: playerItemB)
        
        if let player = playerB {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            print("[LIFECYCLE] ✅ 播放器B创建成功 - 内存地址: \(playerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[ERROR] ❌ 播放器B创建失败 - 窗口ID: \(windowId)")
            throw VideoPlayerError.playerCreationFailed
        }
        
        print("[DEBUG] 创建播放器层A - 窗口ID: \(windowId)")
        guard let playerA = playerA else {
            print("[ERROR] 播放器A为空，无法创建层 - 窗口ID: \(windowId)")
            throw VideoPlayerError.playerCreationFailed
        }
        
        playerLayerA = AVPlayerLayer(player: playerA)
        
        if let layer = playerLayerA {
            let layerPointer = Unmanaged.passUnretained(layer).toOpaque()
            print("[LIFECYCLE] ✅ 播放器层A创建成功 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[ERROR] ❌ 播放器层A创建失败 - 窗口ID: \(windowId)")
            throw VideoPlayerError.layerCreationFailed
        }
        
        print("[DEBUG] 设置播放器层A的frame: \(contentView.bounds) - 窗口ID: \(windowId)")
        playerLayerA?.frame = contentView.bounds
        playerLayerA?.videoGravity = .resizeAspectFill
        playerLayerA?.opacity = 1.0
        
        applyCropTransform(to: playerLayerA, scale: scale, offset: offset, containerSize: contentView.bounds.size)
        
        print("[DEBUG] 创建播放器层B - 窗口ID: \(windowId)")
        guard let playerB = playerB else {
            print("[ERROR] 播放器B为空，无法创建层 - 窗口ID: \(windowId)")
            throw VideoPlayerError.playerCreationFailed
        }
        
        playerLayerB = AVPlayerLayer(player: playerB)
        
        if let layer = playerLayerB {
            let layerPointer = Unmanaged.passUnretained(layer).toOpaque()
            print("[LIFECYCLE] ✅ 播放器层B创建成功 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[ERROR] ❌ 播放器层B创建失败 - 窗口ID: \(windowId)")
            throw VideoPlayerError.layerCreationFailed
        }
        
        print("[DEBUG] 设置播放器层B的frame: \(contentView.bounds) - 窗口ID: \(windowId)")
        playerLayerB?.frame = contentView.bounds
        playerLayerB?.videoGravity = .resizeAspectFill
        playerLayerB?.opacity = 0.0
        
        applyCropTransform(to: playerLayerB, scale: scale, offset: offset, containerSize: contentView.bounds.size)
        
        print("[DEBUG] 添加播放器层到内容视图 - 窗口ID: \(windowId)")
        guard let contentViewLayer = contentView.layer else {
            print("[ERROR] contentView的layer为空 - 窗口ID: \(windowId)")
            throw VideoPlayerError.contentViewLayerMissing
        }
        
        if let layerA = playerLayerA {
            let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
            contentViewLayer.addSublayer(layerA)
            print("[LIFECYCLE] ✅ 播放器层A已添加到视图 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[ERROR] ❌ 播放器层A为空，无法添加 - 窗口ID: \(windowId)")
            throw VideoPlayerError.layerCreationFailed
        }
        
        if let layerB = playerLayerB {
            let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
            contentViewLayer.addSublayer(layerB)
            print("[LIFECYCLE] ✅ 播放器层B已添加到视图 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[ERROR] ❌ 播放器层B为空，无法添加 - 窗口ID: \(windowId)")
            throw VideoPlayerError.layerCreationFailed
        }
        
        print("[DEBUG] 设置无缝循环观察者 - 窗口ID: \(windowId)")
        setupSeamlessLoopObserver()
        
        print("[INFO] 双播放器系统创建完成 - 窗口ID: \(windowId)")
    }
    
    private func applyCropTransform(to layer: AVPlayerLayer?, scale: CGFloat, offset: CGSize, containerSize: CGSize) {
        guard let layer = layer else { return }
        
        print("[DEBUG] 应用裁剪变换 - 缩放: \(scale), 偏移: \(offset) - 窗口ID: \(windowId)")
        
        var transform = CATransform3DIdentity
        transform = CATransform3DScale(transform, scale, scale, 1.0)
        
        let adjustedOffsetX = offset.width
        let adjustedOffsetY = -offset.height
        transform = CATransform3DTranslate(transform, adjustedOffsetX, adjustedOffsetY, 0)
        
        layer.transform = transform
        
        print("[DEBUG] 裁剪变换已应用到播放器层 - 调整后偏移: (\(adjustedOffsetX), \(adjustedOffsetY)) - 窗口ID: \(windowId)")
    }

    private func setupSeamlessLoopObserver() {
        print("[DEBUG] 开始设置无缝循环观察者 - 窗口ID: \(windowId)")
        
        if let observer = timeObserver {
            print("[DEBUG] 清理旧的时间观察者 - 窗口ID: \(windowId)")
            let currentActivePlayer = isPlayerAActive ? playerA : playerB
            currentActivePlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        guard let activePlayer = isPlayerAActive ? playerA : playerB,
              let activeItem = activePlayer.currentItem else {
            print("[ERROR] 无法设置观察者 - 播放器或播放项为空 - 窗口ID: \(windowId)")
            return
        }
        
        let playerPointer = Unmanaged.passUnretained(activePlayer).toOpaque()
        print("[DEBUG] 活跃播放器: \(isPlayerAActive ? "A" : "B"), 内存地址: \(playerPointer) - 窗口ID: \(windowId)")
        
        let strongPlayerRef = activePlayer
        let strongItemRef = activeItem
        
        strongItemRef.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else {
                    print("[ERROR] self已被释放，无法设置观察者")
                    return
                }
                
                guard self.playerA != nil || self.playerB != nil else {
                    print("[ERROR] 播放器已被清理，取消设置观察者 - 窗口ID: \(self.windowId)")
                    return
                }
                
                print("[DEBUG] 视频资源加载完成，开始设置观察者 - 窗口ID: \(self.windowId)")
                
                var error: NSError?
                let status = strongItemRef.asset.statusOfValue(forKey: "duration", error: &error)
                
                if status == .loaded {
                    let duration = strongItemRef.asset.duration
                    let durationSeconds = CMTimeGetSeconds(duration)
                    
                    print("[DEBUG] 视频时长: \(String(format: "%.1f", durationSeconds))秒 - 窗口ID: \(self.windowId)")
                    
                    let triggerTime = CMTime(seconds: max(0, durationSeconds - self.transitionDuration), preferredTimescale: 600)
                    
                    guard let currentActivePlayer = self.isPlayerAActive ? self.playerA : self.playerB,
                          currentActivePlayer === strongPlayerRef else {
                        print("[ERROR] 播放器已更改或被释放，无法添加观察者 - 窗口ID: \(self.windowId)")
                        return
                    }
                    
                    print("[DEBUG] 添加新的时间观察者 - 窗口ID: \(self.windowId)")
                    let observer = currentActivePlayer.addPeriodicTimeObserver(
                        forInterval: CMTime(seconds: 0.1, preferredTimescale: 600),
                        queue: .main
                    ) { [weak self] time in
                        guard let self = self else { return }
                        
                        guard self.playerA != nil || self.playerB != nil else { return }
                        
                        let currentSeconds = CMTimeGetSeconds(time)
                        let triggerSeconds = CMTimeGetSeconds(triggerTime)
                        
                        if currentSeconds >= triggerSeconds && !self.isTransitioning {
                            self.performSeamlessTransition()
                        }
                    }
                    
                    self.timeObserver = observer
                    let observerPointer = Unmanaged.passUnretained(observer as AnyObject).toOpaque()
                    print("[LIFECYCLE] ✅ 时间观察者创建成功 - 内存地址: \(observerPointer) - 窗口ID: \(self.windowId)")
                    
                    print("🎬 无缝循环观察者设置完成，视频时长: \(String(format: "%.1f", durationSeconds))秒 - 窗口ID: \(self.windowId)")
                } else {
                    print("[ERROR] 无法获取视频时长: \(error?.localizedDescription ?? "未知错误") - 窗口ID: \(self.windowId)")
                }
            }
        }
    }
    
    private func performSeamlessTransition() {
        print("[DEBUG] 准备执行无缝过渡 - 窗口ID: \(windowId)")
        
        guard !isTransitioning else {
            print("[DEBUG] 已在过渡中，跳过 - 窗口ID: \(windowId)")
            return
        }
        
        guard let layerA = playerLayerA,
              let layerB = playerLayerB,
              let playerA = playerA,
              let playerB = playerB else {
            print("[ERROR] 播放器或层为空，无法执行过渡 - 窗口ID: \(windowId)")
            return
        }
        
        isTransitioning = true
        
        if isPlayerAActive {
            print("[DEBUG] 从播放器A切换到播放器B - 窗口ID: \(windowId)")
            playerB.seek(to: .zero)
            playerB.play()
            performTransition(fromLayer: layerA, toLayer: layerB, fromPlayer: playerA, toPlayer: playerB)
        } else {
            print("[DEBUG] 从播放器B切换到播放器A - 窗口ID: \(windowId)")
            playerA.seek(to: .zero)
            playerA.play()
            performTransition(fromLayer: layerB, toLayer: layerA, fromPlayer: playerB, toPlayer: playerA)
        }
    }
    
    private func performTransition(fromLayer: AVPlayerLayer, toLayer: AVPlayerLayer, fromPlayer: AVPlayer, toPlayer: AVPlayer) {
        switch transitionType {
        case .fade:
            performFadeTransition(fromLayer: fromLayer, toLayer: toLayer, fromPlayer: fromPlayer, toPlayer: toPlayer)
        case .blackout:
            performBlackoutTransition(fromLayer: fromLayer, toLayer: toLayer, fromPlayer: fromPlayer, toPlayer: toPlayer)
        }
    }
    
    private func performFadeTransition(fromLayer: AVPlayerLayer, toLayer: AVPlayerLayer, fromPlayer: AVPlayer, toPlayer: AVPlayer) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.completeTransition(fromPlayer: fromPlayer)
        }
        
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = 1.0
        fadeOutAnimation.toValue = 0.0
        fadeOutAnimation.duration = transitionDuration
        fadeOutAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.fromValue = 0.0
        fadeInAnimation.toValue = 1.0
        fadeInAnimation.duration = transitionDuration
        fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        fromLayer.opacity = 0.0
        toLayer.opacity = 1.0
        
        fromLayer.add(fadeOutAnimation, forKey: "fadeOut")
        toLayer.add(fadeInAnimation, forKey: "fadeIn")
        
        CATransaction.commit()
    }
    
    private func performBlackoutTransition(fromLayer: AVPlayerLayer, toLayer: AVPlayerLayer, fromPlayer: AVPlayer, toPlayer: AVPlayer) {
        let halfDuration = transitionDuration / 2
        
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.performBlackoutFadeIn(toLayer: toLayer, fromPlayer: fromPlayer, halfDuration: halfDuration)
        }
        
        let fadeOutAnimation = CABasicAnimation(keyPath: "opacity")
        fadeOutAnimation.fromValue = 1.0
        fadeOutAnimation.toValue = 0.0
        fadeOutAnimation.duration = halfDuration
        fadeOutAnimation.timingFunction = CAMediaTimingFunction(name: .easeIn)
        
        fromLayer.opacity = 0.0
        fromLayer.add(fadeOutAnimation, forKey: "blackoutFadeOut")
        
        CATransaction.commit()
    }
    
    private func performBlackoutFadeIn(toLayer: AVPlayerLayer, fromPlayer: AVPlayer, halfDuration: Double) {
        CATransaction.begin()
        CATransaction.setCompletionBlock { [weak self] in
            self?.completeTransition(fromPlayer: fromPlayer)
        }
        
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.fromValue = 0.0
        fadeInAnimation.toValue = 1.0
        fadeInAnimation.duration = halfDuration
        fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        toLayer.opacity = 1.0
        toLayer.add(fadeInAnimation, forKey: "blackoutFadeIn")
        
        CATransaction.commit()
    }
    
    private func completeTransition(fromPlayer: AVPlayer) {
        print("[DEBUG] 完成过渡 - 窗口ID: \(windowId)")
        
        // 安全地移除时间观察者
        if let observer = timeObserver {
            print("[DEBUG] 移除时间观察者 - 窗口ID: \(windowId)")
            let fromPlayerPointer = Unmanaged.passUnretained(fromPlayer).toOpaque()
            print("[DEBUG] 从播放器移除观察者 - 内存地址: \(fromPlayerPointer) - 窗口ID: \(windowId)")
            fromPlayer.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        // 暂停旧播放器
        print("[DEBUG] 暂停旧播放器 - 窗口ID: \(windowId)")
        fromPlayer.pause()
        
        // 切换活跃播放器
        isPlayerAActive.toggle()
        print("[DEBUG] 切换到播放器: \(isPlayerAActive ? "A" : "B") - 窗口ID: \(windowId)")
        
        // 重新设置观察者
        print("[DEBUG] 重新设置观察者 - 窗口ID: \(windowId)")
        setupSeamlessLoopObserver()
        
        // 重置过渡标志
        isTransitioning = false
        
        print("✅ 无缝过渡效果完成 - 窗口ID: \(windowId)")
    }
    
    func playVideo() {
        if isPlayerAActive {
            playerA?.play()
        } else {
            playerB?.play()
        }
    }
    
    func pauseVideo() {
        playerA?.pause()
        playerB?.pause()
    }
    
    func stopVideo() {
        playerA?.pause()
        playerB?.pause()
        playerA?.seek(to: .zero)
        playerB?.seek(to: .zero)
    }
    
    private var isCleaningUp = false
    
    private func cleanupVideoPlayerAsync(completion: @escaping () -> Void) {
        let cleanupId = UUID().uuidString
        print("[INFO] [\(cleanupId)] 开始异步安全清理视频播放器资源 - 窗口ID: \(windowId)")
        
        print("[LIFECYCLE] === 清理前的对象状态 ===")
        detectDanglingPointers()
        checkObjectValidity()
        trackObjectLifecycle()
        
        let currentPlayerA = playerA
        let currentPlayerB = playerB
        let currentObserver = timeObserver
        let currentLayerA = playerLayerA
        let currentLayerB = playerLayerB
        let isPlayerA = isPlayerAActive
        
        print("[LIFECYCLE] 🗑️ 开始清除所有引用 - 窗口ID: \(windowId)")
        timeObserver = nil
        playerA = nil
        playerB = nil
        playerLayerA = nil
        playerLayerB = nil
        currentVideoURL = nil
        isPlayerAActive = true
        isTransitioning = false
        print("[LIFECYCLE] ✅ 所有引用已清除 - 窗口ID: \(windowId)")
        
        cleanupStep1_StopPlayers(
            playerA: currentPlayerA,
            playerB: currentPlayerB,
            cleanupId: cleanupId
        ) { [weak self] in
            self?.cleanupStep2_RemoveObserver(
                observer: currentObserver,
                playerA: currentPlayerA,
                playerB: currentPlayerB,
                isPlayerA: isPlayerA,
                cleanupId: cleanupId
            ) { [weak self] in
                self?.cleanupStep3_RemoveLayers(
                    layerA: currentLayerA,
                    layerB: currentLayerB,
                    cleanupId: cleanupId
                ) { [weak self] in
                    self?.cleanupStep4_FinalCleanup(cleanupId: cleanupId, completion: completion)
                }
            }
        }
    }
    
    private func cleanupStep1_StopPlayers(
        playerA: AVPlayer?,
        playerB: AVPlayer?,
        cleanupId: String,
        completion: @escaping () -> Void
    ) {
        print("[DEBUG] [\(cleanupId)] 步骤1: 停止播放器 - 窗口ID: \(windowId)")
        
        if let player = playerA {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            print("[DEBUG] [\(cleanupId)] 暂停播放器A - 内存地址: \(playerPointer) - 窗口ID: \(windowId)")
            player.pause()
        }
        
        if let player = playerB {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            print("[DEBUG] [\(cleanupId)] 暂停播放器B - 内存地址: \(playerPointer) - 窗口ID: \(windowId)")
            player.pause()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            print("[DEBUG] [\(cleanupId)] 步骤1完成 - 窗口ID: \(self.windowId)")
            completion()
        }
    }
    
    private func cleanupStep2_RemoveObserver(
        observer: Any?,
        playerA: AVPlayer?,
        playerB: AVPlayer?,
        isPlayerA: Bool,
        cleanupId: String,
        completion: @escaping () -> Void
    ) {
        print("[DEBUG] [\(cleanupId)] 步骤2: 移除时间观察者 - 窗口ID: \(windowId)")
        
        if let timeObserver = observer {
            let observerPointer = Unmanaged.passUnretained(timeObserver as AnyObject).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎯 准备移除时间观察者 - 内存地址: \(observerPointer) - 窗口ID: \(windowId)")
            
            do {
                if isPlayerA, let player = playerA {
                    let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                    print("[DEBUG] [\(cleanupId)] 🎯 从播放器A移除观察者 - 播放器地址: \(playerPointer), 观察者地址: \(observerPointer) - 窗口ID: \(windowId)")
                    player.removeTimeObserver(timeObserver)
                    print("[LIFECYCLE] ✅ 观察者已从播放器A移除 - 窗口ID: \(windowId)")
                } else if let player = playerB {
                    let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                    print("[DEBUG] [\(cleanupId)] 🎯 从播放器B移除观察者 - 播放器地址: \(playerPointer), 观察者地址: \(observerPointer) - 窗口ID: \(windowId)")
                    player.removeTimeObserver(timeObserver)
                    print("[LIFECYCLE] ✅ 观察者已从播放器B移除 - 窗口ID: \(windowId)")
                }
                print("[INFO] [\(cleanupId)] ✅ 时间观察者移除完成 - 窗口ID: \(windowId)")
            } catch {
                print("[ERROR] [\(cleanupId)] ❌ 移除时间观察者时发生错误: \(error) - 窗口ID: \(windowId)")
            }
        } else {
            print("[DEBUG] [\(cleanupId)] 没有时间观察者需要移除 - 窗口ID: \(windowId)")
        }
        
        print("[DEBUG] [\(cleanupId)] 步骤2完成 - 窗口ID: \(windowId)")
        completion()
    }
    
    // 步骤3：安全移除播放器层（关键修复点）
    private func cleanupStep3_RemoveLayers(
        layerA: AVPlayerLayer?,
        layerB: AVPlayerLayer?,
        cleanupId: String,
        completion: @escaping () -> Void
    ) {
        print("[DEBUG] [\(cleanupId)] 步骤3: 安全移除播放器层 - 窗口ID: \(windowId)")
        
        // 使用 CATransaction 确保层移除操作的原子性
        CATransaction.begin()
        CATransaction.setDisableActions(true) // 禁用动画，避免异步操作
        
        if let layerA = layerA {
            let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎬 移除播放器层A - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
            
            // 先设置 player 为 nil，断开与播放器的连接
            layerA.player = nil
            
            // 然后移除层
            layerA.removeFromSuperlayer()
            print("[LIFECYCLE] ✅ 播放器层A已从父层移除 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[DEBUG] [\(cleanupId)] 播放器层A为空，无需移除 - 窗口ID: \(windowId)")
        }
        
        if let layerB = layerB {
            let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎬 移除播放器层B - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
            
            // 先设置 player 为 nil，断开与播放器的连接
            layerB.player = nil
            
            // 然后移除层
            layerB.removeFromSuperlayer()
            print("[LIFECYCLE] ✅ 播放器层B已从父层移除 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[DEBUG] [\(cleanupId)] 播放器层B为空，无需移除 - 窗口ID: \(windowId)")
        }
        
        // 提交事务并等待完成
        CATransaction.commit()
        
        // 等待 Core Animation 完成所有操作
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            print("[DEBUG] [\(cleanupId)] 步骤3完成 - Core Animation 操作已完成 - 窗口ID: \(self.windowId)")
            completion()
        }
    }
    
    // 步骤4：最终清理
    private func cleanupStep4_FinalCleanup(cleanupId: String, completion: @escaping () -> Void) {
        print("[DEBUG] [\(cleanupId)] 步骤4: 最终清理 - 窗口ID: \(windowId)")
        
        // 跟踪清理后的对象状态
        print("[LIFECYCLE] === 清理后的对象状态 ===")
        trackObjectLifecycle()
        
        print("[INFO] [\(cleanupId)] 异步安全清理视频播放器资源完成 - 窗口ID: \(windowId)")
        completion()
    }
    
    // 保留同步清理方法作为备用（简化版本）
    private func cleanupVideoPlayerSync() {
        let cleanupId = UUID().uuidString
        print("[INFO] [\(cleanupId)] 开始同步清理视频播放器资源 - 窗口ID: \(windowId)")
        
        // 保存当前引用，避免在清理过程中被修改
        let currentPlayerA = playerA
        let currentPlayerB = playerB
        let currentObserver = timeObserver
        let currentLayerA = playerLayerA
        let currentLayerB = playerLayerB
        let isPlayerA = isPlayerAActive
        
        // 立即清除引用，防止其他地方继续使用
        print("[LIFECYCLE] 🗑️ 开始清除所有引用 - 窗口ID: \(windowId)")
        
        if timeObserver != nil {
            print("[LIFECYCLE] 🗑️ 清除timeObserver引用 - 窗口ID: \(windowId)")
            timeObserver = nil
        }
        
        if playerA != nil {
            print("[LIFECYCLE] 🗑️ 清除playerA引用 - 窗口ID: \(windowId)")
            playerA = nil
        }
        
        if playerB != nil {
            print("[LIFECYCLE] 🗑️ 清除playerB引用 - 窗口ID: \(windowId)")
            playerB = nil
        }
        
        if playerLayerA != nil {
            print("[LIFECYCLE] 🗑️ 清除playerLayerA引用 - 窗口ID: \(windowId)")
            playerLayerA = nil
        }
        
        if playerLayerB != nil {
            print("[LIFECYCLE] 🗑️ 清除playerLayerB引用 - 窗口ID: \(windowId)")
            playerLayerB = nil
        }
        
        currentVideoURL = nil
        isPlayerAActive = true
        isTransitioning = false
        
        print("[LIFECYCLE] ✅ 所有引用已清除 - 窗口ID: \(windowId)")
        
        // 停止播放器
        if let player = currentPlayerA {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            print("[DEBUG] [\(cleanupId)] 暂停播放器A - 内存地址: \(playerPointer) - 窗口ID: \(windowId)")
            player.pause()
        }
        
        if let player = currentPlayerB {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            print("[DEBUG] [\(cleanupId)] 暂停播放器B - 内存地址: \(playerPointer) - 窗口ID: \(windowId)")
            player.pause()
        }
        
        // 移除时间观察者
        if let observer = currentObserver {
            let observerPointer = Unmanaged.passUnretained(observer as AnyObject).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎯 准备移除时间观察者 - 内存地址: \(observerPointer) - 窗口ID: \(windowId)")
            
            do {
                if isPlayerA, let player = currentPlayerA {
                    let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                    print("[DEBUG] [\(cleanupId)] 🎯 从播放器A移除观察者 - 播放器地址: \(playerPointer), 观察者地址: \(observerPointer) - 窗口ID: \(windowId)")
                    player.removeTimeObserver(observer)
                    print("[LIFECYCLE] ✅ 观察者已从播放器A移除 - 窗口ID: \(windowId)")
                } else if let player = currentPlayerB {
                    let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                    print("[DEBUG] [\(cleanupId)] 🎯 从播放器B移除观察者 - 播放器地址: \(playerPointer), 观察者地址: \(observerPointer) - 窗口ID: \(windowId)")
                    player.removeTimeObserver(observer)
                    print("[LIFECYCLE] ✅ 观察者已从播放器B移除 - 窗口ID: \(windowId)")
                }
                print("[INFO] [\(cleanupId)] ✅ 时间观察者移除完成 - 窗口ID: \(windowId)")
            } catch {
                print("[ERROR] [\(cleanupId)] ❌ 移除时间观察者时发生错误: \(error) - 窗口ID: \(windowId)")
            }
        } else {
            print("[DEBUG] [\(cleanupId)] 没有时间观察者需要移除 - 窗口ID: \(windowId)")
        }
        
        // 移除播放器层
        if let layerA = currentLayerA {
            let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎬 移除播放器层A - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
            
            do {
                layerA.removeFromSuperlayer()
                print("[LIFECYCLE] ✅ 播放器层A已从父层移除 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
            } catch {
                print("[ERROR] [\(cleanupId)] ❌ 移除播放器层A时发生错误: \(error) - 窗口ID: \(windowId)")
            }
        } else {
            print("[DEBUG] [\(cleanupId)] 播放器层A为空，无需移除 - 窗口ID: \(windowId)")
        }
        
        if let layerB = currentLayerB {
            let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎬 移除播放器层B - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
            
            do {
                layerB.removeFromSuperlayer()
                print("[LIFECYCLE] ✅ 播放器层B已从父层移除 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
            } catch {
                print("[ERROR] [\(cleanupId)] ❌ 移除播放器层B时发生错误: \(error) - 窗口ID: \(windowId)")
            }
        } else {
            print("[DEBUG] [\(cleanupId)] 播放器层B为空，无需移除 - 窗口ID: \(windowId)")
        }
        
        print("[INFO] [\(cleanupId)] 同���清理视频播放器资源完成 - 窗口ID: \(windowId)")
    }
    
    private func cleanupVideoPlayer() {
        let cleanupId = UUID().uuidString
        
        // 如果已经在清理过程中，直接返回
        if isCleaningUp {
            print("[DEBUG] [\(cleanupId)] 已经在清理视频播放器资源过程中，忽略重复调用 - 窗口ID: \(windowId)")
            return
        }
        
        print("[INFO] [\(cleanupId)] 开始清理视频播放器资源 - 窗口ID: \(windowId)")
        isCleaningUp = true
        
        // 在主线程上执行清理操作
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                print("[ERROR] [\(cleanupId)] self已被释放，无法清理视频播放器资源")
                return
            }
            
            print("[DEBUG] [\(cleanupId)] 在主线程上执行清理操作 - 窗口ID: \(self.windowId)")
            
            // 停止播放器
            if let player = self.playerA {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                print("[DEBUG] [\(cleanupId)] 暂停播放器A - 内存地址: \(playerPointer) - 窗口ID: \(self.windowId)")
                player.pause()
            } else {
                print("[DEBUG] [\(cleanupId)] 播放器A为空 - 窗口ID: \(self.windowId)")
            }
            
            if let player = self.playerB {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                print("[DEBUG] [\(cleanupId)] 暂停播放器B - 内存地址: \(playerPointer) - 窗口ID: \(self.windowId)")
                player.pause()
            } else {
                print("[DEBUG] [\(cleanupId)] 播放器B为空 - 窗口ID: \(self.windowId)")
            }
            
            // 保存当前的观察者和播放器引用
            print("[DEBUG] [\(cleanupId)] 保存当前观察者和播放器引用 - 窗口ID: \(self.windowId)")
            let currentObserver = self.timeObserver
            let currentPlayerA = self.playerA
            let currentPlayerB = self.playerB
            let isPlayerA = self.isPlayerAActive
            
            // 记录当前状态
            print("[DEBUG] [\(cleanupId)] 当前活跃播放器: \(isPlayerA ? "A" : "B") - 窗口ID: \(self.windowId)")
            print("[DEBUG] [\(cleanupId)] 当前是否有时间观察者: \(currentObserver != nil ? "是" : "否") - 窗口ID: \(self.windowId)")
            
            // 移除时间观察者
            if let observer = currentObserver {
                print("[DEBUG] [\(cleanupId)] 准备移除时间观察者 - 窗口ID: \(self.windowId)")
                
                do {
                    if isPlayerA, let player = currentPlayerA {
                        let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                        print("[DEBUG] [\(cleanupId)] 从播放器A移除观察者 - 内存地址: \(playerPointer) - 窗口ID: \(self.windowId)")
                        player.removeTimeObserver(observer)
                    } else if let player = currentPlayerB {
                        let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                        print("[DEBUG] [\(cleanupId)] 从播放器B移除观察者 - 内存地址: \(playerPointer) - 窗口ID: \(self.windowId)")
                        player.removeTimeObserver(observer)
                    }
                    print("[INFO] [\(cleanupId)] 时间观察者已移除 - 窗口ID: \(self.windowId)")
                } catch {
                    print("[ERROR] [\(cleanupId)] 移除时间观察者时发生错误: \(error) - 窗口ID: \(self.windowId)")
                }
            } else {
                print("[DEBUG] [\(cleanupId)] 没有时间观察者需要移除 - 窗口ID: \(self.windowId)")
            }
            
            // 移除播放器层
            if let layerA = self.playerLayerA {
                let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
                print("[DEBUG] [\(cleanupId)] 移除播放器层A - 内存地址: \(layerPointer) - 窗口ID: \(self.windowId)")
                
                do {
                    layerA.removeFromSuperlayer()
                    print("[DEBUG] [\(cleanupId)] 播放器层A已移除 - 窗口ID: \(self.windowId)")
                } catch {
                    print("[ERROR] [\(cleanupId)] 移除播放器层A时发生错误: \(error) - 窗口ID: \(self.windowId)")
                }
            } else {
                print("[DEBUG] [\(cleanupId)] 播放器层A为空 - 窗口ID: \(self.windowId)")
            }
            
            if let layerB = self.playerLayerB {
                let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
                print("[DEBUG] [\(cleanupId)] 移除播放器层B - 内存地址: \(layerPointer) - 窗口ID: \(self.windowId)")
                
                do {
                    layerB.removeFromSuperlayer()
                    print("[DEBUG] [\(cleanupId)] 播放器层B已移除 - 窗口ID: \(self.windowId)")
                } catch {
                    print("[ERROR] [\(cleanupId)] 移除播放器层B时发生错误: \(error) - 窗口ID: \(self.windowId)")
                }
            } else {
                print("[DEBUG] [\(cleanupId)] 播放器层B为空 - 窗口ID: \(self.windowId)")
            }
            
            // 清除引用
            print("[DEBUG] [\(cleanupId)] 清除所有引用 - 窗口ID: \(self.windowId)")
            self.timeObserver = nil
            self.playerA = nil
            self.playerB = nil
            self.playerLayerA = nil
            self.playerLayerB = nil
            self.currentVideoURL = nil
            self.isPlayerAActive = true
            self.isTransitioning = false
            
            // 重置清理标志
            self.isCleaningUp = false
            
            print("[INFO] [\(cleanupId)] 清理视频播放器资源完成 - 窗口ID: \(self.windowId)")
        }
    }
    
    // 添加内存监控方法
    private func logMemoryUsage(context: String) {
        let task = mach_task_self_
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsage = info.resident_size / 1024 / 1024 // MB
            print("[MEMORY] \(context) - 内存使用: \(memoryUsage) MB - 窗口ID: \(windowId)")
        } else {
            print("[MEMORY] \(context) - 无法获取内存信息 - 窗口ID: \(windowId)")
        }
    }
    
    // 添加对象引用计数监控
    private func logObjectRetainCount<T: AnyObject>(_ object: T?, name: String) {
        guard let obj = object else {
            print("[RETAIN_COUNT] \(name): nil - 窗口ID: \(windowId)")
            return
        }
        
        // 安全地检查对象是否仍然有效
        do {
            let retainCount = CFGetRetainCount(obj)
            let pointer = Unmanaged.passUnretained(obj).toOpaque()
            print("[RETAIN_COUNT] \(name): \(retainCount), 内存地址: \(pointer) - 窗口ID: \(windowId)")
            
            // 额外的安全检查
            if retainCount <= 0 {
                print("[RETAIN_COUNT] ⚠️ 警告: \(name) 引用计数异常: \(retainCount) - 窗口ID: \(windowId)")
            }
        } catch {
            print("[RETAIN_COUNT] ❌ 错误: 无法访问 \(name) 对象 - 可能已被释放 - 窗口ID: \(windowId)")
        }
    }
    
    // 添加对象有效性检查
    private func checkObjectValidity() {
        print("[OBJECT_VALIDITY] === 对象有效性检查开始 - 窗口ID: \(windowId) ===")
        
        // 检查播放器A
        if let player = playerA {
            let pointer = Unmanaged.passUnretained(player).toOpaque()
            print("[OBJECT_VALIDITY] playerA 存在 - 内存地址: \(pointer)")
            
            // 尝试安全访问播放器属性
            do {
                let rate = player.rate
                print("[OBJECT_VALIDITY] playerA.rate: \(rate)")
            } catch {
                print("[OBJECT_VALIDITY] ❌ playerA 访问失败: \(error)")
            }
        } else {
            print("[OBJECT_VALIDITY] playerA: nil")
        }
        
        // 检查播放器B
        if let player = playerB {
            let pointer = Unmanaged.passUnretained(player).toOpaque()
            print("[OBJECT_VALIDITY] playerB 存在 - 内存地址: \(pointer)")
            
            do {
                let rate = player.rate
                print("[OBJECT_VALIDITY] playerB.rate: \(rate)")
            } catch {
                print("[OBJECT_VALIDITY] ❌ playerB 访问失败: \(error)")
            }
        } else {
            print("[OBJECT_VALIDITY] playerB: nil")
        }
        
        // 检查播放器层
        if let layer = playerLayerA {
            let pointer = Unmanaged.passUnretained(layer).toOpaque()
            print("[OBJECT_VALIDITY] playerLayerA 存在 - 内存地址: \(pointer)")
        } else {
            print("[OBJECT_VALIDITY] playerLayerA: nil")
        }
        
        if let layer = playerLayerB {
            let pointer = Unmanaged.passUnretained(layer).toOpaque()
            print("[OBJECT_VALIDITY] playerLayerB 存在 - 内存地址: \(pointer)")
        } else {
            print("[OBJECT_VALIDITY] playerLayerB: nil")
        }
        
        print("[OBJECT_VALIDITY] === 对象有效性检查结束 ===")
    }
    
    // 添加悬空指针检测
    private func detectDanglingPointers() {
        print("[DANGLING_POINTER] === 悬空指针检测开始 - 窗口ID: \(windowId) ===")
        
        // 检查是否有对象引用但实际已被释放
        if playerA != nil {
            do {
                let _ = playerA?.rate
                print("[DANGLING_POINTER] playerA 访问正常")
            } catch {
                print("[DANGLING_POINTER] ❌ playerA 可能是悬空指针: \(error)")
            }
        }
        
        if playerB != nil {
            do {
                let _ = playerB?.rate
                print("[DANGLING_POINTER] playerB 访问正常")
            } catch {
                print("[DANGLING_POINTER] ❌ playerB 可能是悬空指针: \(error)")
            }
        }
        
        if playerLayerA != nil {
            do {
                let _ = playerLayerA?.bounds
                print("[DANGLING_POINTER] playerLayerA 访问正常")
            } catch {
                print("[DANGLING_POINTER] ❌ playerLayerA 可能是悬空指针: \(error)")
            }
        }
        
        if playerLayerB != nil {
            do {
                let _ = playerLayerB?.bounds
                print("[DANGLING_POINTER] playerLayerB 访问正常")
            } catch {
                print("[DANGLING_POINTER] ❌ playerLayerB 可能是悬空指针: \(error)")
            }
        }
        
        print("[DANGLING_POINTER] === 悬空指针检测结束 ===")
    }
    
    // 添加详细的对象生命周期跟踪
    private func trackObjectLifecycle() {
        print("[LIFECYCLE_TRACK] === 对象生命周期跟踪 - 窗口ID: \(windowId) ===")
        
        logObjectRetainCount(playerA, name: "playerA")
        logObjectRetainCount(playerB, name: "playerB")
        logObjectRetainCount(playerLayerA, name: "playerLayerA")
        logObjectRetainCount(playerLayerB, name: "playerLayerB")
        
        if let observer = timeObserver {
            let pointer = Unmanaged.passUnretained(observer as AnyObject).toOpaque()
            print("[LIFECYCLE_TRACK] timeObserver: 存在, 内存地址: \(pointer) - 窗口ID: \(windowId)")
        } else {
            print("[LIFECYCLE_TRACK] timeObserver: nil - 窗口ID: \(windowId)")
        }
        
        logMemoryUsage(context: "对象生命周期跟踪")
        print("[LIFECYCLE_TRACK] === 跟踪结束 ===")
    }
    
    // 添加防护标志
    private var isClosing = false
    private var isBeingClosed = false
    
    override func close() {
        // 如果已经在关闭过程中，直接返回
        if isClosing {
            print("[DEBUG] 已经在关闭窗口过程中，忽略重复调用 - 窗口ID: \(windowId)")
            return
        }
        
        print("[INFO] 开始安全关闭窗口 - 窗口ID: \(windowId)")
        isClosing = true
        isBeingClosed = true // 设置防护标志
        
        // 立即停止所有播放器活动
        print("[DEBUG] 立即停止所有播放器活动 - 窗口ID: \(windowId)")
        playerA?.pause()
        playerB?.pause()
        
        // 使用延迟清理，给 AVFoundation 和 CoreAnimation 足够时间
        print("[DEBUG] 开始延迟安全清理播放器资源 - 窗口ID: \(windowId)")
        cleanupVideoPlayerWithDelay { [weak self] in
            guard let self = self else {
                print("[WARNING] 窗口已被释放，无法完成关闭")
                return
            }
            
            print("[DEBUG] 延迟清理完成，现在安全关闭窗口 - 窗口ID: \(self.windowId)")
            
            // 在主线程上关闭窗口
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                print("[DEBUG] 调用关闭方法 - 窗口ID: \(self.windowId)")
                // 不能在闭包中使用super，直接关闭窗口
                self.performClose(nil)
                print("[INFO] 窗口已安全关闭 - 窗口ID: \(self.windowId)")
            }
        }
    }
    
    // 改进的同步安全清理方法
    private func cleanupVideoPlayerSyncSafe() {
        let cleanupId = UUID().uuidString
        print("[INFO] [\(cleanupId)] 开始同步安全清理视频播放器资源 - 窗口ID: \(windowId)")
        
        // 跟踪清理前的对象状态
        print("[LIFECYCLE] === 清理前的对象状态 ===")
        detectDanglingPointers()
        checkObjectValidity()
        trackObjectLifecycle()
        
        // 保存当前引用，避免在清理过程中被修改
        let currentPlayerA = playerA
        let currentPlayerB = playerB
        let currentObserver = timeObserver
        let currentLayerA = playerLayerA
        let currentLayerB = playerLayerB
        let isPlayerA = isPlayerAActive
        
        // 立即清除引用，防止其他地方继续使用
        print("[LIFECYCLE] 🗑️ 开始清除所有引用 - 窗口ID: \(windowId)")
        timeObserver = nil
        playerA = nil
        playerB = nil
        playerLayerA = nil
        playerLayerB = nil
        currentVideoURL = nil
        isPlayerAActive = true
        isTransitioning = false
        print("[LIFECYCLE] ✅ 所有引用已清除 - 窗口ID: \(windowId)")
        
        // 停止播放器
        if let player = currentPlayerA {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            print("[DEBUG] [\(cleanupId)] 暂停播放器A - 内存地址: \(playerPointer) - 窗口ID: \(windowId)")
            player.pause()
        }
        
        if let player = currentPlayerB {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            print("[DEBUG] [\(cleanupId)] 暂停播放器B - 内存地址: \(playerPointer) - 窗口ID: \(windowId)")
            player.pause()
        }
        
        // 移除时间观察者
        if let observer = currentObserver {
            let observerPointer = Unmanaged.passUnretained(observer as AnyObject).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎯 准备移除时间观察者 - 内存地址: \(observerPointer) - 窗口ID: \(windowId)")
            
            if isPlayerA, let player = currentPlayerA {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                print("[DEBUG] [\(cleanupId)] 🎯 从播放器A移除观察者 - 播放器地址: \(playerPointer), 观察者地址: \(observerPointer) - 窗口ID: \(windowId)")
                player.removeTimeObserver(observer)
                print("[LIFECYCLE] ✅ 观察者已从播放器A移除 - 窗口ID: \(windowId)")
            } else if let player = currentPlayerB {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                print("[DEBUG] [\(cleanupId)] 🎯 从播放器B移除观察者 - 播放器地址: \(playerPointer), 观察者地址: \(observerPointer) - 窗口ID: \(windowId)")
                player.removeTimeObserver(observer)
                print("[LIFECYCLE] ✅ 观察者已从播放器B移除 - 窗口ID: \(windowId)")
            }
            print("[INFO] [\(cleanupId)] ✅ 时间观察者移除完成 - 窗口ID: \(windowId)")
        } else {
            print("[DEBUG] [\(cleanupId)] 没有时间观察者需要移除 - 窗口ID: \(windowId)")
        }
        
        // 安全移除播放器层（关键修复点）
        CATransaction.begin()
        CATransaction.setDisableActions(true) // 禁用动画，避免异步操作
        
        if let layerA = currentLayerA {
            let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎬 安全移除播放器层A - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
            
            // 先设置 player 为 nil，断开与播放器的连接
            layerA.player = nil
            
            // 然后移除层
            layerA.removeFromSuperlayer()
            print("[LIFECYCLE] ✅ 播放器层A已从父层移除 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[DEBUG] [\(cleanupId)] 播放器层A为空，无需移除 - 窗口ID: \(windowId)")
        }
        
        if let layerB = currentLayerB {
            let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎬 安全移除播放器层B - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
            
            // 先设置 player 为 nil，断开与播放器的连接
            layerB.player = nil
            
            // 然后移除层
            layerB.removeFromSuperlayer()
            print("[LIFECYCLE] ✅ 播放器层B已从父层移除 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[DEBUG] [\(cleanupId)] 播放器层B为空，无需移除 - 窗口ID: \(windowId)")
        }
        
        // 提交事务
        CATransaction.commit()
        
        // 跟踪清理后的对象状态
        print("[LIFECYCLE] === 清理后的对象状态 ===")
        trackObjectLifecycle()
        
        print("[INFO] [\(cleanupId)] 同步安全清理视频播放器资源完成 - 窗口ID: \(windowId)")
    }
    
    // 延迟清理方法 - 关键修复点
    private func cleanupVideoPlayerWithDelay(completion: @escaping () -> Void) {
        let cleanupId = UUID().uuidString
        print("[INFO] [\(cleanupId)] 开始延迟安全清理视频播放器资源 - 窗口ID: \(windowId)")
        
        // 跟踪清理前的对象状态
        print("[LIFECYCLE] === 延迟清理前的对象状态 ===")
        detectDanglingPointers()
        checkObjectValidity()
        trackObjectLifecycle()
        
        // 保存当前引用，避免在清理过程中被修改
        let currentPlayerA = playerA
        let currentPlayerB = playerB
        let currentObserver = timeObserver
        let currentLayerA = playerLayerA
        let currentLayerB = playerLayerB
        let isPlayerA = isPlayerAActive
        
        // 第一步：移除时间观察者（立即执行）
        if let observer = currentObserver {
            let observerPointer = Unmanaged.passUnretained(observer as AnyObject).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎯 准备移除时间观察者 - 内存地址: \(observerPointer) - 窗口ID: \(windowId)")
            
            if isPlayerA, let player = currentPlayerA {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                print("[DEBUG] [\(cleanupId)] 🎯 从播放器A移除观察者 - 播放器地址: \(playerPointer), 观察者地址: \(observerPointer) - 窗口ID: \(windowId)")
                player.removeTimeObserver(observer)
                print("[LIFECYCLE] ✅ 观察者已从播放器A移除 - 窗口ID: \(windowId)")
            } else if let player = currentPlayerB {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                print("[DEBUG] [\(cleanupId)] 🎯 从播放器B移除观察者 - 播放器地址: \(playerPointer), 观察者地址: \(observerPointer) - 窗口ID: \(windowId)")
                player.removeTimeObserver(observer)
                print("[LIFECYCLE] ✅ 观察者已从播放器B移除 - 窗口ID: \(windowId)")
            }
            
            // 立即清除观察者引用
            timeObserver = nil
            print("[INFO] [\(cleanupId)] ✅ 时间观察者移除完成 - 窗口ID: \(windowId)")
        } else {
            print("[DEBUG] [\(cleanupId)] 没有时间观察者需要移除 - 窗口ID: \(windowId)")
        }
        
        // 第二步：使用 CATransaction 安全移除播放器层
        print("[DEBUG] [\(cleanupId)] 开始 CATransaction 安全移除播放器层 - 窗口ID: \(windowId)")
        
        CATransaction.begin()
        CATransaction.setDisableActions(true) // 禁用动画，避免异步操作
        
        // 设置完成回调
        CATransaction.setCompletionBlock { [weak self] in
            print("[DEBUG] [\(cleanupId)] CATransaction 完成回调执行 - 窗口ID: \(self?.windowId ?? "unknown")")
            
            // 第三步：延迟清除播放器引用，给 AVFoundation 更多时间
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else {
                    print("[WARNING] [\(cleanupId)] 窗口已被释放，跳过播放器引用清理")
                    completion()
                    return
                }
                
                print("[DEBUG] [\(cleanupId)] 延迟清除播放器引用 - 窗口ID: \(self.windowId)")
                
                // 清除播放器引用
                self.playerA = nil
                self.playerB = nil
                self.playerLayerA = nil
                self.playerLayerB = nil
                self.currentVideoURL = nil
                self.isPlayerAActive = true
                self.isTransitioning = false
                
                print("[LIFECYCLE] ✅ 所有引用已延迟清除 - 窗口ID: \(self.windowId)")
                
                // 跟踪清理后的对象状态
                print("[LIFECYCLE] === 延迟清理后的对象状态 ===")
                self.trackObjectLifecycle()
                
                print("[INFO] [\(cleanupId)] 延迟安全清理视频播放器资源完成 - 窗口ID: \(self.windowId)")
                completion()
            }
        }
        
        // 安全移除播放器层
        if let layerA = currentLayerA {
            let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎬 CATransaction 中安全移除播放器层A - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
            
            // 先断开与播放器的连接
            layerA.player = nil
            
            // 然后移除层
            layerA.removeFromSuperlayer()
            print("[LIFECYCLE] ✅ 播放器层A已在 CATransaction 中移除 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[DEBUG] [\(cleanupId)] 播放器层A为空，无需移除 - 窗口ID: \(windowId)")
        }
        
        if let layerB = currentLayerB {
            let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
            print("[DEBUG] [\(cleanupId)] 🎬 CATransaction 中安全移除播放器层B - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
            
            // 先断开与播放器的连接
            layerB.player = nil
            
            // 然后移除层
            layerB.removeFromSuperlayer()
            print("[LIFECYCLE] ✅ 播放器层B已在 CATransaction 中移除 - 内存地址: \(layerPointer) - 窗口ID: \(windowId)")
        } else {
            print("[DEBUG] [\(cleanupId)] 播放器层B为空，无需移除 - 窗口ID: \(windowId)")
        }
        
        // 提交事务（这将触发完成回调）
        CATransaction.commit()
        print("[DEBUG] [\(cleanupId)] CATransaction 已提交 - 窗口ID: \(windowId)")
    }
}

class FluxwallWallpaperManager: ObservableObject {
    static let shared = FluxwallWallpaperManager()
    
    @Published var isVideoActive = false
    @Published var currentWallpaperName = LocalizedStrings.current.systemDefault
    @Published var isVideoPaused = false
    
    private var desktopWindows: [CGDirectDisplayID: DesktopOverlayWindow] = [:]
    private var currentVideoURL: URL?
    private var currentImageURL: URL?
    
    init() {
    }
    
    deinit {
        print("[LIFECYCLE] ⚠️ FluxwallWallpaperManager 析构开始")
        
        if !desktopWindows.isEmpty {
            print("[LIFECYCLE] ⚠️ 析构时发现\(desktopWindows.count)个desktopWindow未清理")
        }
        if currentVideoURL != nil {
            print("[LIFECYCLE] ⚠️ 析构时发现currentVideoURL未清理")
        }
        if currentImageURL != nil {
            print("[LIFECYCLE] ⚠️ 析构时发现currentImageURL未清理")
        }
        
        print("[LIFECYCLE] ✅ FluxwallWallpaperManager 析构完成")
    }
    
    private func logManagerMemoryUsage(context: String, operationId: String) {
        let task = mach_task_self_
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(task, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            let memoryUsage = info.resident_size / 1024 / 1024
            print("[MEMORY] [\(operationId)] \(context) - 内存使用: \(memoryUsage) MB")
        } else {
            print("[MEMORY] [\(operationId)] \(context) - 无法获取内存信息")
        }
    }
    
    private func logWindowObjectState(_ window: DesktopOverlayWindow, context: String, operationId: String) {
        let windowId = ObjectIdentifier(window).hashValue
        let windowPointer = Unmanaged.passUnretained(window).toOpaque()
        
        print("[WINDOW_STATE] [\(operationId)] \(context) - 窗口ID: \(windowId), 内存地址: \(windowPointer)")
        print("[WINDOW_STATE] [\(operationId)] 窗口是否可见: \(window.isVisible)")
        print("[WINDOW_STATE] [\(operationId)] 窗口层级: \(window.level.rawValue)")
        print("[WINDOW_STATE] [\(operationId)] 窗口frame: \(window.frame)")
    }
    
    // 管理器状态跟踪
    private func logManagerState(context: String, operationId: String) {
        print("[MANAGER_STATE] [\(operationId)] \(context)")
        print("[MANAGER_STATE] [\(operationId)] isVideoActive: \(isVideoActive)")
        print("[MANAGER_STATE] [\(operationId)] isVideoPaused: \(isVideoPaused)")
        print("[MANAGER_STATE] [\(operationId)] currentWallpaperName: \(currentWallpaperName)")
        print("[MANAGER_STATE] [\(operationId)] desktopWindows: \(desktopWindows.count)个窗口")
        print("[MANAGER_STATE] [\(operationId)] currentVideoURL: \(currentVideoURL?.lastPathComponent ?? "nil")")
        print("[MANAGER_STATE] [\(operationId)] currentImageURL: \(currentImageURL?.lastPathComponent ?? "nil")")
    }
    
    func setImageWallpaper(from url: URL, for displayID: CGDirectDisplayID? = nil, scale: CGFloat = 1.0, offset: CGSize = .zero) -> Bool {
        stopVideoWallpaper()
        
        do {
            // 如果有裁剪参数，先处理图片
            let finalURL: URL
            if scale != 1.0 || offset != .zero {
                guard let croppedURL = createCroppedImage(from: url, scale: scale, offset: offset, for: displayID) else {
                    print("❌ 图片裁剪失败")
                    return false
                }
                finalURL = croppedURL
            } else {
                finalURL = url
            }
            
            if let targetDisplayID = displayID {
                // 为特定显示器设置壁纸
                if let targetScreen = findScreen(for: targetDisplayID) {
                    try NSWorkspace.shared.setDesktopImageURL(finalURL, for: targetScreen, options: [:])
                    print("🖼️ 图片壁纸设置成功到显示器 \(targetDisplayID): \(url.lastPathComponent)")
                } else {
                    print("❌ 找不到指定的显示器: \(targetDisplayID)")
                    return false
                }
            } else {
                // 为所有显示器设置壁纸（保持原有行为）
                let screens = NSScreen.screens
                for screen in screens {
                    try NSWorkspace.shared.setDesktopImageURL(finalURL, for: screen, options: [:])
                }
                print("🖼️ 图片壁纸设置成功到所有显示器: \(url.lastPathComponent)")
            }
            
            currentImageURL = url
            currentVideoURL = nil
            currentWallpaperName = url.lastPathComponent
            isVideoActive = false
            return true
        } catch {
            print("❌ 图片壁纸设置失败: \(error)")
            return false
        }
    }
    
    // 辅助方法：根据显示器ID查找对应的NSScreen
    private func findScreen(for displayID: CGDirectDisplayID) -> NSScreen? {
        return NSScreen.screens.first { screen in
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            return screenNumber == displayID
        }
    }
    
    // 创建裁剪后的图片
    private func createCroppedImage(from url: URL, scale: CGFloat, offset: CGSize, for displayID: CGDirectDisplayID?) -> URL? {
        guard let originalImage = NSImage(contentsOf: url) else {
            print("❌ 无法加载原始图片")
            return nil
        }
        
        // 获取目标显示器的分辨率
        let targetSize: CGSize
        if let displayID = displayID, let screen = findScreen(for: displayID) {
            targetSize = screen.frame.size
        } else {
            targetSize = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        }
        
        // 创建裁剪后的图片
        guard let croppedImage = applyCropToImage(originalImage, scale: scale, offset: offset, targetSize: targetSize) else {
            print("❌ 图片裁剪处理失败")
            return nil
        }
        
        // 保存到临时文件
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileName = "fluxwall_cropped_\(UUID().uuidString).png"
        let tempURL = tempDirectory.appendingPathComponent(tempFileName)
        
        guard let tiffData = croppedImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            print("❌ 无法生成PNG数据")
            return nil
        }
        
        do {
            try pngData.write(to: tempURL)
            print("✅ 裁剪后的图片已保存到: \(tempURL.path)")
            return tempURL
        } catch {
            print("❌ 保存裁剪图片失败: \(error)")
            return nil
        }
    }
    
    // 对图片应用裁剪变换（与 Core Animation 变换保持一致）
    private func applyCropToImage(_ image: NSImage, scale: CGFloat, offset: CGSize, targetSize: CGSize) -> NSImage? {
        // 创建目标图片
        let targetImage = NSImage(size: targetSize)
        
        targetImage.lockFocus()
        
        // 设置背景为透明
        NSColor.clear.set()
        let backgroundRect = NSRect(origin: .zero, size: targetSize)
        backgroundRect.fill()
        
        // 使用与 Core Animation 相同的变换逻辑
        // 1. 首先将图片按 resizeAspectFill 模式适配到目标尺寸
        let imageSize = image.size
        let targetAspect = targetSize.width / targetSize.height
        let imageAspect = imageSize.width / imageSize.height
        
        var fillSize: CGSize
        if imageAspect > targetAspect {
            // 图片更宽，以高度为准
            fillSize = CGSize(width: targetSize.height * imageAspect, height: targetSize.height)
        } else {
            // 图片更高，以宽度为准
            fillSize = CGSize(width: targetSize.width, height: targetSize.width / imageAspect)
        }
        
        // 2. 应用缩放
        let scaledSize = CGSize(
            width: fillSize.width * scale,
            height: fillSize.height * scale
        )
        
        // 3. 计算绘制位置（居中 + 偏移）
        // 注意：图片绘制的坐标系 Y 轴向上为正，需要与 Core Animation 保持一致
        let adjustedOffsetX = offset.width
        let adjustedOffsetY = -offset.height  // 反转 Y 轴，与视频壁纸保持一致
        
        let drawRect = CGRect(
            x: (targetSize.width - scaledSize.width) / 2 + adjustedOffsetX,
            y: (targetSize.height - scaledSize.height) / 2 + adjustedOffsetY,
            width: scaledSize.width,
            height: scaledSize.height
        )
        
        // 4. 绘制图片
        image.draw(in: drawRect)
        
        targetImage.unlockFocus()
        
        return targetImage
    }
    
    func setVideoWallpaper(from url: URL, for displayID: CGDirectDisplayID? = nil, transitionType: TransitionType = .fade, transitionDuration: Double = 1.0, scale: CGFloat = 1.0, offset: CGSize = .zero, completion: ((Bool) -> Void)? = nil) {
        // 验证URL是否存在
        if !FileManager.default.fileExists(atPath: url.path) {
            completion?(false)
            return
        }
        
        // 在主线程上执行UI操作
        DispatchQueue.main.async {
            let targetDisplayID = displayID ?? self.getMainDisplayID()
            
            // 检查是否已有该显示器的窗口实例
            if let currentWindow = self.desktopWindows[targetDisplayID] {
                // 配置窗口的过渡设置
                currentWindow.transitionType = transitionType
                currentWindow.transitionDuration = transitionDuration
                
                // 直接更新视频播放器的资源
                currentWindow.setupVideoPlayer(with: url, scale: scale, offset: offset)
                
                // 确保窗口可见并播放视频
                currentWindow.orderFront(nil)
                currentWindow.orderBack(nil)
                currentWindow.playVideo()
                
                print("[INFO] 更新显示器 \(targetDisplayID) 的视频壁纸")
            } else {
                // 为该显示器创建新的窗口实例
                self.createVideoWindow(for: targetDisplayID, url: url, transitionType: transitionType, transitionDuration: transitionDuration, scale: scale, offset: offset, completion: completion)
                return
            }
            
            // 更新状态
            self.currentVideoURL = url
            self.currentImageURL = nil
            self.currentWallpaperName = url.lastPathComponent
            self.isVideoActive = true
            self.isVideoPaused = false
            
            completion?(true)
        }
    }
    
    private func createVideoWindow(for displayID: CGDirectDisplayID, url: URL, transitionType: TransitionType, transitionDuration: Double, scale: CGFloat, offset: CGSize, completion: ((Bool) -> Void)?) {
        // 为特定显示器创建窗口
        let window = DesktopOverlayWindow(for: displayID)
        print("🎬 为显示器 \(displayID) 创建视频壁纸窗口")
        
        // 配置窗口
        window.transitionType = transitionType
        window.transitionDuration = transitionDuration
        
        // 设置视频播放器
        window.setupVideoPlayer(with: url, scale: scale, offset: offset)
        
        // 显示窗口
        window.orderFront(nil)
        window.orderBack(nil)
        
        // 开始播放
        window.playVideo()
        
        // 保存窗口引用到字典中
        self.desktopWindows[displayID] = window
        
        // 更新状态
        self.currentVideoURL = url
        self.currentImageURL = nil
        self.currentWallpaperName = url.lastPathComponent
        self.isVideoActive = true
        self.isVideoPaused = false
        
        print("[INFO] 显示器 \(displayID) 的视频壁纸窗口创建完成，当前共有 \(self.desktopWindows.count) 个视频窗口")
        
        completion?(true)
    }
    
    private func getMainDisplayID() -> CGDirectDisplayID {
        return CGMainDisplayID()
    }
    
    // 添加一个标志，防止重复调用
    var isStoppingVideo = false
    
    func stopVideoWallpaper() {
        // 在主线程上安全地关闭所有窗口
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // 关闭所有视频壁纸窗口
            for (displayID, window) in self.desktopWindows {
                print("[INFO] 关闭显示器 \(displayID) 的视频壁纸窗口")
                // 先暂停视频播放
                window.pauseVideo()
                
                // 关闭窗口
                window.close()
            }
            
            // 清理状态
            self.desktopWindows.removeAll()
            self.currentVideoURL = nil
            self.isVideoActive = false
            self.isVideoPaused = false
            
            print("[INFO] 所有视频壁纸窗口已关闭")
        }
    }
    
    func stopVideoWallpaper(for displayID: CGDirectDisplayID) {
        // 停止特定显示器的视频壁纸
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let window = self.desktopWindows[displayID] {
                print("[INFO] 关闭显示器 \(displayID) 的视频壁纸窗口")
                // 先暂停视频播放
                window.pauseVideo()
                
                // 关闭窗口
                window.close()
                
                // 从字典中移除
                self.desktopWindows.removeValue(forKey: displayID)
                
                // 如果没有视频窗口了，更新状态
                if self.desktopWindows.isEmpty {
                    self.currentVideoURL = nil
                    self.isVideoActive = false
                    self.isVideoPaused = false
                }
                
                print("[INFO] 显示器 \(displayID) 的视频壁纸已停止，剩余 \(self.desktopWindows.count) 个视频窗口")
            }
        }
    }
    
    func pauseCurrentVideo() {
        for window in desktopWindows.values {
            window.pauseVideo()
        }
        isVideoPaused = true
    }
    
    func resumeCurrentVideo() {
        for window in desktopWindows.values {
            window.playVideo()
        }
        isVideoPaused = false
    }
    
    func updateTransitionSettings(type: TransitionType, duration: Double) {
        for window in desktopWindows.values {
            window.transitionType = type
            window.transitionDuration = duration
        }
    }
    
    func getCurrentTransitionSettings() -> (type: TransitionType, duration: Double) {
        // 从第一个窗口获取设置，如果没有窗口则使用默认值
        if let firstWindow = desktopWindows.values.first {
            return (firstWindow.transitionType, firstWindow.transitionDuration)
        }
        return (.fade, 1.0)
    }
    
    // 添加一个标志，防止重复恢复系统壁纸
    var isRestoringSystemWallpaper = false
    
    func restoreSystemWallpaper() -> Bool {
        // 如果已经在恢复系统壁纸过程中，直接返回
        if isRestoringSystemWallpaper {
            print("[DEBUG] 已经在恢复系统壁纸过程中，忽略重复调用")
            return true
        }
        
        print("[INFO] 开始恢复系统壁纸")
        isRestoringSystemWallpaper = true
        
        // 首先停止视频壁纸 - 这是一个异步操作
        print("[DEBUG] 停止视频壁纸")
        stopVideoWallpaper()
        
        // 使用延迟确保视频壁纸已完全停止
        print("[DEBUG] 延迟0.5秒后设置系统壁纸")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else {
                print("[ERROR] self已被释放，无法继续恢复系统壁纸")
                return
            }
            
            // 更新状态
            print("[DEBUG] 更新状态")
            self.currentWallpaperName = LocalizedStrings.current.systemDefault
            self.isVideoActive = false
            self.isVideoPaused = false
            
            // 尝试设置系统壁纸
            print("[DEBUG] 尝试设置系统壁纸")
            self.attemptToSetSystemWallpaper()
            
            // 重置标志
            self.isRestoringSystemWallpaper = false
        }
        
        // 立即返回成功，实际设置在异步操作中完成
        print("[INFO] 恢复系统壁纸操作已启动")
        return true
    }
    
    // 尝试设置系统壁纸的辅助方法
    func attemptToSetSystemWallpaper() {
        print("[INFO] 尝试设置系统默认壁纸")
        
        // 尝试使用系统默认壁纸
        let defaultWallpaperPaths = [
            "/System/Library/Desktop Pictures/Monterey.heic",
            "/System/Library/Desktop Pictures/Big Sur.heic",
            "/System/Library/Desktop Pictures/Catalina.heic"
        ]
        
        var success = false
        
        // 尝试系统壁纸
        for path in defaultWallpaperPaths where !success {
            let url = URL(fileURLWithPath: path)
            print("[DEBUG] 检查壁纸路径: \(path)")
            
            if FileManager.default.fileExists(atPath: path) {
                print("[DEBUG] 找到壁纸文件: \(path)")
                do {
                    let screens = NSScreen.screens
                    print("[DEBUG] 设置壁纸到\(screens.count)个屏幕")
                    
                    for (index, screen) in screens.enumerated() {
                        print("[DEBUG] 设置壁纸到屏幕\(index + 1)")
                        try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
                    }
                    
                    success = true
                    print("[INFO] 已成功设置系统默认壁纸: \(path)")
                    break
                } catch {
                    print("[ERROR] 设置系统壁纸失败: \(error)")
                }
            } else {
                print("[DEBUG] 壁纸文件不存在: \(path)")
            }
        }
        
        // 如果系统壁纸设置失败，尝试创建纯色壁纸
        if !success {
            print("[WARNING] 未找到系统默认壁纸，尝试创建纯色壁纸")
            createAndSetSolidColorWallpaper()
        }
    }
    
    // 创建并设置纯色壁纸
    func createAndSetSolidColorWallpaper() {
        print("[INFO] 开始创建纯色壁纸")
        
        do {
            // 创建一个纯色图片
            let size = NSSize(width: 1920, height: 1080)
            print("[DEBUG] 创建尺寸为\(size.width)x\(size.height)的图片")
            
            let image = NSImage(size: size)
            
            print("[DEBUG] 填充纯色")
            image.lockFocus()
            NSColor.darkGray.setFill()
            NSRect(origin: .zero, size: size).fill()
            image.unlockFocus()
            
            // 保存到临时文件
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent("default_wallpaper.png")
            print("[DEBUG] 保存到临时文件: \(tempURL.path)")
            
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                
                print("[DEBUG] 写入PNG数据到文件")
                try pngData.write(to: tempURL)
                
                // 设置为壁纸
                let screens = NSScreen.screens
                print("[DEBUG] 设置壁纸到\(screens.count)个屏幕")
                
                for (index, screen) in screens.enumerated() {
                    print("[DEBUG] 设置壁纸到屏幕\(index + 1)")
                    try NSWorkspace.shared.setDesktopImageURL(tempURL, for: screen, options: [:])
                }
                
                print("[INFO] 已成功设置默认纯色壁纸")
            } else {
                print("[ERROR] 创建图片数据失败")
            }
        } catch {
            print("[ERROR] 创建默认壁纸失败: \(error)")
        }
    }
}
