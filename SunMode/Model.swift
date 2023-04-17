// 04.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI

class Model: ObservableObject {
    @Published var systemAppearance: SystemAppearances = .light
    @Published var systemAppearance2: SystemAppearances = .light
    @AppStorage("mode") var mode: Modes = .none
    @AppStorage("menuBarIconAdvanced") var menuBarIconAdvanced: Bool = true
    
    @Published var coord: Coordinates = (try? PropertyListDecoder().decode(Coordinates.self, from: UserDefaults.standard.value(forKey: "coord") as? Data ?? Data())) ?? Coordinates()
    @Published var hueV1: HueV1 = (try? PropertyListDecoder().decode(HueV1.self, from: UserDefaults.standard.value(forKey: "hueV1") as? Data ?? Data())) ?? HueV1()
    @Published var staticTime: StaticTime = (try? PropertyListDecoder().decode(StaticTime.self, from: UserDefaults.standard.value(forKey: "staticTime") as? Data ?? Data())) ?? StaticTime()
    
    @Published var refreshTimer: Timer? = nil       /// timer for refreshing external sensor data
    @Published var appearanceTimer: Timer? = nil    /// timer for triggering next mode change
    
    /// Debugging saved values
    // init() {
    //     print("coord")
    //     guard let uD: Data = UserDefaults.standard.value(forKey: "coord") as? Data else {
    //         print("data error")
    //         return
    //     }
    //     do {
    //         coord = try PropertyListDecoder().decode(Coordinates.self, from: uD)
    //         print("succ")
    //     } catch {
    //         print("dfasfd \(error)")
    //     }
    //
    //     print("huev1")
    //     guard let uD: Data = UserDefaults.standard.value(forKey: "hueV1") as? Data else {
    //         print("data error")
    //         return
    //     }
    //     do {
    //         hueV1 = try PropertyListDecoder().decode(HueV1.self, from: uD)
    //         print("succ")
    //     } catch {
    //         print("dfasfd \(error)")
    //     }
    //
    //     print("statictime")
    //     guard let uD: Data = UserDefaults.standard.value(forKey: "staticTime") as? Data else {
    //         print("data error")
    //         return
    //     }
    //     do {
    //         staticTime = try PropertyListDecoder().decode(StaticTime3.self, from: uD)
    //         print("succ")
    //     } catch {
    //         print("dfasfd \(error)")
    //     }
    // }
    
    enum Modes: String, CaseIterable {
        case none = "Off"
        case hueV1 = "Hue V1"
        case coord = "Coordinates"
        case staticTime = "Static Time"
    }
    
    func startMode() {
        print("startMode")
        appearanceTimer?.invalidate()
        refreshTimer?.invalidate()
        
        var modeAppearance: SystemAppearances?
        var nextAppearance: (TimeInterval, SystemAppearances)?
        var nextRefreshInterval: TimeInterval?
        
        /// check current Appearance and set interval, so timer gets started
        switch mode {
            case .none:
                modeAppearance = getSystemAppearance()
                return
            case .coord:
                modeAppearance = coord.currAppearance
                nextAppearance = coord.nextAppearance
            case .hueV1:
                modeAppearance = hueV1.currAppearance
                nextRefreshInterval = TimeInterval(hueV1.refreshInterval * 60)
            case .staticTime:
                modeAppearance = staticTime.currAppearance
                nextAppearance = staticTime.nextAppearance
        }
        
        /// set current appearance to correct mode appearance
        if let newAppearance = modeAppearance {
            systemAppearance = newAppearance
        }
        
        
        /// use if (instead of guard) so both optional variables get checked & only set timer if interval is given
        if let (interval, appearance) = nextAppearance {
            appearanceTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { timer in
                self.systemAppearance = appearance
                
                timer.invalidate()
                NSLog("appearanceTimer invalidated")
                
                /// init new timer 10 sec later
                DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
                    self.startMode()
                }
            })
            appearanceTimer?.tolerance = 10
            NSLog("\(appearance) at: \(Date.init(timeIntervalSinceNow: interval))")
        }
        
        if let nextRefreshInterval = nextRefreshInterval {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: nextRefreshInterval, repeats: true, block: { timer in
                switch self.mode {
                    case .hueV1:
                        if let newAppearance = modeAppearance {
                            self.systemAppearance = newAppearance
                        }
                    default:
                        NSLog("no mode found")
                }
            })
            refreshTimer?.tolerance = 10
            NSLog("\(String(describing: modeAppearance)) refresh: \(Date.init(timeIntervalSinceNow: nextRefreshInterval))")
        }
    }
}

// MARK: System Functions
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
