import Foundation
import AppKit

struct WallpaperSettings {
    var sourceURL: URL
    var displayID: CGDirectDisplayID?
    
    var scale: CGFloat
    var offset: CGSize                 
    
    var transitionType: TransitionType
    var transitionDuration: Double

    init(
        sourceURL: URL,
        displayID: CGDirectDisplayID? = nil,
        scale: CGFloat = 1.0,
        offset: CGSize = .zero,
        transitionType: TransitionType = .fade,
        transitionDuration: Double = 1.0
    ) {
        self.sourceURL = sourceURL
        self.displayID = displayID
        self.scale = scale
        self.offset = offset
        self.transitionType = transitionType
        self.transitionDuration = transitionDuration
    }
}
