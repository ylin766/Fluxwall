import Foundation
import SwiftUI

// 支持的语言枚举
enum SupportedLanguage: String, CaseIterable {
    case chinese = "zh-Hans"
    case english = "en"
    
    var displayName: String {
        switch self {
        case .chinese:
            return "中文"
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

// 语言设置管理器
class LanguageSettings: ObservableObject {
    static let shared = LanguageSettings()
    
    @Published var currentLanguage: SupportedLanguage {
        didSet {
            saveLanguage()
            updateLocalizedStrings()
        }
    }
    
    private init() {
        // 从UserDefaults读取保存的语言设置，默认为中文
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