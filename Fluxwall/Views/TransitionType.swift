//
//  TransitionType.swift
//  Fluxwall
//
//  Created by ylin766 on 2025/7/25.
//


import Foundation

enum TransitionType: String, CaseIterable, Codable {
    case fade
    case blackout
    
    var description: String {
        switch self {
        case .fade:
            return LocalizedStrings.current.transitionFade
        case .blackout:
            return LocalizedStrings.current.transitionBlackout
        }
    }
}
