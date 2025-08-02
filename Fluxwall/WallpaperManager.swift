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
        
    }
    
    var transitionType: TransitionType = .fade
    var transitionDuration: Double = 1.0
    
    var targetDisplayID: CGDirectDisplayID?
    
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: NSScreen.main?.frame ?? .zero, styleMask: [.borderless], backing: .buffered, defer: true)
        setupWindow()
    }
    
    convenience init() {
        self.init(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
    }
    
    convenience init(for displayID: CGDirectDisplayID) {
        self.init(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        self.targetDisplayID = displayID
        setupWindowForDisplay(displayID)
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
            self.setFrame(targetScreen.frame, display: false)
        } else {
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
            return
        }
        
        if !FileManager.default.fileExists(atPath: url.path) {
            return
        }
        
        guard let contentView = self.contentView else {
            return
        }
        
        if contentView.layer == nil {
            contentView.wantsLayer = true
        }
        
        if playerA != nil || playerB != nil || timeObserver != nil {
            cleanupVideoPlayerSync()
        }
        
        currentVideoURL = url
        
        do {
            try setupDualPlayerSystem(with: url, in: contentView, scale: scale, offset: offset)
        } catch VideoPlayerError.playerCreationFailed {
            
        } catch VideoPlayerError.layerCreationFailed {
            
        } catch VideoPlayerError.contentViewLayerMissing {
            
        } catch {
            
        }
    }
    
    enum VideoPlayerError: Error {
        case playerCreationFailed
        case layerCreationFailed
        case contentViewLayerMissing
    }
    
    private func setupDualPlayerSystem(with url: URL, in contentView: NSView, scale: CGFloat, offset: CGSize) throws {
        if contentView.layer == nil {
            contentView.wantsLayer = true
            if contentView.layer == nil {
                throw VideoPlayerError.contentViewLayerMissing
            }
        }
        
        let playerItemA = AVPlayerItem(url: url)
        playerA = AVPlayer(playerItem: playerItemA)
        
        if playerA == nil {
            throw VideoPlayerError.playerCreationFailed
        }
        
        let playerItemB = AVPlayerItem(url: url)
        playerB = AVPlayer(playerItem: playerItemB)
        
        if playerB == nil {
            throw VideoPlayerError.playerCreationFailed
        }
        
        guard let playerA = playerA else {
            throw VideoPlayerError.playerCreationFailed
        }
        
        playerLayerA = AVPlayerLayer(player: playerA)
        
        if playerLayerA == nil {
            throw VideoPlayerError.layerCreationFailed
        }
        
        playerLayerA?.frame = contentView.bounds
        playerLayerA?.videoGravity = .resizeAspectFill
        playerLayerA?.opacity = 1.0
        
        applyCropTransform(to: playerLayerA, scale: scale, offset: offset, containerSize: contentView.bounds.size)
        
        guard let playerB = playerB else {
            throw VideoPlayerError.playerCreationFailed
        }
        
        playerLayerB = AVPlayerLayer(player: playerB)
        
        if playerLayerB == nil {
            throw VideoPlayerError.layerCreationFailed
        }
        
        playerLayerB?.frame = contentView.bounds
        playerLayerB?.videoGravity = .resizeAspectFill
        playerLayerB?.opacity = 0.0
        
        applyCropTransform(to: playerLayerB, scale: scale, offset: offset, containerSize: contentView.bounds.size)
        
        guard let contentViewLayer = contentView.layer else {
            throw VideoPlayerError.contentViewLayerMissing
        }
        
        if let layerA = playerLayerA {
            contentViewLayer.addSublayer(layerA)
        } else {
            throw VideoPlayerError.layerCreationFailed
        }
        
        if let layerB = playerLayerB {
            contentViewLayer.addSublayer(layerB)
        } else {
            throw VideoPlayerError.layerCreationFailed
        }
        
        setupSeamlessLoopObserver()
    }
    
    private func applyCropTransform(to layer: AVPlayerLayer?, scale: CGFloat, offset: CGSize, containerSize: CGSize) {
        guard let layer = layer else { return }
        
        var transform = CATransform3DIdentity
        transform = CATransform3DScale(transform, scale, scale, 1.0)
        
        let adjustedOffsetX = offset.width
        let adjustedOffsetY = -offset.height
        transform = CATransform3DTranslate(transform, adjustedOffsetX, adjustedOffsetY, 0)
        
        layer.transform = transform
    }

    private func setupSeamlessLoopObserver() {
        if let observer = timeObserver {
            let currentActivePlayer = isPlayerAActive ? playerA : playerB
            currentActivePlayer?.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        guard let activePlayer = isPlayerAActive ? playerA : playerB,
              let activeItem = activePlayer.currentItem else {
            return
        }
        
        let strongPlayerRef = activePlayer
        let strongItemRef = activeItem
        
        strongItemRef.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            DispatchQueue.main.async {
                guard let self = self else {
                    return
                }
                
                guard self.playerA != nil || self.playerB != nil else {
                    return
                }
                
                var error: NSError?
                let status = strongItemRef.asset.statusOfValue(forKey: "duration", error: &error)
                
                if status == .loaded {
                    let duration = strongItemRef.asset.duration
                    let durationSeconds = CMTimeGetSeconds(duration)
                    
                    let triggerTime = CMTime(seconds: max(0, durationSeconds - self.transitionDuration), preferredTimescale: 600)
                    
                    guard let currentActivePlayer = self.isPlayerAActive ? self.playerA : self.playerB,
                          currentActivePlayer === strongPlayerRef else {
                        return
                    }
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
                }
            }
        }
    }
    
    private func performSeamlessTransition() {
        guard !isTransitioning else {
            return
        }
        
        guard let layerA = playerLayerA,
              let layerB = playerLayerB,
              let playerA = playerA,
              let playerB = playerB else {
            return
        }
        
        isTransitioning = true
        
        if isPlayerAActive {
            playerB.seek(to: .zero)
            playerB.play()
            performTransition(fromLayer: layerA, toLayer: layerB, fromPlayer: playerA, toPlayer: playerB)
        } else {
            playerA.seek(to: .zero)
            playerA.play()
            performTransition(fromLayer: layerB, toLayer: layerA, fromPlayer: playerB, toPlayer: playerA)
        }
    }
    
    private func performTransition(fromLayer: AVPlayerLayer, toLayer: AVPlayerLayer, fromPlayer: AVPlayer, toPlayer: AVPlayer) {
        switch transitionType {
        case .none:
            performDirectTransition(fromLayer: fromLayer, toLayer: toLayer, fromPlayer: fromPlayer, toPlayer: toPlayer)
        case .fade:
            performFadeTransition(fromLayer: fromLayer, toLayer: toLayer, fromPlayer: fromPlayer, toPlayer: toPlayer)
        case .blackout:
            performBlackoutTransition(fromLayer: fromLayer, toLayer: toLayer, fromPlayer: fromPlayer, toPlayer: toPlayer)
        }
    }
    
    private func performDirectTransition(fromLayer: AVPlayerLayer, toLayer: AVPlayerLayer, fromPlayer: AVPlayer, toPlayer: AVPlayer) {
        toLayer.opacity = 1.0
        fromLayer.opacity = 0.0
        
        completeTransition(fromPlayer: fromPlayer)
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
        if let observer = timeObserver {
            fromPlayer.removeTimeObserver(observer)
            timeObserver = nil
        }
        
        fromPlayer.pause()
        
        isPlayerAActive.toggle()
        
        setupSeamlessLoopObserver()
        
        isTransitioning = false
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
        
        detectDanglingPointers()
        checkObjectValidity()
        trackObjectLifecycle()
        
        let currentPlayerA = playerA
        let currentPlayerB = playerB
        let currentObserver = timeObserver
        let currentLayerA = playerLayerA
        let currentLayerB = playerLayerB
        let isPlayerA = isPlayerAActive
        
        timeObserver = nil
        playerA = nil
        playerB = nil
        playerLayerA = nil
        playerLayerB = nil
        currentVideoURL = nil
        isPlayerAActive = true
        isTransitioning = false
        
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
        
        if let player = playerA {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            player.pause()
        }
        
        if let player = playerB {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            player.pause()
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
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
        
        if let timeObserver = observer {
            let observerPointer = Unmanaged.passUnretained(timeObserver as AnyObject).toOpaque()
            
            do {
                if isPlayerA, let player = playerA {
                    let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                    player.removeTimeObserver(timeObserver)
                } else if let player = playerB {
                    let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                    player.removeTimeObserver(timeObserver)
                }
            } catch {
            }
        } else {
        }
        
        completion()
    }
    
    private func cleanupStep3_RemoveLayers(
        layerA: AVPlayerLayer?,
        layerB: AVPlayerLayer?,
        cleanupId: String,
        completion: @escaping () -> Void
    ) {
        
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        
        if let layerA = layerA {
            let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
            
            layerA.player = nil
            
            layerA.removeFromSuperlayer()
        } else {
        }
        
        if let layerB = layerB {
            let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
            
            layerB.player = nil
            
            layerB.removeFromSuperlayer()
        } else {
        }
        
        CATransaction.commit()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            completion()
        }
    }
    
    private func cleanupStep4_FinalCleanup(cleanupId: String, completion: @escaping () -> Void) {
        
        trackObjectLifecycle()
        
        completion()
    }
    
    private func cleanupVideoPlayerSync() {
        let cleanupId = UUID().uuidString
        
        let currentPlayerA = playerA
        let currentPlayerB = playerB
        let currentObserver = timeObserver
        let currentLayerA = playerLayerA
        let currentLayerB = playerLayerB
        let isPlayerA = isPlayerAActive
        
        
        if timeObserver != nil {
            timeObserver = nil
        }
        
        if playerA != nil {
            playerA = nil
        }
        
        if playerB != nil {
            playerB = nil
        }
        
        if playerLayerA != nil {
            playerLayerA = nil
        }
        
        if playerLayerB != nil {
            playerLayerB = nil
        }
        
        currentVideoURL = nil
        isPlayerAActive = true
        isTransitioning = false
        
        
        if let player = currentPlayerA {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            player.pause()
        }
        
        if let player = currentPlayerB {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            player.pause()
        }
        
        if let observer = currentObserver {
            let observerPointer = Unmanaged.passUnretained(observer as AnyObject).toOpaque()
            
            do {
                if isPlayerA, let player = currentPlayerA {
                    let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                    player.removeTimeObserver(observer)
                } else if let player = currentPlayerB {
                    let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                    player.removeTimeObserver(observer)
                }
            } catch {
            }
        } else {
        }
        
        if let layerA = currentLayerA {
            let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
            
            do {
                layerA.removeFromSuperlayer()
            } catch {
            }
        } else {
        }
        
        if let layerB = currentLayerB {
            let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
            
            do {
                layerB.removeFromSuperlayer()
            } catch {
            }
        } else {
        }
        
    }
    
    private func cleanupVideoPlayer() {
        let cleanupId = UUID().uuidString
        
        if isCleaningUp {
            return
        }
        
        isCleaningUp = true
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else {
                return
            }
            
            
            if let player = self.playerA {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                player.pause()
            } else {
            }
            
            if let player = self.playerB {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                player.pause()
            } else {
            }
            
            let currentObserver = self.timeObserver
            let currentPlayerA = self.playerA
            let currentPlayerB = self.playerB
            let isPlayerA = self.isPlayerAActive
            
            
            if let observer = currentObserver {
                
                do {
                    if isPlayerA, let player = currentPlayerA {
                        let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                        player.removeTimeObserver(observer)
                    } else if let player = currentPlayerB {
                        let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                        player.removeTimeObserver(observer)
                    }
                } catch {
                }
            } else {
            }
            
            if let layerA = self.playerLayerA {
                let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
                
                do {
                    layerA.removeFromSuperlayer()
                } catch {
                }
            } else {
            }
            
            if let layerB = self.playerLayerB {
                let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
                
                do {
                    layerB.removeFromSuperlayer()
                } catch {
                }
            } else {
            }
            
            self.timeObserver = nil
            self.playerA = nil
            self.playerB = nil
            self.playerLayerA = nil
            self.playerLayerB = nil
            self.currentVideoURL = nil
            self.isPlayerAActive = true
            self.isTransitioning = false
            
            self.isCleaningUp = false
            
        }
    }
    
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
        } else {
        }
    }
    
    private func logObjectRetainCount<T: AnyObject>(_ object: T?, name: String) {
        guard let obj = object else {
            return
        }
        
        do {
            let retainCount = CFGetRetainCount(obj)
            let pointer = Unmanaged.passUnretained(obj).toOpaque()
            
            if retainCount <= 0 {
            }
        } catch {
        }
    }
    
    private func checkObjectValidity() {
        
        if let player = playerA {
            let pointer = Unmanaged.passUnretained(player).toOpaque()
            
            do {
                let rate = player.rate
            } catch {
            }
        } else {
        }
        
        if let player = playerB {
            let pointer = Unmanaged.passUnretained(player).toOpaque()
            
            do {
                let rate = player.rate
            } catch {
            }
        } else {
        }
        
        if let layer = playerLayerA {
            let pointer = Unmanaged.passUnretained(layer).toOpaque()
        } else {
        }
        
        if let layer = playerLayerB {
            let pointer = Unmanaged.passUnretained(layer).toOpaque()
        } else {
        }
        
    }
    
    private func detectDanglingPointers() {
        
        if playerA != nil {
            do {
                let _ = playerA?.rate
            } catch {
            }
        }
        
        if playerB != nil {
            do {
                let _ = playerB?.rate
            } catch {
            }
        }
        
        if playerLayerA != nil {
            do {
                let _ = playerLayerA?.bounds
            } catch {
            }
        }
        
        if playerLayerB != nil {
            do {
                let _ = playerLayerB?.bounds
            } catch {
            }
        }
        
    }
    
    private func trackObjectLifecycle() {
        
        logObjectRetainCount(playerA, name: "playerA")
        logObjectRetainCount(playerB, name: "playerB")
        logObjectRetainCount(playerLayerA, name: "playerLayerA")
        logObjectRetainCount(playerLayerB, name: "playerLayerB")
        
        if let observer = timeObserver {
            let pointer = Unmanaged.passUnretained(observer as AnyObject).toOpaque()
        } else {
        }
        
        logMemoryUsage(context: "Object lifecycle tracking")
    }
    
    private var isClosing = false
    private var isBeingClosed = false
    
    override func close() {
        if isClosing {
            return
        }
        
        isClosing = true
        
        playerA?.pause()
        playerB?.pause()
        
        cleanupVideoPlayerWithDelay { [weak self] in
            guard let self = self else {
                return
            }
            
            
            DispatchQueue.main.async { [weak self] in
                guard let self = self else { return }
                self.performClose(nil)
            }
        }
    }
    
    private func cleanupVideoPlayerSyncSafe() {
        let cleanupId = UUID().uuidString
        
        detectDanglingPointers()
        checkObjectValidity()
        trackObjectLifecycle()
        
        let currentPlayerA = playerA
        let currentPlayerB = playerB
        let currentObserver = timeObserver
        let currentLayerA = playerLayerA
        let currentLayerB = playerLayerB
        let isPlayerA = isPlayerAActive
        
        timeObserver = nil
        playerA = nil
        playerB = nil
        playerLayerA = nil
        playerLayerB = nil
        currentVideoURL = nil
        isPlayerAActive = true
        isTransitioning = false
        
        if let player = currentPlayerA {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            player.pause()
        }
        
        if let player = currentPlayerB {
            let playerPointer = Unmanaged.passUnretained(player).toOpaque()
            player.pause()
        }
        
        if let observer = currentObserver {
            let observerPointer = Unmanaged.passUnretained(observer as AnyObject).toOpaque()
            
            if isPlayerA, let player = currentPlayerA {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                player.removeTimeObserver(observer)
            } else if let player = currentPlayerB {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                player.removeTimeObserver(observer)
            }
        } else {
        }
        
        CATransaction.begin()
        
        if let layerA = currentLayerA {
            let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
            
            layerA.player = nil
            
            layerA.removeFromSuperlayer()
        } else {
        }
        
        if let layerB = currentLayerB {
            let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
            
            layerB.player = nil
            
            layerB.removeFromSuperlayer()
        } else {
        }
        
        CATransaction.commit()
        
        trackObjectLifecycle()
        
    }
    
    private func cleanupVideoPlayerWithDelay(completion: @escaping () -> Void) {
        let cleanupId = UUID().uuidString
        
        detectDanglingPointers()
        checkObjectValidity()
        trackObjectLifecycle()
        
        let currentPlayerA = playerA
        let currentPlayerB = playerB
        let currentObserver = timeObserver
        let currentLayerA = playerLayerA
        let currentLayerB = playerLayerB
        let isPlayerA = isPlayerAActive
        
        if let observer = currentObserver {
            let observerPointer = Unmanaged.passUnretained(observer as AnyObject).toOpaque()
            
            if isPlayerA, let player = currentPlayerA {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                player.removeTimeObserver(observer)
            } else if let player = currentPlayerB {
                let playerPointer = Unmanaged.passUnretained(player).toOpaque()
                player.removeTimeObserver(observer)
            }
            
            timeObserver = nil
        } else {
        }
        
        
        CATransaction.begin()
        
        CATransaction.setCompletionBlock { [weak self] in
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self = self else {
                    completion()
                    return
                }
                
                
                self.playerA = nil
                self.playerB = nil
                self.playerLayerA = nil
                self.playerLayerB = nil
                self.currentVideoURL = nil
                self.isPlayerAActive = true
                self.isTransitioning = false
                
                
                self.trackObjectLifecycle()
                
                completion()
            }
        }
        
        if let layerA = currentLayerA {
            let layerPointer = Unmanaged.passUnretained(layerA).toOpaque()
            
            layerA.player = nil
            
            layerA.removeFromSuperlayer()
        } else {
        }
        
        if let layerB = currentLayerB {
            let layerPointer = Unmanaged.passUnretained(layerB).toOpaque()
            
            layerB.player = nil
            
            layerB.removeFromSuperlayer()
        } else {
        }
        
        CATransaction.commit()
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
        
        if !desktopWindows.isEmpty {
        }
        if currentVideoURL != nil {
        }
        if currentImageURL != nil {
        }
        
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
        } else {
        }
    }
    
    private func logWindowObjectState(_ window: DesktopOverlayWindow, context: String, operationId: String) {
        let windowId = ObjectIdentifier(window).hashValue
        let windowPointer = Unmanaged.passUnretained(window).toOpaque()
        
    }
    
    private func logManagerState(context: String, operationId: String) {
    }
    
    func setImageWallpaper(from url: URL, for displayID: CGDirectDisplayID? = nil, scale: CGFloat = 1.0, offset: CGSize = .zero) -> Bool {
        stopVideoWallpaper()
        
        do {
            let finalURL: URL
            if scale != 1.0 || offset != .zero {
                guard let croppedURL = createCroppedImage(from: url, scale: scale, offset: offset, for: displayID) else {
                    return false
                }
                finalURL = croppedURL
            } else {
                finalURL = url
            }
            
            if let targetDisplayID = displayID {
                if let targetScreen = findScreen(for: targetDisplayID) {
                    try NSWorkspace.shared.setDesktopImageURL(finalURL, for: targetScreen, options: [:])
                } else {
                    return false
                }
            } else {
                let screens = NSScreen.screens
                for screen in screens {
                    try NSWorkspace.shared.setDesktopImageURL(finalURL, for: screen, options: [:])
                }
            }
            
            currentImageURL = url
            currentVideoURL = nil
            currentWallpaperName = url.lastPathComponent
            isVideoActive = false
            return true
        } catch {
            return false
        }
    }
    
    private func findScreen(for displayID: CGDirectDisplayID) -> NSScreen? {
        return NSScreen.screens.first { screen in
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            return screenNumber == displayID
        }
    }
    
    private func createCroppedImage(from url: URL, scale: CGFloat, offset: CGSize, for displayID: CGDirectDisplayID?) -> URL? {
        guard let originalImage = NSImage(contentsOf: url) else {
            return nil
        }
        
        let targetSize: CGSize
        if let displayID = displayID, let screen = findScreen(for: displayID) {
            targetSize = screen.frame.size
        } else {
            targetSize = NSScreen.main?.frame.size ?? CGSize(width: 1920, height: 1080)
        }
        
        guard let croppedImage = applyCropToImage(originalImage, scale: scale, offset: offset, targetSize: targetSize) else {
            return nil
        }
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let tempFileName = "fluxwall_cropped_\(UUID().uuidString).png"
        let tempURL = tempDirectory.appendingPathComponent(tempFileName)
        
        guard let tiffData = croppedImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }
        
        do {
            try pngData.write(to: tempURL)
            return tempURL
        } catch {
            return nil
        }
    }
    
    private func applyCropToImage(_ image: NSImage, scale: CGFloat, offset: CGSize, targetSize: CGSize) -> NSImage? {
        let targetImage = NSImage(size: targetSize)
        
        targetImage.lockFocus()
        
        NSColor.clear.set()
        let backgroundRect = NSRect(origin: .zero, size: targetSize)
        backgroundRect.fill()
        
        let imageSize = image.size
        let targetAspect = targetSize.width / targetSize.height
        let imageAspect = imageSize.width / imageSize.height
        
        var fillSize: CGSize
        if imageAspect > targetAspect {
            fillSize = CGSize(width: targetSize.height * imageAspect, height: targetSize.height)
        } else {
            fillSize = CGSize(width: targetSize.width, height: targetSize.width / imageAspect)
        }
        
        let scaledSize = CGSize(
            width: fillSize.width * scale,
            height: fillSize.height * scale
        )
        
        let adjustedOffsetX = offset.width
        let adjustedOffsetY = -offset.height
        
        let drawRect = CGRect(
            x: (targetSize.width - scaledSize.width) / 2 + adjustedOffsetX,
            y: (targetSize.height - scaledSize.height) / 2 + adjustedOffsetY,
            width: scaledSize.width,
            height: scaledSize.height
        )
        
        image.draw(in: drawRect)
        
        targetImage.unlockFocus()
        
        return targetImage
    }
    
    func setVideoWallpaper(from url: URL, for displayID: CGDirectDisplayID? = nil, transitionType: TransitionType = .fade, transitionDuration: Double = 1.0, scale: CGFloat = 1.0, offset: CGSize = .zero, completion: ((Bool) -> Void)? = nil) {
        if !FileManager.default.fileExists(atPath: url.path) {
            completion?(false)
            return
        }
        
        DispatchQueue.main.async {
            let targetDisplayID = displayID ?? self.getMainDisplayID()
            
            if let currentWindow = self.desktopWindows[targetDisplayID] {
                currentWindow.transitionType = transitionType
                currentWindow.transitionDuration = transitionDuration
                
                currentWindow.setupVideoPlayer(with: url, scale: scale, offset: offset)
                
                currentWindow.orderFront(nil)
                currentWindow.orderBack(nil)
                currentWindow.playVideo()
                
            } else {
                self.createVideoWindow(for: targetDisplayID, url: url, transitionType: transitionType, transitionDuration: transitionDuration, scale: scale, offset: offset, completion: completion)
                return
            }
            
            self.currentVideoURL = url
            self.currentImageURL = nil
            self.currentWallpaperName = url.lastPathComponent
            self.isVideoActive = true
            self.isVideoPaused = false
            
            completion?(true)
        }
    }
    
    private func createVideoWindow(for displayID: CGDirectDisplayID, url: URL, transitionType: TransitionType, transitionDuration: Double, scale: CGFloat, offset: CGSize, completion: ((Bool) -> Void)?) {
        let window = DesktopOverlayWindow(for: displayID)
        
        window.transitionType = transitionType
        window.transitionDuration = transitionDuration
        
        window.setupVideoPlayer(with: url, scale: scale, offset: offset)
        
        window.orderFront(nil)
        window.orderBack(nil)
        
        window.playVideo()
        
        self.desktopWindows[displayID] = window
        
        self.currentVideoURL = url
        self.currentImageURL = nil
        self.currentWallpaperName = url.lastPathComponent
        self.isVideoActive = true
        self.isVideoPaused = false
        
        
        completion?(true)
    }
    
    private func getMainDisplayID() -> CGDirectDisplayID {
        return CGMainDisplayID()
    }
    
    var isStoppingVideo = false
    
    func stopVideoWallpaper() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            for (displayID, window) in self.desktopWindows {
                window.pauseVideo()
                
                window.close()
            }
            
            self.desktopWindows.removeAll()
            self.currentVideoURL = nil
            self.isVideoActive = false
            self.isVideoPaused = false
            
        }
    }
    
    func stopVideoWallpaper(for displayID: CGDirectDisplayID) {
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            if let window = self.desktopWindows[displayID] {
                window.pauseVideo()
                
                window.close()
                
                self.desktopWindows.removeValue(forKey: displayID)
                
                if self.desktopWindows.isEmpty {
                    self.currentVideoURL = nil
                    self.isVideoActive = false
                    self.isVideoPaused = false
                }
                
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
        if let firstWindow = desktopWindows.values.first {
            return (firstWindow.transitionType, firstWindow.transitionDuration)
        }
        return (.fade, 1.0)
    }
    
    var isRestoringSystemWallpaper = false
    
    func restoreSystemWallpaper() -> Bool {
        if isRestoringSystemWallpaper {
            return true
        }
        
        isRestoringSystemWallpaper = true
        
        stopVideoWallpaper()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            guard let self = self else {
                return
            }
            
            self.currentWallpaperName = LocalizedStrings.current.systemDefault
            self.isVideoActive = false
            self.isVideoPaused = false
            
            self.attemptToSetSystemWallpaper()
            
            self.isRestoringSystemWallpaper = false
        }
        
        return true
    }
    
    func attemptToSetSystemWallpaper() {
        
        let defaultWallpaperPaths = [
            "/System/Library/Desktop Pictures/Monterey.heic",
            "/System/Library/Desktop Pictures/Big Sur.heic",
            "/System/Library/Desktop Pictures/Catalina.heic"
        ]
        
        var success = false
        
        for path in defaultWallpaperPaths where !success {
            let url = URL(fileURLWithPath: path)
            
            if FileManager.default.fileExists(atPath: path) {
                do {
                    let screens = NSScreen.screens
                    
                    for (index, screen) in screens.enumerated() {
                        try NSWorkspace.shared.setDesktopImageURL(url, for: screen, options: [:])
                    }
                    
                    success = true
                    break
                } catch {
                }
            } else {
            }
        }
        
        if !success {
            createAndSetSolidColorWallpaper()
        }
    }
    
    func createAndSetSolidColorWallpaper() {
        
        do {
            let size = NSSize(width: 1920, height: 1080)
            
            let image = NSImage(size: size)
            
            image.lockFocus()
            NSColor.darkGray.setFill()
            NSRect(origin: .zero, size: size).fill()
            image.unlockFocus()
            
            let tempDir = FileManager.default.temporaryDirectory
            let tempURL = tempDir.appendingPathComponent("default_wallpaper.png")
            
            if let tiffData = image.tiffRepresentation,
               let bitmap = NSBitmapImageRep(data: tiffData),
               let pngData = bitmap.representation(using: .png, properties: [:]) {
                
                try pngData.write(to: tempURL)
                
                let screens = NSScreen.screens
                
                for (index, screen) in screens.enumerated() {
                    try NSWorkspace.shared.setDesktopImageURL(tempURL, for: screen, options: [:])
                }
                
            } else {
            }
        } catch {
        }
    }
}
