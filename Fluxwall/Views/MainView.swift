import SwiftUI
import AppKit
import UniformTypeIdentifiers
import AVKit

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
                .foregroundColor(.secondary)
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
    
    // Calculate if there's a selected wallpaper (user file or system wallpaper)
    private var hasSelectedWallpaper: Bool {
        selectedMediaURL != nil || selectedSystemWallpaper != nil
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title and settings button
            ZStack {
                // Centered title
                VStack(spacing: 4) {
                    Text(LocalizedStrings.current.appTitle)
                        .font(.system(size: 22, weight: .bold))
                    Text(LocalizedStrings.current.appSubtitle)
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                
                // Top-right settings button
                HStack {
                    Spacer()
                    Button(action: {
                        showingSettings = true
                    }) {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.trailing, 20)
                }
            }
            .frame(height: 60)
            .padding(.top, 12)

            GeometryReader { geometry in
                let availableHeight = geometry.size.height - 20
                let columnWidth = (geometry.size.width - 80) / 3

                HStack(alignment: .top, spacing: 20) {
                    VStack(spacing: 12) {
                        displaySelectorPanel()
                            .frame(height: 140)

                        fileSelectionPanel()
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: columnWidth, height: availableHeight)

                    // Middle column: split layout
                    VStack(spacing: 12) {
                        // Top half: built-in wallpapers
                        VStack(spacing: 8) {
                            HStack {
                                Text(LocalizedStrings.current.builtInWallpapers)
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.primary)
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
                        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.windowBackgroundColor)))
                        .frame(maxHeight: .infinity)
                        
                        // Bottom half: crop preview area
                        cropPreviewPanel()
                            .frame(maxHeight: .infinity)
                    }
                    .frame(width: columnWidth, height: availableHeight)

                    transitionSettingsPanel()
                        .frame(width: columnWidth, height: availableHeight)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
            }

            Spacer(minLength: 0)
        }
        .frame(width: 1000, height: 650)
        .onAppear {
            statusMessage = LocalizedStrings.current.ready
        }
        .onChange(of: languageSettings.currentLanguage) { _ in
            // Update status message when language changes
            if !hasSelectedWallpaper {
                statusMessage = LocalizedStrings.current.ready
            }
        }
        .sheet(isPresented: $showingSettings) {
            SettingsView()
        }
    }

    // MARK: - Left Column: File Selection
    @ViewBuilder
    private func fileSelectionPanel() -> some View {
        VStack(spacing: 12) {
            DragDropArea { urls in
                if let firstUrl = urls.first {
                    selectedMediaURL = firstUrl
                    handleFileSelection(url: firstUrl)
                }
            }
            .frame(height: 100)
            .background(RoundedRectangle(cornerRadius: 10).fill(Color(.controlBackgroundColor)))
            .overlay(
                VStack(spacing: 6) {
                    Image(systemName: "arrow.down.doc.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                    Text(LocalizedStrings.current.dragFilesHere).font(.system(size: 13, weight: .medium))
                    Text(LocalizedStrings.current.supportedFormats).font(.system(size: 10)).foregroundColor(.secondary)
                }
            )

            Button(action: selectFile) {
                HStack(spacing: 6) {
                    Image(systemName: "folder.fill").font(.system(size: 14))
                    Text(LocalizedStrings.current.selectFile).font(.system(size: 14, weight: .medium))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
            }
            .buttonStyle(BorderlessButtonStyle())
            .background(RoundedRectangle(cornerRadius: 6).fill(Color.blue))
            .foregroundColor(.white)

            VStack(spacing: 4) {
                Text(statusMessage)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)

                Text("\(LocalizedStrings.current.currentWallpaper): \(wallpaperManager.currentWallpaperName)")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.primary)
                    .lineLimit(1)
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
            .background(RoundedRectangle(cornerRadius: 6).fill(Color(.controlBackgroundColor)))
            .disabled(wallpaperManager.currentWallpaperName == LocalizedStrings.current.systemDefault && !wallpaperManager.isVideoActive)

            Spacer()
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.windowBackgroundColor)))
    }

    // MARK: - Display Selection
    @ViewBuilder
    private func displaySelectorPanel() -> some View {
        DisplaySelectorView(displays: $displays, onDisplaySelected: { displayID in
            selectedDisplayID = displayID
        })
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.windowBackgroundColor)))
    }

    // MARK: - Middle Column: Crop Preview
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
        } else {
            Text(LocalizedStrings.current.previewPrompt)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(RoundedRectangle(cornerRadius: 10).fill(Color(.windowBackgroundColor)))
        }
    }

    // MARK: - Right Column: Transition Settings
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
        .background(RoundedRectangle(cornerRadius: 10).fill(Color(.windowBackgroundColor)))
    }

    // MARK: - File Selection Logic
    private func selectFile() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = LocalizedStrings.current.selectWallpaper
        panel.message = LocalizedStrings.current.selectWallpaperMessage

        if #available(macOS 12.0, *) {
            panel.allowedContentTypes = [
                .mpeg4Movie, .quickTimeMovie, .avi,
                .jpeg, .png, .gif, .bmp, .tiff, .heic
            ]
        } else {
            panel.allowedFileTypes = ["mp4", "mov", "avi", "m4v", "mkv", "jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"]
        }

        panel.begin { response in
            if response == .OK, let url = panel.url {
                self.selectedMediaURL = url
                self.handleFileSelection(url: url)
            }
        }
    }

    private func handleFileSelection(url: URL) {
        // Clear system wallpaper selection
        selectedSystemWallpaper = nil
        
        let ext = url.pathExtension.lowercased()

        if ["jpg", "jpeg", "png", "gif", "bmp", "tiff", "heic"].contains(ext) {
            if let image = NSImage(contentsOf: url) {
                self.previewImage = image
                self.firstFrame = image
                self.lastFrame = image  // For images, first and last frame are the same
            }
        } else if ["mp4", "mov", "avi", "m4v", "mkv"].contains(ext) {
            // Extract first and last frames from video
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
        
        // Extract frames asynchronously to avoid blocking UI
        DispatchQueue.global(qos: .userInitiated).async {
            // First get video duration
            asset.loadValuesAsynchronously(forKeys: ["duration"]) {
                var error: NSError?
                let status = asset.statusOfValue(forKey: "duration", error: &error)
                
                if status == .loaded {
                    let duration = asset.duration
                    let durationSeconds = CMTimeGetSeconds(duration)
                    
                    // Extract first frame (0 seconds)
                    let firstFrameTime = CMTime.zero
                    // Extract last frame (0.1 seconds before end to avoid black frames)
                    let lastFrameTime = CMTime(seconds: max(0, durationSeconds - 0.1), preferredTimescale: 600)
                    
                    let times = [NSValue(time: firstFrameTime), NSValue(time: lastFrameTime)]
                    
                    var extractedImages: [NSImage] = []
                    
                    generator.generateCGImagesAsynchronously(forTimes: times) { (requestedTime, cgImage, actualTime, result, error) in
                        if let cgImage = cgImage {
                            let nsImage = NSImage(cgImage: cgImage, size: .zero)
                            extractedImages.append(nsImage)
                            
                            DispatchQueue.main.async {
                                if CMTimeCompare(requestedTime, firstFrameTime) == 0 {
                                    // This is the first frame
                                    self.firstFrame = nsImage
                                    self.previewImage = nsImage  // Also use as main preview
                                } else {
                                    // This is the last frame
                                    self.lastFrame = nsImage
                                }
                                
                                // Update status when both frames are extracted
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
        // Handle user-selected files (including converted system wallpapers)
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

    


}
