// 09.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI
import Foundation

struct HueV1: Codable {
    struct Sensor: Codable {
        let lightlevel: Int
        let dark: Bool
        let daylight: Bool
        let lastupdated: String
        let tholddark: Int
    }
    var ipAddress: String = ""
    var apiKey: String = ""
    var sensorNumber: Int = 0
    
    var useBridgeThreshold: Bool = true
    var customThreshold: Int = 4500
    
    var refreshInterval: Int = 5
    
    var sensorData: Sensor?
    var restartMode: Bool = false   /// single variable for onChange to subscribe to, instead of each single variable seperately
    
    var currAppearance: SystemAppearances? {
        // guard let currSensor = self.sensorData else { return nil }
        guard let currSensor: Sensor = getSensorStatus() else { return nil }
        
        if useBridgeThreshold {
            return currSensor.dark ? .dark : .light
        } else {
            return currSensor.lightlevel < customThreshold ? .dark : .light
        }
    }
    
    private func getSensorStatus() -> Sensor? {
        var result: Sensor? = nil
        
        let url = URL(string: "http://\(ipAddress)/api/\(apiKey)/sensors/\(sensorNumber)")!
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let data = data, error == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data)  as? [String: Any]
                    // NSLog("-------- json: --------")
                    // NSLog(json)
                    
                    /// parse values
                    if let state = json?["state"] as? [String: Any],
                       let lightlevel: Int = state["lightlevel"] as? Int,
                       let dark: Bool = state["dark"] as? Bool,
                       let daylight: Bool = state["daylight"] as? Bool,
                       let lastupdated: String = state["lastupdated"] as? String,
                       let config = json?["config"] as? [String: Any],
                       let tholddark: Int = config["tholddark"] as? Int {
                        /// all values were found
                        result = Sensor(lightlevel: lightlevel, dark: dark, daylight: daylight, lastupdated: lastupdated, tholddark: tholddark)
                    }
                } catch {
                    NSLog("-------- json error: --------")
                    NSLog(String(describing: error))
                }
            } else {
                /// urlsession error
                NSLog("-------- error: --------")
                NSLog(error?.localizedDescription ?? "no error received")
                NSLog("-------- response: --------")
                NSLog(String(describing: response))
                NSLog("-------- data: --------")
                NSLog(String(decoding: data ?? Data(), as: UTF8.self))
            }
        }).resume()

        return result
    }
}

// MARK: HueV1 Inputs
struct HueV1Inputs: View {
    @Binding var hueV1: HueV1
    
    var body: some View {
        LabeledContent("Refresh Interval (min)", content: {
            TextField("Refresh Interval (min)", value: $hueV1.refreshInterval, format: .number)
                .textFieldStyle(.custom)
        })
        
        Divider()
            .onChange(of: hueV1.ipAddress, perform: saveChange)
            .onChange(of: hueV1.apiKey, perform: saveChange)
            .onChange(of: hueV1.sensorNumber, perform: saveChange)
            .onChange(of: hueV1.useBridgeThreshold, perform: saveChange)
            .onChange(of: hueV1.customThreshold, perform: saveChange)
            .onChange(of: hueV1.refreshInterval, perform: saveChange)
        
        LabeledContent("Bridge IP", content: {
            TextField("Bridge IP", text: $hueV1.ipAddress, prompt: Text("192.168.x.x"))
                .textFieldStyle(.custom)
        })
        LabeledContent("API Key", content: {
            TextField("API Key", text: $hueV1.apiKey)
                .textFieldStyle(.custom)
        })
        LabeledContent("Sensor number", content: {
            TextField("Sensor number", value: $hueV1.sensorNumber, format: .number)
                .textFieldStyle(.custom)
        })
        
        Divider()
        
        Picker("Threshold", selection: $hueV1.useBridgeThreshold, content: {
            Text("Hue Bridge").tag(true)
            Text("Custom").tag(false)
        })
        .pickerStyle(.segmented)
        
        if !hueV1.useBridgeThreshold {
            LabeledContent("Threshold Value", content: {
                TextField("Threshold Value", value: $hueV1.customThreshold, format: .number)
                    .textFieldStyle(.custom)
            })
        } else {
            LabeledContent("Threshold Value", content: {
                TextField("Threshold Value", value: .constant(hueV1.sensorData?.tholddark ?? 0), format: .number)
                    .disabled(true)
                    .textFieldStyle(.custom)
            })
        }
    }
    
    // MARK: Functions
    private func saveChange(_ any: any Equatable) {
        hueV1.restartMode.toggle()
        UserDefaults.standard.set(try? PropertyListEncoder().encode(hueV1), forKey: "hueV1")
    }
}

// MARK: HueV1 Info
struct HueV1Info: View {
    let refreshTimer: Timer?
    let sensorData: HueV1.Sensor?
    
    @State private var updateViewTimer: Timer?
    @State private var now: Date = Date.now
    
    var body: some View {
        HStack(content: {
            Image(systemName: "clock.arrow.2.circlepath")
            
            if let fireDate: Date = refreshTimer?.fireDate {
                Text(Formatter.relativeDateFormatter.localizedString(for: fireDate, relativeTo: now))
                    .onAppear(perform: {
                        updateViewTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(1), repeats: true, block: { _ in now = Date.now })
                    })
                    .onDisappear(perform: { updateViewTimer?.invalidate() })
            } else {
                Text("-")
            }
            
            
            if let sensor: HueV1.Sensor = sensorData {
                Text("\(sensor.lightlevel) lux, at \(ISO8601DateFormatter().date(from: sensor.lastupdated)?.formatted(date: .omitted, time: .standard) ?? "-")")
            } else {
                HStack(content: {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(.red)
                    Text("No Sensor Data")
                })
            }
        })
        .font(.footnote)
    }
}
