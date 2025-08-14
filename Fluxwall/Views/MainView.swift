import SwiftUI
import AppKit
import UniformTypeIdentifiers
import AVKit
import WebKit

// MARK: - Animated Button Component
struct AnimatedButton: View {
    let action: () -> Void
    let icon: String
    let text: String
    let style: ButtonStyle
    
    @State private var isHovered = false
    
    enum ButtonStyle {
        case primary
        case secondary
        case success
    }
    
    var backgroundColor: Color {
        switch style {
        case .primary:
            return ModernDesignSystem.Colors.infoColor
        case .secondary:
            return ModernDesignSystem.Colors.buttonBackground
        case .success:
            return ModernDesignSystem.Colors.successColor
        }
    }
    
    var foregroundColor: Color {
        switch style {
        case .primary, .success:
            return ModernDesignSystem.Colors.buttonTextActive
        case .secondary:
            return ModernDesignSystem.Colors.primaryText
        }
    }
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                
                Text(text)
                    .font(.system(size: 14, weight: .medium))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(backgroundColor)
                    .shadow(
                        color: backgroundColor.opacity(0.3),
                        radius: isHovered ? 6 : 3,
                        x: 0,
                        y: isHovered ? 3 : 2
                    )
                    .animation(.easeInOut(duration: 0.2), value: isHovered)
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isHovered)
        }
        .buttonStyle(PlainButtonStyle())
        .foregroundColor(foregroundColor)
        .onHover { hovering in
            withAnimation(.easeInOut(duration: 0.2)) {
                isHovered = hovering
            }
        }
    }
}

struct RefreshButton: View {
    let action: () -> Void
    @State private var isPressed = false
    @State private var rotationAngle: Double = 0
    
    var body: some View {
        Button(action: {
            // Trigger rotation animation
            withAnimation(.easeInOut(duration: 0.6)) {
                rotationAngle += 360
            }
            
            // Call the refresh action
            action()
        }) {
            Image(systemName: "arrow.clockwise")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(ModernDesignSystem.Colors.secondaryText)
                .rotationEffect(.degrees(rotationAngle))
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.easeInOut(duration: 0.1), value: isPressed)
        }
        .buttonStyle(PlainButtonStyle())
        .padding(6)
        .background(
            Circle()
                .fill(Color(.controlBackgroundColor))
                .opacity(isPressed ? 0.8 : 0.6)
        )
        .onPressGesture(
            onPress: { isPressed = true },
            onRelease: { isPressed = false }
        )
        .help(LocalizedStrings.current.refresh)
    }
}

// Helper for press gesture
extension View {
    func onPressGesture(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        self.simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in onPress() }
                .onEnded { _ in onRelease() }
        )
    }
}

struct MainView: View {
    @StateObject private var wallpaperManager = FluxwallWallpaperManager.shared
    @StateObject private var languageSettings = LanguageSettings.shared
    @State private var statusMessage = ""
    @State private var selectedTransitionType: TransitionType = .none
    @State private var transitionDuration: Double = 1.0
    @State private var selectedMediaURL: URL? = nil
    @State private var selectedSystemWallpaper: SystemWallpaper? = nil
    @State private var selectedDisplayID: CGDirectDisplayID?
    @State private var displays: [DisplayInfo] = []
    @State private var previewImage: NSImage? = nil
    @State private var firstFrame: NSImage? = nil
    @State private var lastFrame: NSImage? = nil
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var showingSettings = false
    @State private var webWallpaperURL: String = ""
    
    private var hasSelectedWallpaper: Bool {
        selectedMediaURL != nil || selectedSystemWallpaper != nil
    }

