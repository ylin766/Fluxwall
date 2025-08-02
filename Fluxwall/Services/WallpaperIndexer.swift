import Foundation
import AppKit

class WallpaperIndexer: ObservableObject {
    static let shared = WallpaperIndexer()
    
    @Published var availableWallpapers: [SystemWallpaper] = []
    @Published var isLoading = false
    
    private let desktopPicturesPath = "/System/Library/Desktop Pictures"
    private let tvIdleServicesPath = "/System/Library/PrivateFrameworks/TVIdleServices.framework/Versions/A/Resources"
    private let idleAssetsdPath = "/Library/Application Support/com.apple.idleassetsd"
    
    private init() {
        indexWallpapers()
    }
    
    func indexWallpapers() {
        isLoading = true
        
        DispatchQueue.global(qos: .userInitiated).async {
            var wallpapers: [SystemWallpaper] = []
            
            // Scan all wallpapers (static, dynamic, and solid colors)
            wallpapers.append(contentsOf: self.indexStaticWallpapers())
            
            // Index downloaded dynamic wallpapers from idleassetsd
            wallpapers.append(contentsOf: self.indexDownloadedDynamicWallpapers())
            
            // Index additional video wallpapers
            wallpapers.append(contentsOf: self.indexVideoWallpapers())
            
            DispatchQueue.main.async {
                self.availableWallpapers = wallpapers.sorted { $0.displayName < $1.displayName }
                self.isLoading = false
            }
        }
    }
    
    private func indexStaticWallpapers() -> [SystemWallpaper] {
        var wallpapers: [SystemWallpaper] = []
        let fileManager = FileManager.default
        let thumbnailsPath = "\(desktopPicturesPath)/.thumbnails"
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: thumbnailsPath)
            
