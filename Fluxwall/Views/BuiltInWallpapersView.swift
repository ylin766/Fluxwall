import SwiftUI

enum WallpaperDisplayCategory: String, CaseIterable {
    case dynamic = "Dynamic"
    case staticWallpaper = "Static"
    
    var localizedName: String {
        switch self {
        case .dynamic:
            return LocalizedStrings.current.dynamicWallpapers
        case .staticWallpaper:
            return LocalizedStrings.current.staticWallpapers
        }
    }
}

struct BuiltInWallpapersView: View {
    @StateObject private var wallpaperIndexer = WallpaperIndexer.shared
    @State private var selectedCategory: WallpaperDisplayCategory = .dynamic
    @State private var selectedWallpaper: SystemWallpaper?
    
    let onWallpaperSelected: (SystemWallpaper) -> Void
    
    var filteredWallpapers: [SystemWallpaper] {
        switch selectedCategory {
        case .dynamic:
            return wallpaperIndexer.availableWallpapers.filter { $0.category == .dynamic }
        case .staticWallpaper:
            return wallpaperIndexer.availableWallpapers.filter { $0.category == .staticWallpaper }
        }
    }
    
    var body: some View {
        VStack(spacing: 8) {
            // Category selector
            categorySelector
            
            // Wallpaper grid
            wallpaperGrid
        }
    }
    
    @ViewBuilder
    private var categorySelector: some View {
        HStack(spacing: 8) {
            ForEach(WallpaperDisplayCategory.allCases, id: \.self) { category in
                Button(action: {
                    selectedCategory = category
                }) {
                    Text(category.localizedName)
                        .font(.system(size: 12, weight: .medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .foregroundColor(selectedCategory == category ? .white : .primary)
                        .flatButton(
                            isSelected: selectedCategory == category,
                            cornerRadius: ModernDesignSystem.CornerRadius.small,
                            borderIntensity: selectedCategory == category ? 1.0 : 0.6
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
            Spacer()
        }
    }
    
    @ViewBuilder
    private var wallpaperGrid: some View {
        if wallpaperIndexer.isLoading {
            VStack {
                ProgressView()
                    .scaleEffect(0.8)
                Text("Scanning system wallpapers...")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: 4), spacing: 20) {
                    ForEach(filteredWallpapers) { wallpaper in
                        SystemWallpaperThumbnailView(
                            wallpaper: wallpaper,
                            isSelected: selectedWallpaper?.id == wallpaper.id
                        ) {
                            selectedWallpaper = wallpaper
                            onWallpaperSelected(wallpaper)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }
            .frame(maxHeight: .infinity)
        }
    }
}

struct SystemWallpaperThumbnailView: View {
    let wallpaper: SystemWallpaper
    let isSelected: Bool
    let onTap: () -> Void
    
    @State private var thumbnailImage: NSImage?
    @State private var imageAspectRatio: CGFloat = 16.0/10.0 // Default aspect ratio
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 12) {
                // Thumbnail container with dynamic aspect ratio based on actual image
                Group {
                    if let thumbnailImage = thumbnailImage {
                        Image(nsImage: thumbnailImage)
                            .resizable()
                            .aspectRatio(imageAspectRatio, contentMode: .fit)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .overlay(
                                // Selection border - matches the actual image shape
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                            )
                    } else {
                        // Placeholder with default aspect ratio
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(.controlBackgroundColor))
                            .aspectRatio(imageAspectRatio, contentMode: .fit)
                            .overlay(
                                VStack(spacing: 4) {
                                    Image(systemName: wallpaper.isDynamic ? "sun.and.horizon.fill" : "photo.fill")
                                        .font(.system(size: 20))
                                        .foregroundColor(.secondary)
                                    
                                    if wallpaper.isDynamic {
                                        Image(systemName: "play.circle.fill")
                                            .font(.system(size: 12))
                                            .foregroundColor(.blue)
                                    }
                                }
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                            )
                    }
                }
                
                // Wallpaper name - separated from image with more spacing
                Text(wallpaper.displayName)
                    .font(.system(size: 11, weight: .medium))
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .frame(height: 28) // Fixed height for consistent spacing
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            loadThumbnail()
        }
    }
    
    private func loadThumbnail() {
        guard let thumbnailPath = wallpaper.thumbnailPath else { return }
        
        DispatchQueue.global(qos: .userInitiated).async {
            if let image = NSImage(contentsOfFile: thumbnailPath) {
                let aspectRatio = image.size.width / image.size.height
                
                DispatchQueue.main.async {
                    self.thumbnailImage = image
                    self.imageAspectRatio = aspectRatio
                }
            }
        }
    }
}

