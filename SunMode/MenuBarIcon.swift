// 13.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI

struct MenuBarIcon: View {
    @ObservedObject var model: Model
    
    var iconTuple: (String, String) {
        var iconName: String = model.systemAppearance == .dark ? "lightswitch.off" : "lightswitch.on"
        var iconText: String = ""
        
        switch model.mode {
            case .coord:
                if model.settings.menuBarIconAdvanced {
                    iconName = model.coord.nextChanges.1
                    iconText = model.coord.nextChanges.0.formatted(date: .omitted, time: .shortened)
                }
            case .hueV1:
                guard let sensorData: HueV1.SensorData = model.hueV1.sensorData else {
                    return ("exclamationmark.triangle", model.mode.rawValue)
                }
                if model.settings.menuBarIconAdvanced {
                    iconText = "\(sensorData.lightlevel)lux"
                }
            case .staticTime:
                if model.settings.menuBarIconAdvanced {
                    iconName = model.staticTime.nextChanges.1
                    iconText = model.staticTime.nextChanges.0.formatted(date: .omitted, time: .shortened)
                }
            default: break
        }
        
        return (iconName, iconText)
    }
    
    // MARK: Icon
    var body: some View {
        HStack(content: {
            Image(systemName: iconTuple.0)
            
            if !iconTuple.1.isEmpty {
                Text(iconTuple.1)
            }
        })
    }
}

struct MenuBarIcon_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarIcon(model: Model())
    }
}