            for item in contents {
                if item.hasSuffix(".heic") {
                    let thumbnailPath = "\(thumbnailsPath)/\(item)"
                    let displayName = String(item.dropLast(5)) // Remove .heic extension
                    
                    // Check for corresponding dynamic wallpaper first
                    let isDynamic = hasCorrespondingDynamicWallpaper(displayName)
                    
                    if isDynamic, let videoPath = findVideoPath(for: displayName) {
                        // Dynamic wallpaper - use thumbnail for preview, video for application
                        let wallpaper = SystemWallpaper(
                            id: UUID(),
                            name: displayName,
                            displayName: displayName,
                            path: thumbnailPath, // Use thumbnail for preview
                            fullResolutionPath: videoPath, // Use video for actual application
                            thumbnailPath: thumbnailPath,
                            isDynamic: true,
                            category: .dynamic,
                            videoPath: videoPath
                        )
                        wallpapers.append(wallpaper)
                    } else if let fullResolutionPath = findFullResolutionPath(for: displayName) {
                        // Static wallpaper - use thumbnail for preview, full resolution for application
                        let wallpaper = SystemWallpaper(
                            id: UUID(),
                            name: displayName,
                            displayName: displayName,
                            path: thumbnailPath, // Use thumbnail for preview
                            fullResolutionPath: fullResolutionPath, // Use full resolution for application
                            thumbnailPath: thumbnailPath,
                            isDynamic: false,
                            category: .staticWallpaper,
                            videoPath: nil
                        )
                        wallpapers.append(wallpaper)
                    } else {
                        continue
                    }
                }
            }
        } catch {
        }
        
        // Add solid color wallpapers
        wallpapers.append(contentsOf: indexSolidColorWallpapers())
        
        return wallpapers
    }
    
    private func findFullResolutionPath(for displayName: String) -> String? {
        let fileManager = FileManager.default
        
        // First, check if this wallpaper is managed by Mobile Asset System
        // If so, skip it entirely as we can't access full resolution files
        let baseDisplayName = displayName.replacingOccurrences(of: " Light", with: "").replacingOccurrences(of: " Dark", with: "")
        let madeDesktopPath = "\(desktopPicturesPath)/\(baseDisplayName).madesktop"
        
        if fileManager.fileExists(atPath: madeDesktopPath) {
            return nil
        }
        
        // Try to find direct full-resolution files
        let possiblePaths = [
            "\(desktopPicturesPath)/\(displayName).heic",
            "\(desktopPicturesPath)/\(displayName).jpg",
            "\(desktopPicturesPath)/\(displayName).png",
            "\(desktopPicturesPath)/\(displayName) Light.heic",
            "\(desktopPicturesPath)/\(displayName) Dark.heic"
        ]
        
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                return path
            }
        }
        
        return nil
    }
    
    private func indexSolidColorWallpapers() -> [SystemWallpaper] {
        var wallpapers: [SystemWallpaper] = []
        let fileManager = FileManager.default
        let solidColorsPath = "\(desktopPicturesPath)/Solid Colors"
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: solidColorsPath)
            
            for item in contents {
                if item.hasSuffix(".png") && !item.hasPrefix(".") {
                    let fullPath = "\(solidColorsPath)/\(item)"
                    let displayName = String(item.dropLast(4)) // Remove .png extension
                    
                    let wallpaper = SystemWallpaper(
                        id: UUID(),
                        name: displayName,
                        displayName: displayName,
                        path: fullPath,
                        fullResolutionPath: fullPath,
                        thumbnailPath: fullPath,
                        isDynamic: false,
                        category: .staticWallpaper
                    )
                    
                    wallpapers.append(wallpaper)
                }
            }
        } catch {
        }
        
        return wallpapers
    }
    
    private func parseMadeDesktopFile(at path: String) -> MadeDesktopInfo? {
        guard let data = FileManager.default.contents(atPath: path),
              let plist = try? PropertyListSerialization.propertyList(from: data, options: [], format: nil) as? [String: Any] else {
            return nil
        }
        
        let thumbnailPath = plist["thumbnailPath"] as? String
        
        return MadeDesktopInfo(
            mobileAssetID: plist["mobileAssetID"] as? String,
            thumbnailPath: thumbnailPath,
            isDynamic: plist["isDynamic"] as? Bool ?? false,
            isSolar: plist["isSolar"] as? Bool ?? false
        )
    }
    
    private func hasCorrespondingDynamicWallpaper(_ displayName: String) -> Bool {
        let wallpapersPath = "\(desktopPicturesPath)/.wallpapers"
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: wallpapersPath)
            
            for folder in contents {
                let folderPath = "\(wallpapersPath)/\(folder)"
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: folderPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                    // Check if folder name matches display name
                    if folder.lowercased().contains(displayName.lowercased()) || 
                       displayName.lowercased().contains(folder.lowercased()) {
                        let videoContents = try fileManager.contentsOfDirectory(atPath: folderPath)
                        
                        // Check for .mov files
                        for videoFile in videoContents {
                            if videoFile.hasSuffix(".mov") {
                                return true
                            }
                        }
                    }
                }
            }
        } catch {
        }
        
        return false
    }
    
    private func findVideoPath(for displayName: String) -> String? {
        let wallpapersPath = "\(desktopPicturesPath)/.wallpapers"
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: wallpapersPath)
            
            for folder in contents {
                let folderPath = "\(wallpapersPath)/\(folder)"
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: folderPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                    // Check if folder name matches display name
                    if folder.lowercased().contains(displayName.lowercased()) || 
                       displayName.lowercased().contains(folder.lowercased()) {
                        let videoContents = try fileManager.contentsOfDirectory(atPath: folderPath)
                        
                        // Find .mov files, prefer Light version
                        var movFiles: [String] = []
                        for videoFile in videoContents {
                            if videoFile.hasSuffix(".mov") {
                                movFiles.append("\(folderPath)/\(videoFile)")
                            }
                        }
                        
                        // Prefer files containing "Light"
                        for movFile in movFiles {
                            if movFile.contains("Light") {
                                return movFile
                            }
                        }
                        
                        // If no Light version, return first one
                        return movFiles.first
                    }
                }
            }
        } catch {
        }
        
        return nil
    }
    

    
    private func indexDownloadedDynamicWallpapers() -> [SystemWallpaper] {
        var wallpapers: [SystemWallpaper] = []
        let entriesPath = "\(idleAssetsdPath)/Customer/entries.json"
        let snapshotsPath = "\(idleAssetsdPath)/snapshots"
        let videoPath = "\(idleAssetsdPath)/Customer/4KSDR240FPS"
        
        // Check if the paths exist
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: entriesPath),
              fileManager.fileExists(atPath: snapshotsPath),
              fileManager.fileExists(atPath: videoPath) else {
            return wallpapers
        }
        
        // Load entries.json to get wallpaper metadata
        guard let data = fileManager.contents(atPath: entriesPath),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let assets = json["assets"] as? [[String: Any]] else {
            return wallpapers
        }
        
        // Get list of downloaded video files
        do {
            let videoFiles = try fileManager.contentsOfDirectory(atPath: videoPath)
            let downloadedUUIDs = Set(videoFiles.compactMap { fileName in
                // Extract UUID from filename like "03EC0F5E-CCA8-4E0A-9FEC-5BD1CE151182.mov"
                if fileName.hasSuffix(".mov") {
                    return String(fileName.dropLast(4)) // Remove .mov extension
                }
                return nil
            })
            
            // Match downloaded videos with metadata
            for asset in assets {
                guard let id = asset["id"] as? String,
                      downloadedUUIDs.contains(id),
                      let accessibilityLabel = asset["accessibilityLabel"] as? String else {
                    continue
                }
                
                // Check if preview image exists locally
                let previewPath = "\(snapshotsPath)/asset-preview-\(id).jpg"
                let hasLocalPreview = fileManager.fileExists(atPath: previewPath)
                let videoFilePath = "\(videoPath)/\(id).mov"
                
                // Only add wallpapers that have local preview images
                if hasLocalPreview {
                    let wallpaper = SystemWallpaper(
                        id: UUID(),
                        name: accessibilityLabel,
                        displayName: accessibilityLabel,
                        path: previewPath, // Use preview for display
                        fullResolutionPath: videoFilePath, // Use video for application
                        thumbnailPath: previewPath,
                        isDynamic: true,
                        category: .dynamic,
                        videoPath: videoFilePath
                    )
                    
                    wallpapers.append(wallpaper)
                }
            }
            
        } catch {
        }
        
        return wallpapers
    }
    
    private func indexVideoWallpapers() -> [SystemWallpaper] {
        var wallpapers: [SystemWallpaper] = []
        let wallpapersPath = "\(desktopPicturesPath)/.wallpapers"
        let fileManager = FileManager.default
        
        do {
            let contents = try fileManager.contentsOfDirectory(atPath: wallpapersPath)
            
            for folder in contents {
                let folderPath = "\(wallpapersPath)/\(folder)"
                var isDirectory: ObjCBool = false
                
                if fileManager.fileExists(atPath: folderPath, isDirectory: &isDirectory) && isDirectory.boolValue {
                    let videoContents = try fileManager.contentsOfDirectory(atPath: folderPath)
                    
                    // Find all .mov files in this folder
                    let movFiles = videoContents.filter { $0.hasSuffix(".mov") }
                    
                    for movFile in movFiles {
                        let fullPath = "\(folderPath)/\(movFile)"
                        let displayName = "\(folder) - \(String(movFile.dropLast(4)))"
                        
                        // Try to find corresponding thumbnail
                        let thumbnailName = String(movFile.dropLast(4)) + " Thumbnail.png"
                        let thumbnailPath = "\(folderPath)/\(thumbnailName)"
                        
                        // Only add wallpapers that have thumbnails
                        if fileManager.fileExists(atPath: thumbnailPath) {
                            let wallpaper = SystemWallpaper(
                                id: UUID(),
                                name: movFile,
                                displayName: displayName,
                                path: thumbnailPath, // Use thumbnail for preview
                                fullResolutionPath: fullPath, // Use video for application
                                thumbnailPath: thumbnailPath,
                                isDynamic: true,
                                category: .dynamic,
                                videoPath: fullPath
                            )
                            
                            wallpapers.append(wallpaper)
                        }
                    }
                }
            }
        } catch {
        }
        
        return wallpapers
    }

}

