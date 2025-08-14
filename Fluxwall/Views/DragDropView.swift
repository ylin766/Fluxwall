//
//  DragDropView.swift
//  Fluxwall
//
//  Created by Kiro on 2025/7/22.
//

import SwiftUI
import AppKit

// NSView that supports drag and drop functionality
class DragDropView: NSView {
    
    // Callback for dropped files
    var onFilesDropped: (([URL]) -> Void)?
    
    // Visual state tracking
    private var isDragOver = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        setupDragAndDrop()
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupDragAndDrop()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDragAndDrop()
    }
    
    private func setupDragAndDrop() {
        // Register drag types
        registerForDraggedTypes([.fileURL])
        
        // Setup view properties
        wantsLayer = true
        layer?.cornerRadius = 12
        updateAppearance()
    }
    
    private func updateAppearance() {
        let isDarkMode = NSApp.effectiveAppearance?.name == .darkAqua
        
        if isDragOver {
            layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.15).cgColor
            layer?.borderColor = NSColor.systemBlue.cgColor
            layer?.borderWidth = 3
            
            layer?.shadowOpacity = isDarkMode ? 0.3 : 0.2
            layer?.shadowRadius = 5
            layer?.shadowOffset = CGSize(width: 0, height: 2)
            layer?.shadowColor = NSColor.black.cgColor
        } else {
            if isDarkMode {
                layer?.backgroundColor = NSColor.clear.cgColor
                layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.3).cgColor
            } else {
                layer?.backgroundColor = NSColor.controlBackgroundColor.withAlphaComponent(0.3).cgColor
                layer?.borderColor = NSColor.separatorColor.withAlphaComponent(0.2).cgColor
            }
            layer?.borderWidth = 1
            
            layer?.shadowOpacity = isDarkMode ? 0.1 : 0.05
            layer?.shadowRadius = 3
            layer?.shadowOffset = CGSize(width: 0, height: 1)
            layer?.shadowColor = NSColor.black.cgColor
        }
    }
    
    // MARK: - Drag and Drop Handling
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // Check if contains file URLs
        guard sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil) else {
            return []
        }
        
        // Check file types
        if let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] {
            let supportedExtensions = ["mp4", "mov", "avi", "m4v", "mkv", "jpg", "jpeg", "png", "gif", "bmp", "tiff"]
            
            for url in urls {
                let fileExtension = url.pathExtension.lowercased()
                if supportedExtensions.contains(fileExtension) {
                    isDragOver = true
                    updateAppearance()
                    return .copy
                }
            }
        }
        
        return []
    }
    
    override func draggingUpdated(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func draggingExited(_ sender: NSDraggingInfo?) {
        isDragOver = false
        updateAppearance()
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        guard let urls = sender.draggingPasteboard.readObjects(forClasses: [NSURL.self], options: nil) as? [URL] else {
            return false
        }
        
        // Filter supported file types
        let supportedExtensions = ["mp4", "mov", "avi", "m4v", "mkv", "jpg", "jpeg", "png", "gif", "bmp", "tiff"]
        let validUrls = urls.filter { url in
            supportedExtensions.contains(url.pathExtension.lowercased())
        }
        
        if !validUrls.isEmpty {
            // Add simple animation effect
            if let layer = self.layer {
                let animation = CABasicAnimation(keyPath: "backgroundColor")
                animation.fromValue = layer.backgroundColor
                animation.toValue = NSColor.systemGreen.withAlphaComponent(0.2).cgColor
                animation.duration = 0.3
                layer.add(animation, forKey: "backgroundColor")
                layer.backgroundColor = NSColor.systemGreen.withAlphaComponent(0.2).cgColor
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.isDragOver = false
                self?.updateAppearance()
            }

            
            // Call callback
            onFilesDropped?(validUrls)
            return true
        }
        
        return false
    }
    
    override func draggingEnded(_ sender: NSDraggingInfo) {
        isDragOver = false
        updateAppearance()
    }
}

// SwiftUI wrapper
struct DragDropArea: NSViewRepresentable {
    var onFilesDropped: ([URL]) -> Void
    
    func makeNSView(context: Context) -> DragDropView {
        let view = DragDropView()
        view.onFilesDropped = onFilesDropped
        return view
    }
    
    func updateNSView(_ nsView: DragDropView, context: Context) {
        nsView.onFilesDropped = onFilesDropped
    }
}
