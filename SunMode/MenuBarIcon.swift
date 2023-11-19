// 13.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI

struct MenuBarIcon: View {
    @ObservedObject var model: Model
    @AppStorage("menuBarIconAdvanced") var menuBarIconAdvanced: Bool = true
    
    var body: some View {
        if menuBarIconAdvanced {
            switch model.mode {
                case .coord:
                    Label(model.coord.nextChanges.0.formatted(date: .omitted, time: .shortened), systemImage: model.coord.nextChanges.1)
                case .hueV1:
                    if let sensorData: HueV1.SensorData = model.hueV1.sensorData {
                        Text("\(sensorData.lightlevel / 1000) lux")
                    } else {
                        Label(model.mode.rawValue, systemImage: "exclamationmark.triangle")
                    }
                case .hueV2:
                    if let sensorData: HueV2.SensorData = model.hueV2.sensorData {
                        Text("\(sensorData.lightlevel / 1000) lux")
                    } else {
                        Label(model.mode.rawValue, systemImage: "exclamationmark.triangle")
                    }
                case .staticTime:
                    Label(model.staticTime.nextChanges.0.formatted(date: .omitted, time: .shortened), systemImage: model.staticTime.nextChanges.1)
                default:
                    Image(systemName: model.systemAppearance == .dark ? "lightswitch.off" : "lightswitch.on")
            }
        } else {
            Image(systemName: model.systemAppearance == .dark ? "lightswitch.off" : "lightswitch.on")
        }
    }
}

struct MenuBarIcon_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarIcon(model: Model())
    }
}
