import SwiftUI

struct SettingsView: View {
    @ObservedObject private var languageSettings = LanguageSettings.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // Title
            HStack {
                Text(LocalizedStrings.current.languageSettings)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(ModernDesignSystem.Colors.secondaryText)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            // Language selection
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStrings.current.languageSettings)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(ModernDesignSystem.Colors.secondaryText)
                
                VStack(spacing: 8) {
                    ForEach(SupportedLanguage.allCases, id: \.self) { language in
                        Button(action: {
                            languageSettings.currentLanguage = language
                        }) {
                            HStack {
                                Text(language.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(ModernDesignSystem.Colors.primaryText)
                                
                                Spacer()
                                
                                if languageSettings.currentLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(ModernDesignSystem.Colors.infoColor)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .flatCard(
                                isActive: languageSettings.currentLanguage == language,
                                cornerRadius: ModernDesignSystem.CornerRadius.medium,
                                shadowStyle: ModernDesignSystem.Shadow.minimal,
                                borderIntensity: languageSettings.currentLanguage == language ? 1.2 : 0.8
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(languageSettings.currentLanguage == language ? 
                                           Color.blue : Color.clear, lineWidth: 1)
                            )
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            .padding(.horizontal, 20)
            
            Spacer()
        }
        .frame(width: 300, height: 200)
        .flatCard(cornerRadius: ModernDesignSystem.CornerRadius.extraLarge, shadowStyle: ModernDesignSystem.Shadow.light)
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}