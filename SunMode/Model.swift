// 04.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI

class Model: ObservableObject {
    @Published var systemAppearance: SystemAppearances = .light
    @AppStorage("mode") var mode: Modes = .none
    @Published var settings: Settings = (try? PropertyListDecoder().decode(Settings.self, from: UserDefaults.standard.value(forKey: "settings") as? Data ?? Data())) ?? Settings()
    // @AppStorage("menuBarIconAdvanced") var menuBarIconAdvanced: Bool = true
    
    @Published var refreshTimer: Timer? = nil       /// timer for refreshing external sensor data
    
    /// Modes
    @Published var coord: Coordinates = (try? PropertyListDecoder().decode(Coordinates.self, from: UserDefaults.standard.value(forKey: "coord") as? Data ?? Data())) ?? Coordinates()
    @Published var hueV1: HueV1 = (try? PropertyListDecoder().decode(HueV1.self, from: UserDefaults.standard.value(forKey: "hueV1") as? Data ?? Data())) ?? HueV1()
    @Published var staticTime: StaticTime = (try? PropertyListDecoder().decode(StaticTime.self, from: UserDefaults.standard.value(forKey: "staticTime") as? Data ?? Data())) ?? StaticTime()
    enum Modes: String, CaseIterable {
        case none = "Off"
        case coord = "Coordinates"
        case hueV1 = "Hue V1"
        case staticTime = "Static Time"
    }
    
    
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
    
    // MARK: Functions
    func startMode() {
        print("startMode")
        refreshTimer?.invalidate()
        
        /// sets current appropiate system appearance
        switch mode {
            case .none:
                break
            case .coord:
                systemAppearance = coord.currAppearance
                updateSystemMode(to: coord.currAppearance)
            case .hueV1:
                hueV1.getSensorStatusCompletion(completion: { sensor in
                    if let modeAppearance = self.hueV1.getCurrAppearanceForCompletion(sensor: sensor) {
                        self.systemAppearance = modeAppearance
                        updateSystemMode(to: modeAppearance)
                    }
                })
            case .staticTime:
                systemAppearance = staticTime.currAppearance
                updateSystemMode(to: staticTime.currAppearance)
        }
        
        /// sets timer for next recursion
        var interval: TimeInterval?
        switch mode {
            case .none:         break
            case .coord:        interval = coord.nextAppearance.0
            case .hueV1:        interval = TimeInterval(hueV1.refreshInterval * 60)
            case .staticTime:   interval = staticTime.nextAppearance.0
        }
        
        if let interval = interval {
            refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false, block: { timer in
                timer.invalidate()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 5, execute: {
                    self.startMode()
                })
            })
            refreshTimer?.tolerance = 10
        }
    }
}