// MARK: - Data Models

struct SystemWallpaper: Identifiable, Hashable {
    let id: UUID
    let name: String
    let displayName: String
    let path: String // For display/preview purposes
    let fullResolutionPath: String // For actual wallpaper application
    let thumbnailPath: String?
    let isDynamic: Bool
    let category: WallpaperCategory
    let videoPath: String?
    
    init(id: UUID, name: String, displayName: String, path: String, fullResolutionPath: String? = nil, thumbnailPath: String?, isDynamic: Bool, category: WallpaperCategory, videoPath: String? = nil) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.path = path
        self.fullResolutionPath = fullResolutionPath ?? path // Use path as fallback
        self.thumbnailPath = thumbnailPath
        self.isDynamic = isDynamic
        self.category = category
        self.videoPath = videoPath
    }
    
    enum WallpaperCategory: String, CaseIterable {
        case staticWallpaper = "Static"
        case dynamic = "Dynamic"
        
        var localizedName: String {
            switch self {
            case .staticWallpaper:
                return LocalizedStrings.current.staticWallpapers
            case .dynamic:
                return LocalizedStrings.current.dynamicWallpapers
            }
        }
    }
}

struct MadeDesktopInfo {
    let mobileAssetID: String?
    let thumbnailPath: String?
    let isDynamic: Bool
    let isSolar: Bool
}

