// 06.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI
import CoreLocation

struct ContentView: View {
    @ObservedObject var model: Model
    
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
                
                Picker("System Mode", selection: $model.systemAppearance, content: {
                    ForEach(SystemAppearances.allCases, id: \.self, content: { appearance in
                        Text(appearance.rawValue).tag(appearance)
                    })
                })
                .pickerStyle(.segmented)
                .labelsHidden()
            })
            
            // MARK: Inputs
            switch model.mode {
                case .none:         EmptyView()
                case .coord:        CoordinatesInputs(coord: $model.coord)
                case .hueV1:        HueV1Inputs(hueV1: $model.hueV1)
                case .staticTime:   StaticTimeInputs(staticTime: $model.staticTime)
            }
            
            // MARK: Footer
            HStack(content: {
                Toggle(isOn: $model.menuBarIconAdvanced, label: { Text("MenuBarIcon Toggle") })
                    .toggleStyle(.switch)
                    .labelsHidden()
                    .scaleEffect(0.75)
                    .padding(.trailing, -10)
                    .help("MenuBarIcon: show next Sunset/Sunrise or current lightlevel")
                
                Spacer()
                
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
                
                Button("Quit", action: quitAction)
            })
            .buttonStyle(.link)
        })
        .formStyle(.grouped)
        .padding(8)
    }
    
    // MARK: Button actions
    private func toggleAction() {
        model.menuBarIconAdvanced.toggle()
    }
    private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(model: Model())
            .frame(width: 300, height: 300)
    }
}
