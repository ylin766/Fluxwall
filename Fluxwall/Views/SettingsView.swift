import SwiftUI

struct SettingsView: View {
    @ObservedObject private var languageSettings = LanguageSettings.shared
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(spacing: 20) {
            // 标题
            HStack {
                Text(LocalizedStrings.current.languageSettings)
                    .font(.system(size: 18, weight: .semibold))
                Spacer()
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            
            Divider()
            
            // 语言选择
            VStack(alignment: .leading, spacing: 12) {
                Text(LocalizedStrings.current.languageSettings)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                VStack(spacing: 8) {
                    ForEach(SupportedLanguage.allCases, id: \.self) { language in
                        Button(action: {
                            languageSettings.currentLanguage = language
                        }) {
                            HStack {
                                Text(language.displayName)
                                    .font(.system(size: 14))
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                if languageSettings.currentLanguage == language {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundColor(.blue)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(languageSettings.currentLanguage == language ? 
                                          Color.blue.opacity(0.1) : Color(.controlBackgroundColor))
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
        .background(Color(.windowBackgroundColor))
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}