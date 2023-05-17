// 09.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI
import Foundation

struct HueV1: Codable {
    struct SensorData: Codable {
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
    
    var sensorData: SensorData?
    var restartMode: Bool = false   /// single variable for onChange ( to restart model.startMode() ) to subscribe to instead of each struct variable seperately
    
    var currAppearance: SystemAppearances? {
        guard let currSensor = self.sensorData else { return nil }
        
        if useBridgeThreshold {
            return currSensor.dark ? .dark : .light
        } else {
            return currSensor.lightlevel < customThreshold ? .dark : .light
        }
    }
    
    struct Bridge: Codable {
        var id: UUID = UUID()
        let name: String
        let ipAddress: String
    }
    struct Sensor: Codable {
        var id: UUID = UUID()
        let name: String
        let number: Int
    }
    var foundBridges: [Bridge] = []
    var foundSensors: [Sensor] = []
    
    
    
    // MARK: Functions
    func getSensorStatus(completion: @escaping (SensorData) -> Void) {
        guard let url = URL(string: "http://\(ipAddress)/api/\(apiKey)/sensors/\(sensorNumber)") else {
            print("fuck url sensor")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let data = data, error == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    // NSLog("-------- json: --------")
                    // NSLog(String(describing: json))
                    
                    /// parse values
                    if let state = json?["state"] as? [String: Any],
                       let lightlevel: Int = state["lightlevel"] as? Int,
                       let dark: Bool = state["dark"] as? Bool,
                       let daylight: Bool = state["daylight"] as? Bool,
                       let lastupdated: String = state["lastupdated"] as? String,
                       let config = json?["config"] as? [String: Any],
                       let tholddark: Int = config["tholddark"] as? Int {
                        
                        /// all values were found
                        let result: SensorData = SensorData(lightlevel: lightlevel, dark: dark, daylight: daylight, lastupdated: lastupdated, tholddark: tholddark)
                        completion(result)
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
                
                /// debug
                // let result: Sensor = Sensor(lightlevel: 1010, dark: true, daylight: false, lastupdated: "2023-10-01T01:01:01Z", tholddark: 16000)
                // completion(result)
            }
        }).resume()
    }
    
    
    /// completion: (success, API Key)
    func createAPIKey(completion: @escaping (Bool, String) -> Void) {
        guard let url: URL = URL(string: "\(self.ipAddress)/api") else {
            completion(false, "no IP Address")
            return
        }
        
        let bodyString = "{\"devicetype\":\"SunMode#MacOS\"}"
        guard let bodyData = bodyString.data(using: .utf8) else { return }
        
        var request: URLRequest = URLRequest(url: url)
        request.httpMethod = "POST"
        request.httpBody = bodyData
        
        URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
            if let data = data, error == nil {
                do {
                    let json2 = try JSONSerialization.jsonObject(with: data) as? [Any]
                    let json = json2?.first as? [String: Any]
                    // NSLog("-------- json: --------")
                    // NSLog(String(describing: json))
                    
                    /// parse values
                    if let error = json?["error"] as? [String: Any],
                       let errorDescription: String = error["description"] as? String {
                        completion(false, errorDescription)
                    } else if let success = json?["success"] as? [String: Any],
                              let apiKey: String = success["username"] as? String {
                        completion(true, apiKey)
                    } else {
                        completion(false, "unknown error")
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
                completion(false, "")
            }
        }).resume()
    }
    
