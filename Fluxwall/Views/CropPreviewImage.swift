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
    let targetDisplaySize: CGSize  // 实际显示器尺寸

    var body: some View {
        GeometryReader { proxy in
            // 使用与实际壁纸相同的变换逻辑
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

// 使用 NSViewRepresentable 来精确模拟 Core Animation 的变换
struct CropPreviewImageLayer: NSViewRepresentable {
    let image: NSImage
    let scale: CGFloat
    let offset: CGSize
    let containerSize: CGSize
    let targetDisplaySize: CGSize  // 实际显示器尺寸
    
    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.clear.cgColor
        return view
    }
    
    func updateNSView(_ nsView: NSView, context: Context) {
        // 清除现有的子层
        nsView.layer?.sublayers?.removeAll()
        
        // 创建图像层
        let imageLayer = CALayer()
        imageLayer.contents = image
        imageLayer.frame = CGRect(origin: .zero, size: containerSize)
        imageLayer.contentsGravity = .resizeAspectFill
        
        // 应用与实际壁纸完全相同的变换逻辑
        var transform = CATransform3DIdentity
        transform = CATransform3DScale(transform, scale, scale, 1.0)
        
        // 相对位置映射逻辑：
        // offset 是实际显示器坐标系的值
        // 我们需要将它转换为预览容器中的相对位置来正确显示
        
        // 计算相对位置（百分比）
        let relativeOffsetX = offset.width / targetDisplaySize.width
        let relativeOffsetY = offset.height / targetDisplaySize.height
        
        // 将相对位置应用到预览容器坐标
        let mappedOffsetX = relativeOffsetX * containerSize.width
        let mappedOffsetY = relativeOffsetY * containerSize.height
        
        // 使用与 WallpaperManager 中完全相同的坐标系修正
        let adjustedOffsetX = mappedOffsetX
        let adjustedOffsetY = -mappedOffsetY  // 反转 Y 轴，与实际壁纸保持一致
        transform = CATransform3DTranslate(transform, adjustedOffsetX, adjustedOffsetY, 0)
        
        imageLayer.transform = transform
        
        // 添加到视图层
        nsView.layer?.addSublayer(imageLayer)
    }
}
