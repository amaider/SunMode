// 23.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI

enum SystemAppearances: String, CaseIterable {
    case light = "Light"
    case dark = "Dark"
}

func getSystemAppearance() -> SystemAppearances {
    switch NSApp.effectiveAppearance.bestMatch(from: [.aqua, .darkAqua]) {
        case .aqua?: return .light
        case .darkAqua?: return .dark
        default: return .light
    }
}
func updateSystemMode(to appearance: SystemAppearances?) {
    /// dont update if appearance is already set or nil
    if appearance == getSystemAppearance() { return }
    guard let appearance = appearance else { return }
    
    let script = """
        tell application "System Events" to tell appearance preferences to set dark mode to \(appearance == .dark ? "true" : "false")
    """
    
    let appleScript = NSAppleScript(source: script)
    var errorDict: NSDictionary? = nil
    
    DispatchQueue.global(qos: .background).async {
        let possibleResult = appleScript?.executeAndReturnError(&errorDict)
        if errorDict != nil {
            NSLog("error: \(String(describing: errorDict)), result:\(String(describing: possibleResult))")
        }
    }
}
