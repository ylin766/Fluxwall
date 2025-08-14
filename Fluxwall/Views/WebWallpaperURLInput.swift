//
//  WebWallpaperURLInput.swift
//  Fluxwall
//
//  Created by Kiro on 2025/8/6.
//

import SwiftUI

struct WebWallpaperURLInput: View {
    @State private var urlText: String = ""
    @FocusState private var isTextFieldFocused: Bool
    let onURLSubmitted: (String) -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "globe")
                    .font(.system(size: 14))
                    .foregroundColor(ModernDesignSystem.Colors.infoColor)
                
                TextField(LocalizedStrings.current.enterWebsiteURL, text: $urlText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .font(.system(size: 12))
                    .focused($isTextFieldFocused)
                    .onSubmit {
                        if !urlText.isEmpty {
                            onURLSubmitted(urlText)
                            isTextFieldFocused = false
                        }
                    }
                
                Button(action: {
                    if !urlText.isEmpty {
                        onURLSubmitted(urlText)
                        isTextFieldFocused = false
                    }
                }) {
                    Image(systemName: "arrow.right.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(urlText.isEmpty ? ModernDesignSystem.Colors.tertiaryText : ModernDesignSystem.Colors.infoColor)
                }
                .buttonStyle(PlainButtonStyle())
                .disabled(urlText.isEmpty)
                
                Button(action: {
                    WebWallpaperService.shared.debugWebWallpaper()
                }) {
                    Image(systemName: "ladybug.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ModernDesignSystem.Colors.warningColor)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Debug Web Browser")
                
                Button(action: {
                    WebWallpaperService.shared.closeBrowser()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundColor(ModernDesignSystem.Colors.errorColor)
                }
                .buttonStyle(PlainButtonStyle())
                .help("Close Browser")
            }
        }
        .padding(12)
        .flatCard(cornerRadius: ModernDesignSystem.CornerRadius.large)
        .onTapGesture {
            // Only focus when user explicitly taps on the component
            if !isTextFieldFocused {
                isTextFieldFocused = true
            }
        }
    }
}