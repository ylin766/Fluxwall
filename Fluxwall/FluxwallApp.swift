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
        
    }
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .frame(width: 1000, height: 650)
                .onAppear {
                    
                }
                .onDisappear {
                    FluxwallWallpaperManager.shared.stopVideoWallpaper()
                }
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .windowResizability(.contentSize)
        .commands {
            CommandGroup(replacing: .newItem) {}
        }
    }
}