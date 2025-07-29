import Foundation

// 本地化字符串结构
struct LocalizedStrings {
    static var current = LocalizedStrings.forLanguage(.chinese)
    
    // 应用标题和描述
    let appTitle: String
    let appSubtitle: String
    
    // 语言设置
    let languageChinese: String
    let languageEnglish: String
    let languageSettings: String
    
    // 文件选择
    let dragFilesHere: String
    let supportedFormats: String
    let selectFile: String
    let selectWallpaper: String
    let selectWallpaperMessage: String
    
    // 状态消息
    let ready: String
    let videoSelected: String
    let imageSelected: String
    let unsupportedFormat: String
    let settingVideoWallpaper: String
    let settingImageWallpaper: String
    let videoWallpaperSuccess: String
    let imageWallpaperSuccess: String
    let wallpaperSetFailed: String
    let extractingFrames: String
    let frameExtractionFailed: String
    let videoAnalysisFailed: String
    let currentWallpaper: String
    let systemDefault: String
    let restoringWallpaper: String
    let wallpaperRestored: String
    let pleaseSelectFile: String
    let toSelectedDisplay: String
    let toAllDisplays: String
    
    // 显示器选择
    let displaySelection: String
    let allDisplays: String
    let builtInDisplay: String
    let externalDisplay: String
    let display: String
    let detectingDisplays: String
    let mainDisplay: String
    
    // 预览
    let previewPrompt: String
    let restoreSystemWallpaper: String
    
    // 过渡设置
    let transitionSettings: String
    let transitionType: String
    let transitionDuration: String
    let seconds: String
    let applyWallpaper: String
    let videoPreview: String
    let firstFrame: String
    let lastFrame: String
    
    // 过渡类型
    let transitionFade: String
    let transitionBlackout: String
    let transitionSlideLeft: String
    let transitionSlideRight: String
    let transitionSlideUp: String
    let transitionSlideDown: String
    let transitionZoom: String
    
    // 缩放控制
    let scale: String
    let reset: String
    
    // 过渡预览
    let effectPreview: String
    let applied: String
    
