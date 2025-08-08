import SwiftUI

struct CurrentWallpaperNameView: View {
    @ObservedObject private var wallpaperManager = FluxwallWallpaperManager.shared
    @ObservedObject private var languageSettings = LanguageSettings.shared
    
    private var displayName: String {
        if wallpaperManager.currentWallpaperName == "System Default" || 
           wallpaperManager.currentWallpaperName == "系统默认" {
            return LocalizedStrings.current.systemDefault
        } else {
            return wallpaperManager.currentWallpaperName
        }
    }
    
    var body: some View {
        Text("\(LocalizedStrings.current.currentWallpaper): \(displayName)")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.primary)
            .lineLimit(1)
    }
}