// 04.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI

class Model: ObservableObject {
    @AppStorage("mode") var mode: Modes = .none
    
    @Published var systemAppearance: SystemAppearances = .light
    @Published var refreshTimer: Timer? = nil       /// timer for refreshing external sensor data
    @Published var restartMode: Bool = false        /// onChange restarts the mode loop
    
    /// Modes
    @Published var coord: Coordinates = (try? PropertyListDecoder().decode(Coordinates.self, from: UserDefaults.standard.value(forKey: "coord") as? Data ?? Data())) ?? Coordinates()
    @Published var hueV1: HueV1 = (try? PropertyListDecoder().decode(HueV1.self, from: UserDefaults.standard.value(forKey: "hueV1") as? Data ?? Data())) ?? HueV1()
    @Published var hueV2: HueV2 = (try? PropertyListDecoder().decode(HueV2.self, from: UserDefaults.standard.value(forKey: "hueV2") as? Data ?? Data())) ?? HueV2()
    @Published var staticTime: StaticTime = (try? PropertyListDecoder().decode(StaticTime.self, from: UserDefaults.standard.value(forKey: "staticTime") as? Data ?? Data())) ?? StaticTime()
    enum Modes: String, CaseIterable {
        case none = "Off"
        case coord = "Coordinates"
        case hueV1 = "Hue V1"
        case hueV2 = "Hue V2"
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
        // print("startMode")
        refreshTimer?.invalidate()
        
        /// sets current appropiate system appearance
        switch mode {
            case .none:
                break
            case .coord:
                systemAppearance = coord.currAppearance
                updateSystemMode(to: coord.currAppearance)
            case .hueV1:
                self.hueV1.getSensorStatus(completion: { sensorData in
                    DispatchQueue.main.async(execute: {
                        self.hueV1.sensorData = sensorData
                        
                        if let modeAppearance: SystemAppearances = self.hueV1.currAppearance {
                            self.systemAppearance = modeAppearance
                            updateSystemMode(to: self.systemAppearance)
                        }
                    })
                })
            case .hueV2:
                DispatchQueue.global(qos: .background).async(execute: {
                    self.hueV2.getSensorStatus(completion: { sensorData in
                        DispatchQueue.main.async(execute: {
                            self.hueV2.sensorData = sensorData
                            
                            if let modeAppearance: SystemAppearances = self.hueV2.currAppearance {
                                self.systemAppearance = modeAppearance
                                updateSystemMode(to: self.systemAppearance)
                            }
                        })
                    })
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
            case .hueV2:        interval = TimeInterval(hueV2.refreshInterval * 60)
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