    static func forLanguage(_ language: SupportedLanguage) -> LocalizedStrings {
        switch language {
        case .chinese:
            return LocalizedStrings(
                appTitle: "Fluxwall",
                appSubtitle: "为你的桌面带来生命力",
                
                languageChinese: "中文",
                languageEnglish: "English",
                languageSettings: "语言设置",
                
                dragFilesHere: "拖拽文件到此处",
                supportedFormats: "支持: MP4, MOV, JPG, PNG",
                selectFile: "选择文件",
                selectWallpaper: "选择壁纸",
                selectWallpaperMessage: "请选择视频或图片文件作为壁纸",
                
                ready: "准备就绪 - 可以拖拽文件或点击选择",
                videoSelected: "已选择视频文件，点击'应用壁纸'按钮设置",
                imageSelected: "已选择图片文件，点击'应用壁纸'按钮设置",
                unsupportedFormat: "不支持的文件格式",
                settingVideoWallpaper: "正在设置视频壁纸...",
                settingImageWallpaper: "正在设置图片壁纸...",
                videoWallpaperSuccess: "视频壁纸设置成功",
                imageWallpaperSuccess: "图片壁纸设置成功",
                wallpaperSetFailed: "壁纸设置失败",
                extractingFrames: "已选择视频文件，正在提取预览帧...",
                frameExtractionFailed: "视频帧提取失败，但仍可使用",
                videoAnalysisFailed: "视频分析失败，但仍可使用",
                currentWallpaper: "当前壁纸",
                systemDefault: "系统默认",
                restoringWallpaper: "正在恢复系统壁纸...",
                wallpaperRestored: "已恢复系统壁纸",
                pleaseSelectFile: "请先选择文件",
                toSelectedDisplay: "到选定显示器",
                toAllDisplays: "到所有显示器",
                
                displaySelection: "显示器选择",
                allDisplays: "所有显示器",
                builtInDisplay: "内置显示器",
                externalDisplay: "外接显示器",
                display: "显示器",
                detectingDisplays: "正在检测显示器...",
                mainDisplay: "主显示器",
                
                previewPrompt: "请先选择文件以预览",
                restoreSystemWallpaper: "恢复系统壁纸",
                
                transitionSettings: "过渡设置",
                transitionType: "过渡类型",
                transitionDuration: "过渡时长",
                seconds: "秒",
                applyWallpaper: "应用壁纸",
                videoPreview: "视频预览",
                firstFrame: "第一帧",
                lastFrame: "最后一帧",
                
                transitionFade: "淡入淡出",
                transitionBlackout: "黑幕过渡",
                transitionSlideLeft: "左滑",
                transitionSlideRight: "右滑",
                transitionSlideUp: "上滑",
                transitionSlideDown: "下滑",
                transitionZoom: "缩放",
                
                scale: "缩放",
                reset: "还原",
                
                effectPreview: "效果预览",
                applied: "已应用"
            )
            
        case .english:
            return LocalizedStrings(
                appTitle: "Fluxwall",
                appSubtitle: "Bring life to your desktop",
                
                languageChinese: "中文",
                languageEnglish: "English",
                languageSettings: "Language Settings",
                
                dragFilesHere: "Drag files here",
                supportedFormats: "Supports: MP4, MOV, JPG, PNG",
                selectFile: "Select File",
                selectWallpaper: "Select Wallpaper",
                selectWallpaperMessage: "Please select a video or image file as wallpaper",
                
                ready: "Ready - You can drag files or click to select",
                videoSelected: "Video file selected, click 'Apply Wallpaper' to set",
                imageSelected: "Image file selected, click 'Apply Wallpaper' to set",
                unsupportedFormat: "Unsupported file format",
                settingVideoWallpaper: "Setting video wallpaper...",
                settingImageWallpaper: "Setting image wallpaper...",
                videoWallpaperSuccess: "Video wallpaper set successfully",
                imageWallpaperSuccess: "Image wallpaper set successfully",
                wallpaperSetFailed: "Failed to set wallpaper",
                extractingFrames: "Video file selected, extracting preview frames...",
                frameExtractionFailed: "Video frame extraction failed, but still usable",
                videoAnalysisFailed: "Video analysis failed, but still usable",
                currentWallpaper: "Current wallpaper",
                systemDefault: "System Default",
                restoringWallpaper: "Restoring system wallpaper...",
                wallpaperRestored: "System wallpaper restored",
                pleaseSelectFile: "Please select a file first",
                toSelectedDisplay: " to selected display",
                toAllDisplays: " to all displays",
                
                displaySelection: "Display Selection",
                allDisplays: "All Displays",
                builtInDisplay: "Built-in Display",
                externalDisplay: "External Display",
                display: "Display",
                detectingDisplays: "Detecting displays...",
                mainDisplay: "Main Display",
                
                previewPrompt: "Please select a file to preview",
                restoreSystemWallpaper: "Restore System Wallpaper",
                
                transitionSettings: "Transition Settings",
                transitionType: "Transition Type",
                transitionDuration: "Transition Duration",
                seconds: "seconds",
                applyWallpaper: "Apply Wallpaper",
                videoPreview: "Video Preview",
                firstFrame: "First Frame",
                lastFrame: "Last Frame",
                
                transitionFade: "Fade",
                transitionBlackout: "Blackout",
                transitionSlideLeft: "Slide Left",
                transitionSlideRight: "Slide Right",
                transitionSlideUp: "Slide Up",
                transitionSlideDown: "Slide Down",
                transitionZoom: "Zoom",
                
                scale: "Scale",
                reset: "Reset",
                
                effectPreview: "Effect Preview",
                applied: "Applied"
            )
        }
    }
}