    /// completion: (Name, Sensor Number)
    func findLightSensors(completion: @escaping (String, Int) -> Void) {
        guard let url = URL(string: "http://\(ipAddress)/api/\(apiKey)/sensors/") else {
            print("fuck this url2, no ipAddress or apiKey")
            return
        }
        
        URLSession.shared.dataTask(with: url, completionHandler: { data, response, error in
            if let data = data, error == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    // NSLog("-------- json: --------")
                    // NSLog(String(describing: json))
                    
                    for (key, _) in json ?? [:] {
                        if let sensor = json?[key] as? [String: Any],
                           let name: String = sensor["name"] as? String,
                           let type: String = sensor["type"] as? String,
                           type == "ZLLLightLevel" {
                            guard let sensorNumber: Int = Int(key) else { return }
                            /// got name and sensor number
                            completion(name, sensorNumber)
                        }
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
    }
}

// MARK: HueV1 Inputs
struct HueV1Inputs: View {
    @Binding var hueV1: HueV1
    
    var hueDiscovery: HueBridgeDiscovery = HueBridgeDiscovery()
    
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
        
        LabeledContent(content: {
            TextField("Bridge IP", text: $hueV1.ipAddress, prompt: Text("192.168.x.x"))
                .textFieldStyle(.custom)
        }, label: {
            HStack(content: {
                Text("Bridge IP")
                
                Button(action: findBridgeAction, label: {
                    Image(systemName: "magnifyingglass")
                })
                .buttonStyle(.plain)
                .help("Search for Philips Hue Bridges")
                .sheet(isPresented: .constant(!hueV1.foundBridges.isEmpty), content: { bridgeSheet })
            })
        })
        
        LabeledContent(content: {
            TextField("API Key", text: $hueV1.apiKey)
                .textFieldStyle(.custom)
        }, label: {
            HStack(content: {
                Text("API Key")
                
                Button(action: createAPIKeyAction, label: {
                    Image(systemName: "plus")
                })
                .buttonStyle(.plain)
                .disabled(!hueV1.apiKey.isEmpty)
                .help(hueV1.ipAddress.isEmpty ? "Missing IP Address" : !hueV1.apiKey.isEmpty ? "Delete current API Key to create a new Key" : "Create New API Key")
            })
        })
        
        LabeledContent(content: {
            TextField("Sensor number", value: $hueV1.sensorNumber, format: .number)
                .textFieldStyle(.custom)
        }, label: {
            HStack(content: {
                Text("Sensor Number")
                
                Button(action: findSensorAction, label: {
                    Image(systemName: "magnifyingglass")
                })
                .buttonStyle(.plain)
                .help(hueV1.ipAddress.isEmpty ? "Missing IP Address" : hueV1.apiKey.isEmpty ? "Missing API Key" : "Search for Sensors")
                .disabled(hueV1.ipAddress.isEmpty || hueV1.apiKey.isEmpty)
                .sheet(isPresented: .constant(!hueV1.foundSensors.isEmpty), content: { sensorSheet })
            })
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
    
    
    // MARK: Alerts
    var bridgeSheet: some View {
        VStack(content: {
            HStack(content: {
                HueBridgeIcon(size: 50, version: 0)
                Text(hueV1.foundBridges.isEmpty ? "Searching..." : "Select Bridge")
                    .font(.headline)
            })
            
            ForEach(hueV1.foundBridges, id: \.id, content: { bridge in
                Button(action: {
                    hueV1.ipAddress = bridge.ipAddress
                    
                    hueV1.foundBridges = []
                }, label: {
                    Text("\(bridge.name) - \(bridge.ipAddress)")
                        .frame(minWidth: 0, maxWidth: .infinity)
                })
            })
            
            Divider()
            
            Button(action: {
                hueV1.foundBridges = []
            }, label: {
                Text("Done")
                    .frame(minWidth: 0, maxWidth: .infinity)
            })
            .tint(.red)
        })
        .padding()
        .controlSize(.large)
        .frame(minWidth: 0, maxWidth: .infinity)
    }
    var sensorSheet: some View {
        VStack(content: {
            HStack(content: {
                HueSensorIcon(size: 50)
                Text(hueV1.foundSensors.isEmpty ? "Searching..." : "Select Sensor")
                    .font(.headline)
            })
            
            ForEach(hueV1.foundSensors, id: \.id, content: { sensor in
                Button(action: {
                    hueV1.sensorNumber = sensor.number
                    
                    hueV1.foundSensors = []
                }, label: {
                    Text("\(sensor.name) - \(sensor.number)")
                        .frame(minWidth: 0, maxWidth: .infinity)
                })
            })
            
            Divider()
            
            Button(action: {
                hueV1.foundSensors = []
            }, label: {
                Text("Done")
                    .frame(minWidth: 0, maxWidth: .infinity)
            })
        })
        .padding()
        .controlSize(.large)
        .frame(minWidth: 0, maxWidth: .infinity)
    }
    
    // MARK: Functions
    private func findBridgeAction() {
        hueV1.foundBridges = []
        
        hueDiscovery.startDiscovery(completion: { name, ipAddress in
            let newBridge: HueV1.Bridge = .init(name: name, ipAddress: ipAddress)
            hueV1.foundBridges.append(newBridge)
        })
    }
    private func createAPIKeyAction() {
        hueV1.createAPIKey(completion: { success, apiKey in
            DispatchQueue.main.async(execute: {
                hueV1.apiKey = apiKey
            })
        })
    }
    private func findSensorAction() {
        hueV1.foundSensors = []
        
        hueV1.findLightSensors(completion: { name, sensorNumber in
            let newSensor: HueV1.Sensor = .init(name: name, number: sensorNumber)
            DispatchQueue.main.async(execute: {
                hueV1.foundSensors.append(newSensor)
            })
        })
    }
    private func saveChange(_ any: any Equatable) {
        hueV1.restartMode.toggle()
        UserDefaults.standard.set(try? PropertyListEncoder().encode(hueV1), forKey: "hueV1")
    }
}

// MARK: HueV1 Info
struct HueV1Info: View {
    let refreshTimer: Timer?
    let sensorData: HueV1.SensorData?
    
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
            
            
            if let sensor: HueV1.SensorData = sensorData {
                Text("\(sensor.lightlevel) lux, at \(ISO8601DateFormatter().date(from: sensor.lastupdated + "Z")?.formatted(date: .omitted, time: .standard) ?? "-")")
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
