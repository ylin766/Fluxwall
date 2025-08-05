import Foundation
import SwiftUI

// Supported language enumeration
enum SupportedLanguage: String, CaseIterable {
    case chinese = "zh-Hans"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .chinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }
    
    var localizedDisplayName: String {
        switch self {
        case .chinese:
            return LocalizedStrings.current.languageChinese
        case .english:
            return LocalizedStrings.current.languageEnglish
        }
    }
}

// Language settings manager
class LanguageSettings: ObservableObject {
    static let shared = LanguageSettings()
    
    @Published var currentLanguage: SupportedLanguage {
        didSet {
            saveLanguage()
            updateLocalizedStrings()
        }
    }
    
    private init() {
        // Read saved language settings from UserDefaults, default to Chinese
        let savedLanguage = UserDefaults.standard.string(forKey: "selectedLanguage") ?? SupportedLanguage.chinese.rawValue
        self.currentLanguage = SupportedLanguage(rawValue: savedLanguage) ?? .chinese
        updateLocalizedStrings()
    }
    
    private func saveLanguage() {
        UserDefaults.standard.set(currentLanguage.rawValue, forKey: "selectedLanguage")
    }
    
    private func updateLocalizedStrings() {
        LocalizedStrings.current = LocalizedStrings.forLanguage(currentLanguage)
    }
}