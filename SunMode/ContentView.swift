// 06.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI
import CoreLocation

/// locationManager gets initalized onAppear of CoordinatesInputs and not on MenuBarIcon, test?????, locationManager may get saved in UserDefaults so ignore

struct ContentView: View {
    @ObservedObject var model: Model
    
    @State private var showSettings: Bool = false
    
    var body: some View {
        VStack(content: {
            // MARK: Header
            HStack(content: {
                Menu(content: {
                    ForEach(Model.Modes.allCases, id: \.hashValue) { mode in
                        Button(mode.rawValue, action: {
                            model.mode = mode
                        })
                    }
                }, label: {
                    Text(model.mode.rawValue)
                        .fontWeight(.semibold)
                        .font(.body)
                })
                
                let pickerBinding: Binding<SystemAppearances> = Binding(
                    get: { model.systemAppearance },
                    set: {
                        model.systemAppearance = $0
                        updateSystemMode(to: $0)
                    }
                )
                Picker("System Mode", selection: pickerBinding, content: {
                    ForEach(SystemAppearances.allCases, id: \.self, content: { appearance in
                        Text(appearance.rawValue).tag(appearance)
                    })
                })
                .pickerStyle(.segmented)
                .labelsHidden()
            })
            
            if showSettings {
                // MARK: Settings
                SettingsInputs(settings: $model.settings)
                
            } else {
                // MARK: Inputs
                switch model.mode {
                    case .none:         EmptyView()
                    case .coord:        CoordinatesInputs(coord: $model.coord)
                    case .hueV1:        HueV1Inputs(hueV1: $model.hueV1)
                    case .staticTime:   StaticTimeInputs(staticTime: $model.staticTime)
                }
            }
            
            // MARK: Footer
            HStack(content: {
                Spacer()
                
                // MARK: Info
                Group(content: {
                    switch model.mode {
                        case .coord:
                            CoordinatesInfo(nextChanges: model.coord.nextChanges)
                        case .hueV1:
                            Button(action: model.startMode, label: {
                                HueV1Info(refreshTimer: model.refreshTimer, sensorData: model.hueV1.sensorData)
                            })
                            .buttonStyle(.plain)
                            .help(model.hueV1.sensorData == nil ? "-" : "lightlevel: \(model.hueV1.sensorData!.lightlevel)\ndark: \(model.hueV1.sensorData!.dark ? "true":"false")\ndaylight: \(model.hueV1.sensorData!.daylight ? "true":"false")\nlastupdated: \(model.hueV1.sensorData!.lastupdated)\ntholddark: \(model.hueV1.sensorData!.tholddark)")
                        case .staticTime:
                            StaticTimeInfo(nextChanges: model.staticTime.nextChanges)
                        default:
                            Text("-")
                    }
                })
                .foregroundColor(.gray)
                .font(.subheadline)
                
                Spacer()
                
                Button(action: {
                    showSettings.toggle()
                }, label: {
                    Image(systemName: showSettings ? "chevron.left.square" : "gear")
                })
            })
            .buttonStyle(.link)
        })
        .formStyle(.grouped)
        .padding(8)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(model: Model())
            .frame(width: 300, height: 300)
    }
}
