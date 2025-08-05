//
//  DisplaySelectorView.swift
//  Fluxwall
//
//  Created by Kiro on 2025/7/24.
//

import SwiftUI
import AppKit
import IOKit

struct DisplayInfo: Identifiable {
    let id: CGDirectDisplayID
    let name: String
    let resolution: CGSize
    let isMain: Bool
    var thumbnail: NSImage?
}

struct DisplaySelectorView: View {
    @State private var selectedDisplayID: CGDirectDisplayID?
    @Binding var displays: [DisplayInfo]
    
    var onDisplaySelected: ((CGDirectDisplayID) -> Void)?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(LocalizedStrings.current.displaySelection)
                .font(.system(size: 14, weight: .semibold))
                .padding(.bottom, 2)
            
            if displays.isEmpty {
                Text(LocalizedStrings.current.detectingDisplays)
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 8)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(displays) { display in
                            DisplayCard(
                                display: display,
                                isSelected: selectedDisplayID == display.id
                            )
                            .onTapGesture {
                                selectedDisplayID = display.id
                                onDisplaySelected?(display.id)
                            }
                        }
                    }
                    .padding(.horizontal, 3)
                    .padding(.vertical, 6)
                }
            }
        }
        .onAppear {
            loadDisplays()
        }
    }
    
    private func loadDisplays() {
        // Get all connected displays
        var displayIDs: [CGDirectDisplayID] = []
        var displayCount: UInt32 = 0
        
        if CGGetActiveDisplayList(0, nil, &displayCount) == .success {
            displayIDs = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
            if CGGetActiveDisplayList(displayCount, &displayIDs, &displayCount) == .success {
                // Process each display
                var displayInfos: [DisplayInfo] = []
                
                for displayID in displayIDs {
                    let width = CGDisplayPixelsWide(displayID)
                    let height = CGDisplayPixelsHigh(displayID)
                    let isMain = CGDisplayIsMain(displayID) != 0
                    
                    // Get display real name
                    let name = getDisplayName(for: displayID, isMain: isMain)
                    
                    // Create display thumbnail
                    let thumbnail = createDisplayThumbnail(displayID: displayID)
                    
                    let displayInfo = DisplayInfo(
                        id: displayID,
                        name: name,
                        resolution: CGSize(width: width, height: height),
                        isMain: isMain,
                        thumbnail: thumbnail
                    )
                    
                    displayInfos.append(displayInfo)
                }
                
                // Main display comes first
                displayInfos.sort { $0.isMain && !$1.isMain }
                
                // Update state
                self.displays = displayInfos
                
                // Select main display by default
                if let mainDisplay = displayInfos.first(where: { $0.isMain }) {
                    self.selectedDisplayID = mainDisplay.id
                    self.onDisplaySelected?(mainDisplay.id)
                } else if let firstDisplay = displayInfos.first {
                    self.selectedDisplayID = firstDisplay.id
                    self.onDisplaySelected?(firstDisplay.id)
                }
            }
        }
    }
    
    private func getDisplayName(for displayID: CGDirectDisplayID, isMain: Bool) -> String {
        // Try to get the real name of the display
        if let displayName = getDisplayNameFromIOKit(displayID: displayID) {
            // Clean display name, remove unnecessary suffixes
            let cleanedName = cleanDisplayName(displayName)
            
            // If it's main display, add identifier to name
            return isMain ? "\(cleanedName) (\(LocalizedStrings.current.mainDisplay))" : cleanedName
        }
        
        // If unable to get real name, use fallback
        return isMain ? LocalizedStrings.current.mainDisplay : "\(LocalizedStrings.current.display) \(displayID)"
    }
    
    private func cleanDisplayName(_ name: String) -> String {
        var cleanedName = name
        
        // 移除常见的不必要后缀
        let suffixesToRemove = [
            " Display",
            " Monitor",
            " LCD",
            " LED",
            " OLED"
        ]
        
        for suffix in suffixesToRemove {
            if cleanedName.hasSuffix(suffix) {
                cleanedName = String(cleanedName.dropLast(suffix.count))
            }
        }
        
        // 移除多余的空格
        cleanedName = cleanedName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 如果清理后名称为空，返回原始名称
        return cleanedName.isEmpty ? name : cleanedName
    }
    
    private func getDisplayNameFromIOKit(displayID: CGDirectDisplayID) -> String? {
        // 使用NSScreen来获取显示器信息，这是更现代和稳定的方法
        if let screen = NSScreen.screens.first(where: { screen in
            // 通过比较显示器ID来匹配屏幕
            let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID
            return screenNumber == displayID
        }) {
            // 尝试从NSScreen获取显示器名称
            if let displayName = getDisplayNameFromNSScreen(screen: screen) {
                return displayName
            }
        }
        
        // 如果无法从NSScreen获取，尝试使用显示器数据库
        return getDisplayNameFromDatabase(displayID: displayID)
    }
    
    private func getDisplayNameFromNSScreen(screen: NSScreen) -> String? {
        // 尝试从NSScreen的设备描述中获取显示器名称
        let deviceDescription = screen.deviceDescription
        
        // 尝试多个可能的键
        let possibleKeys = [
            "NSDeviceDisplayName",
            "NSScreenDisplayName", 
            "DisplayName"
        ]
        
        for key in possibleKeys {
            if let displayName = deviceDescription[NSDeviceDescriptionKey(key)] as? String {
                let trimmedName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedName.isEmpty {
                    return trimmedName
                }
            }
        }
        
        // 尝试从本地化显示名称获取
        let localizedName = screen.localizedName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !localizedName.isEmpty {
            return localizedName
        }
        
        return nil
    }
    
    private func getDisplayNameFromDatabase(displayID: CGDirectDisplayID) -> String? {
        // 尝试从显示器的分辨率和特征来推断显示器类型
        let width = CGDisplayPixelsWide(displayID)
        let height = CGDisplayPixelsHigh(displayID)
        let isMain = CGDisplayIsMain(displayID) != 0
        
        // 根据分辨率推断可能的显示器类型
        switch (width, height) {
        case (5120, 2880):
            return "5K Display"
        case (6016, 3384):
            return "Pro Display XDR"
        case (4480, 2520):
            return "Studio Display"
        case (2560, 1440):
            return "2K Display"
        case (3840, 2160):
            return "4K Display"
        case (1920, 1080):
            return "Full HD Display"
        case (1680, 1050):
            return "WSXGA+ Display"
        case (1440, 900):
            return "WXGA+ Display"
        case (1366, 768):
            return "HD Display"
        case (1280, 800):
            return "WXGA Display"
        default:
            // 对于未知分辨率，使用通用名称
            if isMain {
                return LocalizedStrings.current.builtInDisplay
            } else {
                return LocalizedStrings.current.externalDisplay
            }
        }
    }
    
    private func createDisplayThumbnail(displayID: CGDirectDisplayID) -> NSImage? {
        // 在实际应用中，这里可以捕获显示器的实际内容作为缩略图
        // 这里我们创建一个简单的示例图像
        let width = CGDisplayPixelsWide(displayID)
        let height = CGDisplayPixelsHigh(displayID)
        let aspectRatio = CGFloat(width) / CGFloat(height)
        
        let thumbnailWidth: CGFloat = 120
        let thumbnailHeight = thumbnailWidth / aspectRatio
        
        let image = NSImage(size: NSSize(width: thumbnailWidth, height: thumbnailHeight))
        image.lockFocus()
        
        // 绘制显示器边框
        NSColor.darkGray.setStroke()
        NSColor(calibratedWhite: 0.2, alpha: 0.1).setFill()
        let borderRect = NSRect(x: 0, y: 0, width: thumbnailWidth, height: thumbnailHeight)
        let borderPath = NSBezierPath(roundedRect: borderRect, xRadius: 4, yRadius: 4)
        borderPath.lineWidth = 2
        borderPath.fill()
        borderPath.stroke()
        
        // 绘制显示器内容区域
        NSColor(calibratedWhite: 0.9, alpha: 0.3).setFill()
        let contentRect = NSRect(x: 4, y: 4, width: thumbnailWidth - 8, height: thumbnailHeight - 8)
        let contentPath = NSBezierPath(roundedRect: contentRect, xRadius: 2, yRadius: 2)
        contentPath.fill()
        
        // 绘制分辨率文本
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        
        let textAttributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 9),
            .foregroundColor: NSColor.darkGray,
            .paragraphStyle: paragraphStyle
        ]
        
        let resolutionText = "\(width) × \(height)"
        let textRect = NSRect(x: 0, y: thumbnailHeight / 2 - 6, width: thumbnailWidth, height: 12)
        resolutionText.draw(in: textRect, withAttributes: textAttributes)
        
        image.unlockFocus()
        return image
    }
}

struct DisplayCard: View {
    let display: DisplayInfo
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 4) {
            if let thumbnail = display.thumbnail {
                Image(nsImage: thumbnail)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 50)
                    .cornerRadius(3)
            } else {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 50)
                    .cornerRadius(3)
                    .overlay(
                        Text("\(Int(display.resolution.width)) × \(Int(display.resolution.height))")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    )
            }
            
            Text(display.name)
                .font(.system(size: 10, weight: .medium))
                .lineLimit(1)
            
            Text("\(Int(display.resolution.width)) × \(Int(display.resolution.height))")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .padding(6)
        .frame(width: 100)
        .glassCard(
            isActive: isSelected,
            cornerRadius: 6,
            shadowStyle: ModernDesignSystem.Shadow.minimal,
            glassIntensity: isSelected ? 1.0 : 0.6
        )
    }
}

