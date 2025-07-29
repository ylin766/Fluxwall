//
//  DragDropView.swift
//  Fluxwall
//
//  Created by Kiro on 2025/7/22.
//

import SwiftUI
import AppKit

// 支持拖拽的NSView
class DragDropView: NSView {
    
    // 拖拽回调
    var onFilesDropped: (([URL]) -> Void)?
    
    // 视觉状态
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
        // 注册拖拽类型
        registerForDraggedTypes([.fileURL])
        
        // 设置视图属性
        wantsLayer = true
        layer?.cornerRadius = 12
        updateAppearance()
    }
    
    private func updateAppearance() {
        if isDragOver {
            // 高亮状态 - 蓝色边框和淡蓝色背景
            layer?.backgroundColor = NSColor.systemBlue.withAlphaComponent(0.15).cgColor
            layer?.borderColor = NSColor.systemBlue.cgColor
            layer?.borderWidth = 3
            
            // 添加阴影效果
            layer?.shadowOpacity = 0.3
            layer?.shadowRadius = 5
            layer?.shadowOffset = CGSize(width: 0, height: 2)
            layer?.shadowColor = NSColor.black.cgColor
        } else {
            // 正常状态 - 淡灰色边框和透明背景
            layer?.backgroundColor = NSColor.controlBackgroundColor.cgColor
            layer?.borderColor = NSColor.separatorColor.cgColor
            layer?.borderWidth = 2
            
            // 轻微阴影
            layer?.shadowOpacity = 0.1
            layer?.shadowRadius = 3
            layer?.shadowOffset = CGSize(width: 0, height: 1)
            layer?.shadowColor = NSColor.black.cgColor
        }
    }
    
    // MARK: - 拖拽处理
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        // 检查是否包含文件URL
        guard sender.draggingPasteboard.canReadObject(forClasses: [NSURL.self], options: nil) else {
            return []
        }
        
        // 检查文件类型
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
        
        // 过滤支持的文件类型
        let supportedExtensions = ["mp4", "mov", "avi", "m4v", "mkv", "jpg", "jpeg", "png", "gif", "bmp", "tiff"]
        let validUrls = urls.filter { url in
            supportedExtensions.contains(url.pathExtension.lowercased())
        }
        
        if !validUrls.isEmpty {
            // 添加一个简单的动画效果
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

            
            // 调用回调
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

// SwiftUI 包装器
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