    var body: some View {
        ZStack {
            // Modern gradient background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.08),
                    Color(red: 0.08, green: 0.08, blue: 0.12)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
            ZStack {
                VStack(spacing: 6) {
                    HStack(alignment: .center, spacing: 8) {
                        Image(nsImage: NSApp.applicationIconImage)
                            .resizable()
                            .frame(width: 28, height: 28)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                        
                        Text(LocalizedStrings.current.appTitle)
                            .font(.custom("SF Pro Display", size: 26))
                            .fontWeight(.bold)
                            .titleGradient()
                            .shadow(color: .black.opacity(0.3), radius: 2, x: 1, y: 1)
                            .baselineOffset(-7)
                    }
                    
                    Text(LocalizedStrings.current.appSubtitle)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(ModernDesignSystem.Colors.secondaryText)
                }
                
                HStack {
                    Spacer()
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(ModernDesignSystem.Colors.secondaryText)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 20)
                }
            }
            .frame(height: 60)
            .padding(.top, 16)

            GeometryReader { geometry in
                let availableHeight = geometry.size.height - 20
                let horizontalPadding: CGFloat = 20
                let columnSpacing: CGFloat = 20
                let availableWidth = geometry.size.width - (horizontalPadding * 2)
                let columnWidth = (availableWidth - (columnSpacing * 2)) / 3

                HStack(alignment: .top, spacing: columnSpacing) {
                    VStack(spacing: 0) {
                        displaySelectorPanel()
                            .frame(height: 150)
                            .padding(.bottom, 10)
                            .offset(y: 2)

                        webURLInputPanel()
                            .frame(height: 72)
                        
                        fileSelectionPanel()
                            .frame(height: 320)
                        
                    }
                    .frame(width: columnWidth)

                    VStack(spacing: 12) {
                        VStack(spacing: 8) {
                            HStack {
                                Text(LocalizedStrings.current.builtInWallpapers)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(ModernDesignSystem.Colors.primaryText)
                                Spacer()
                                RefreshButton {
                                    WallpaperIndexer.shared.indexWallpapers()
                                }
                            }
                            
                            BuiltInWallpapersView { wallpaper in
                                handleSystemWallpaperSelection(wallpaper)
                            }
                        }
                        .padding(12)
                        .flatCard(cornerRadius: ModernDesignSystem.CornerRadius.large, shadowStyle: ModernDesignSystem.Shadow.minimal)
                        .frame(maxHeight: .infinity)
                        
                        cropPreviewPanel()
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: columnWidth, height: availableHeight)

                    transitionSettingsPanel()
                        .frame(width: columnWidth, height: availableHeight)
                }
                .padding(.horizontal, horizontalPadding)
                .padding(.vertical, 10)
            }

            Spacer(minLength: 0)
            }
        }
        .frame(width: 1000, height: 650)
        .onAppear {
            statusMessage = LocalizedStrings.current.ready
        }
        .onChange(of: languageSettings.currentLanguage) { _ in
            if !hasSelectedWallpaper {
                statusMessage = LocalizedStrings.current.ready
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    @ViewBuilder
    private func fileSelectionPanel() -> some View {
        VStack(spacing: 12) {
            DragDropArea { urls in
                if let firstUrl = urls.first {
                    selectedMediaURL = firstUrl
                    handleFileSelection(url: firstUrl)
                }
            }
            .frame(height: 120)
            .flatCard(cornerRadius: ModernDesignSystem.CornerRadius.large, shadowStyle: ModernDesignSystem.Shadow.minimal)
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 24))
                        .foregroundColor(ModernDesignSystem.Colors.infoColor)
                    Text(LocalizedStrings.current.dragFilesHere).font(.system(size: 13, weight: .medium))
                    Text(LocalizedStrings.current.supportedFormats).font(.system(size: 10)).foregroundColor(ModernDesignSystem.Colors.secondaryText)
                }
            )

            AnimatedButton(
                action: selectFile,
                icon: "folder.fill",
                text: LocalizedStrings.current.selectFile,
                style: .primary
            )

            VStack(spacing: 4) {
                Text(statusMessage)
                    .font(.system(size: 12))
                    .foregroundColor(ModernDesignSystem.Colors.secondaryText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                CurrentWallpaperNameView()
            }

            Button(action: {
                statusMessage = LocalizedStrings.current.restoringWallpaper
                _ = wallpaperManager.restoreSystemWallpaper()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    statusMessage = LocalizedStrings.current.wallpaperRestored
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.counterclockwise").font(.system(size: 12))
                    Text(LocalizedStrings.current.restoreSystemWallpaper).font(.system(size: 12, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
            }
            .buttonStyle(BorderlessButtonStyle())
            .flatCard(cornerRadius: ModernDesignSystem.CornerRadius.medium, shadowStyle: ModernDesignSystem.Shadow.minimal, borderIntensity: 0.8)
            .disabled(wallpaperManager.currentWallpaperName == LocalizedStrings.current.systemDefault && !wallpaperManager.isVideoActive)

            Spacer()
        }
        .padding(12)
        .flatCard(cornerRadius: ModernDesignSystem.CornerRadius.large, shadowStyle: ModernDesignSystem.Shadow.minimal)
    }

    @ViewBuilder
    private func displaySelectorPanel() -> some View {
        DisplaySelectorView(displays: $displays, onDisplaySelected: { displayID in
            selectedDisplayID = displayID
        })
        .padding(12)
        .flatCard(cornerRadius: ModernDesignSystem.CornerRadius.large, shadowStyle: ModernDesignSystem.Shadow.minimal)
    }
    
    @ViewBuilder
    private func webURLInputPanel() -> some View {
        WebWallpaperURLInput { urlString in
            handleWebWallpaperURLAndApply(urlString)
        }
    }

    @ViewBuilder
    private func cropPreviewPanel() -> some View {
        if let image = previewImage {
            let displaySize = selectedDisplayID.flatMap { id in
                displays.first(where: { $0.id == id })?.resolution
            } ?? CGSize(width: 1920, height: 1080)

            CropPreviewView(
                displaySize: displaySize,
                previewImage: image,
                scale: $scale,
                offset: $offset
            )
            .padding(12)
            .flatCard(cornerRadius: ModernDesignSystem.CornerRadius.large, shadowStyle: ModernDesignSystem.Shadow.minimal)
        } else {
            Text(LocalizedStrings.current.previewPrompt)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .flatCard(cornerRadius: ModernDesignSystem.CornerRadius.large, shadowStyle: ModernDesignSystem.Shadow.minimal)
        }
    }

    @ViewBuilder
    private func transitionSettingsPanel() -> some View {
        TransitionSettingsView(
            transitionType: $selectedTransitionType,
            transitionDuration: $transitionDuration,
            hasSelectedFile: hasSelectedWallpaper,
            isBuiltInWallpaper: selectedSystemWallpaper != nil,
            videoFirstFrame: self.firstFrame,  
            videoLastFrame: self.lastFrame
        ) { 
            applyWallpaper() 
        }
        .padding(12)
        .flatCard(cornerRadius: ModernDesignSystem.CornerRadius.large, shadowStyle: ModernDesignSystem.Shadow.minimal)
    }

    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.level = .floating
        
        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [.jpeg, .png, .heic, .mpeg4Movie, .quickTimeMovie]
        } else {
            panel.allowedFileTypes = ["jpg", "jpeg", "png", "heic", "mp4", "mov"]
        }
        
        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.selectedMediaURL = url
                self.handleFileSelection(url: url)
            }
        }
    }

    private func handleFileSelection(url: URL) {
        selectedSystemWallpaper = nil
        webWallpaperURL = ""
        WebWallpaperService.shared.removeWebWallpaper()
        
        let ext = url.pathExtension.lowercased()

        if ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"].contains(ext) {
            if let image = NSImage(contentsOf: url) {
                self.previewImage = image
                self.firstFrame = image
                self.lastFrame = image
            }
        } else if ["mp4", "mov", "avi", "m4v", "mkv"].contains(ext) {
            extractVideoFrames(from: url)
        }

        DispatchQueue.main.async {
            if ["mp4", "mov", "avi", "m4v", "mkv"].contains(ext) {
                self.statusMessage = LocalizedStrings.current.extractingFrames
            } else if ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"].contains(ext) {
                self.statusMessage = LocalizedStrings.current.imageSelected
            } else {
                self.statusMessage = LocalizedStrings.current.unsupportedFormat
                self.selectedMediaURL = nil
                self.previewImage = nil
                self.firstFrame = nil
                self.lastFrame = nil
            }
        }
    }

    private func generateThumbnail(from url: URL) -> NSImage? {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        do {
            let cgImage = try generator.copyCGImage(at: .zero, actualTime: nil)
            return NSImage(cgImage: cgImage, size: .zero)
        } catch {
            return nil
        }
    }
    
    private func extractVideoFrames(from url: URL) {
        let asset = AVURLAsset(url: url)
        let generator = AVAssetImageGenerator(asset: asset)
        generator.appliesPreferredTrackTransform = true
        generator.requestedTimeToleranceAfter = .zero
        generator.requestedTimeToleranceBefore = .zero
        
        DispatchQueue.global(qos: .userInitiated).async {
            asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                var error: NSError?
                let status = asset.statusOfValue(forKey: "duration", error: &error)
                
                if status == .loaded {
                    let duration = asset.duration
                    let durationSeconds = CMTimeGetSeconds(duration)
                    
                    let firstFrameTime = CMTime.zero
                    let lastFrameTime = CMTime(seconds: max(0, durationSeconds - 0.1), preferredTimescale: 600)
                    
                    let times = [NSValue(time: firstFrameTime), NSValue(time: lastFrameTime)]
                    
                    var extractedImages: [NSImage] = []
                    
                    generator.generateCGImagesAsynchronously(forTimes: times) { (requestedTime, cgImage, actualTime, result, error) in
                        if let cgImage = cgImage {
                            let nsImage = NSImage(cgImage: cgImage, size: .zero)
                            extractedImages.append(nsImage)
                            
                            DispatchQueue.main.async {
                                if CMTimeCompare(requestedTime, firstFrameTime) == 0 {
                                    self.firstFrame = nsImage
                                    self.previewImage = nsImage
                                } else {
                                    self.lastFrame = nsImage
                                }
                                
                                if self.firstFrame != nil && self.lastFrame != nil {
                                    self.statusMessage = LocalizedStrings.current.videoSelected
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.statusMessage = LocalizedStrings.current.frameExtractionFailed
                            }
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self.statusMessage = LocalizedStrings.current.videoAnalysisFailed
                        if let thumbnail = self.generateThumbnail(from: url) {
                            self.firstFrame = thumbnail
                            self.lastFrame = thumbnail
                            self.previewImage = thumbnail
                        }
                    }
                }
            }
        }
    }

    private func applyWallpaper() {
        guard let url = selectedMediaURL else {
            statusMessage = LocalizedStrings.current.pleaseSelectFile
            return
        }

        let fileExtension = url.pathExtension.lowercased()

        if ["mp4", "mov", "avi", "m4v", "mkv"].contains(fileExtension) {
            statusMessage = LocalizedStrings.current.settingVideoWallpaper
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.wallpaperManager.setVideoWallpaper(
                    from: url,
                    for: self.selectedDisplayID,
                    transitionType: self.selectedTransitionType,
                    transitionDuration: self.transitionDuration,
                    scale: self.scale,
                    offset: self.offset
                ) { success in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        let displayInfo = self.selectedDisplayID != nil ? LocalizedStrings.current.toSelectedDisplay : LocalizedStrings.current.toAllDisplays
                        self.statusMessage = success ? "\(LocalizedStrings.current.videoWallpaperSuccess)\(displayInfo)" : LocalizedStrings.current.wallpaperSetFailed
                    }
                }
            }
        } else if ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"].contains(fileExtension) {
            statusMessage = LocalizedStrings.current.settingImageWallpaper
            if wallpaperManager.setImageWallpaper(from: url, for: selectedDisplayID, scale: scale, offset: offset) {
                let displayInfo = selectedDisplayID != nil ? LocalizedStrings.current.toSelectedDisplay : LocalizedStrings.current.toAllDisplays
                statusMessage = "\(LocalizedStrings.current.imageWallpaperSuccess)\(displayInfo)"
            } else {
                statusMessage = LocalizedStrings.current.wallpaperSetFailed
            }
        }
    }
    

    

    
    private func handleSystemWallpaperSelection(_ wallpaper: SystemWallpaper) {
        selectedSystemWallpaper = nil
        
        let fileURL: URL
        if wallpaper.isDynamic, let videoPath = wallpaper.videoPath {
            fileURL = URL(fileURLWithPath: videoPath)
        } else {
            fileURL = URL(fileURLWithPath: wallpaper.fullResolutionPath)
        }
        
        selectedMediaURL = fileURL
        handleFileSelection(url: fileURL)
        statusMessage = "\(LocalizedStrings.current.imageSelected): \(wallpaper.displayName)"
    }
    
    private func handleWebWallpaperURLAndApply(_ urlString: String) {
        guard let url = URL(string: urlString), 
              url.scheme == "http" || url.scheme == "https" else {
            statusMessage = LocalizedStrings.current.invalidURL
            return
        }
        
        webWallpaperURL = urlString
        statusMessage = "Web wallpaper feature under development"
        
        WebWallpaperService.shared.openWebBrowser(url: url)
    }

    


}
