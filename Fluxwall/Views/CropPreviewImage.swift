//
//  CropPreviewImage.swift
//  Fluxwall
//
//  Created by ylin766 on 2025/7/24.
//


// CropPreviewImage.swift

import SwiftUI

struct CropPreviewImage: View {
    let image: NSImage
    let scale: CGFloat
    let offset: CGSize
    let targetDisplaySize: CGSize  // Actual display size

    var body: some View {
        GeometryReader { proxy in
            // Use the same transformation logic as actual wallpaper
            CropPreviewImageLayer(
                image: image,
                scale: scale,
                offset: offset,
                containerSize: proxy.size,
                targetDisplaySize: targetDisplaySize
            )
            .frame(width: proxy.size.width, height: proxy.size.height)
            .clipped()
        }
    }
}

// Use NSViewRepresentable to precisely simulate Core Animation transformations
struct CropPreviewImageLayer: NSViewRepresentable {
    let image: NSImage
    let scale: CGFloat
    let offset: CGSize
    let containerSize: CGSize
    let targetDisplaySize: CGSize  // Actual display size
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // Clear existing sublayers
        nsView.layer?.sublayers?.removeAll()
        
        // Create image layer
        let imageLayer = CALayer()
        imageLayer.contents = image
        imageLayer.frame = CGRect(origin: .zero, size: containerSize)
        imageLayer.contentsGravity = .resizeAspectFill
        
        // Apply the exact same transformation logic as actual wallpaper
        var transform = CATransform3DIdentity
        transform = CATransform3DScale(transform, scale, scale, 1.0)
        
        // Relative position mapping logic:
        // offset is the value in actual display coordinate system
        // We need to convert it to relative position in preview container for correct display
        
        // Calculate relative position (percentage)
        let relativeOffsetX = offset.width / targetDisplaySize.width
        let relativeOffsetY = offset.height / targetDisplaySize.height
        
        // Apply relative position to preview container coordinates
        let mappedOffsetX = relativeOffsetX * containerSize.width
        let mappedOffsetY = relativeOffsetY * containerSize.height
        
        // Use the exact same coordinate system correction as in WallpaperManager
        let adjustedOffsetX = mappedOffsetX
        let adjustedOffsetY = -mappedOffsetY  // Invert Y axis to match actual wallpaper
        transform = CATransform3DTranslate(transform, adjustedOffsetX, adjustedOffsetY, 0)
        
        imageLayer.transform = transform
        
        // Add to view layer
        nsView.layer?.addSublayer(imageLayer)
    }
}
