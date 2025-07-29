//
//  FluxwallApp.swift
//  Fluxwall
//
//  Created by ylin766 on 2025/7/22.
//

import SwiftUI
import Foundation

@main
struct FluxwallApp: App {
    init() {
        // 应用启动时记录日志
        print("========== Fluxwall应用程序启动 ==========")
        print("系统信息: \(ProcessInfo.processInfo.operatingSystemVersionString)")
        print("屏幕数量: \(NSScreen.screens.count)")
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(width: 1000, height: 650) // 固定窗口大小 - 轻量化设计
                .onAppear {
                    print("主视图已显示")
                }
                .onDisappear {
                    print("主视图即将消失，清理资源")
                    // 应用关闭时清理资源
                    FluxwallWallpaperManager.shared.stopVideoWallpaper()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize) // 禁用窗口大小调整
        .commands {
            // 移除默认的窗口菜单项
            CommandGroup(replacing: .newItem) {}
        }
    }
}