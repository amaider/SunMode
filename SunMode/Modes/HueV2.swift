// 09.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI
import Foundation

struct HueV2: Codable {
    struct SensorData: Codable {
        let lightlevel: Int
        let changed: String
    }
    var ipAddress: String = ""
    var hueApplicationKey: String = ""
    var rid: String = ""
    
    var customThreshold: Int = 4500
    
    var refreshInterval: Int = 5
    
    var sensorData: SensorData?
    
    var currAppearance: SystemAppearances? {
        guard let currSensor = self.sensorData else { return nil }
        return currSensor.lightlevel < customThreshold ? .dark : .light
    }
    
    struct Bridge: Codable {
        var id: UUID = UUID()
        let name: String
        let ipAddress: String
    }
    struct Sensor: Codable {
        var id: UUID = UUID()
        let name: String
        let rid: String
    }
    var foundBridges: [Bridge] = []
    var foundSensors: [Sensor] = []
    
    
    // MARK: Functions
    func getSensorStatus(completion: @escaping (SensorData) -> Void) {
        guard let url = URL(string: "https://\(ipAddress)/clip/v2/resource/light_level/\(rid)") else {
            print("fuck url sensor, no ipAddress or rid")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(self.hueApplicationKey, forHTTPHeaderField: "hue-application-key")
        
        URLSession(configuration: URLSessionConfiguration.default, delegate: HueAPIv2URLSessioDelegate(), delegateQueue: OperationQueue.current).dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data, error == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    // NSLog("-------- json: --------")
                    // NSLog(String(describing: json))
                    
                    /// parse response
                    if let data: [[String: Any]] = json?["data"] as? [[String: Any]],
                       let light: [String: Any] = data.first?["light"] as? [String : Any],
                       let lightLevelReport: [String: Any] = light["light_level_report"] as? [String: Any],
                       let lightLevel: Int = lightLevelReport["light_level"] as? Int,
                       let changed: String = lightLevelReport["changed"] as? String {
                        /// all values were found
                        let result: SensorData = .init(lightlevel: lightLevel, changed: changed)
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
    func createHueApplicationKey(completion: @escaping (Bool, String) -> Void) {
        guard let url: URL = URL(string: "https://\(self.ipAddress)/api") else {
            print("bad URL2")
            return
        }
        
        let bodyString: String = "{\"devicetype\":\"SunMode#macOS\", \"generateclientkey\":true}"
        guard let bodyData: Data = bodyString.data(using: .utf8) else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue(self.hueApplicationKey, forHTTPHeaderField: "hue-application-key")
        request.httpBody = bodyData
        
        URLSession(configuration: URLSessionConfiguration.default, delegate: HueAPIv2URLSessioDelegate(), delegateQueue: OperationQueue.current).dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data, error == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                    
                    /// parse response
                    if let error: [String: Any] = json?.first?["error"] as? [String: Any],
                       let errorDescription: String = error["description"] as? String {
                        /// error
                        completion(false, errorDescription)
                    } else if let success: [String: Any] = json?.first?["success"] as? [String: Any],
                              let hueApplicationKey: String = success["username"] as? String {
                        /// success
                        completion(true, hueApplicationKey)
                    } else {
                        /// should never happen
                        completion(false, "unknown error")
                    }
                } catch {
                    NSLog("--json error:--")
                    NSLog(error.localizedDescription)
                }
            } else {
                NSLog("--error:--")
                NSLog(error?.localizedDescription ?? "no error description")
            }
        }).resume()
    }
    
    /// completion: (Name, Sensor Number)
    func findLightSensors(completion: @escaping (String, String) -> Void) {
        guard let url = URL(string: "https://\(ipAddress)/clip/v2/resource/device") else {
            print("fuck this url2, no ipAddress or hueApplicationKey")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.addValue(self.hueApplicationKey, forHTTPHeaderField: "hue-application-key")
        
        URLSession(configuration: URLSessionConfiguration.default, delegate: HueAPIv2URLSessioDelegate(), delegateQueue: OperationQueue.current).dataTask(with: request, completionHandler: { (data, response, error) in
            if let data = data, error == nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                    // NSLog("-------- json: --------")
                    // NSLog(String(describing: json))
                    
                    if let data: [[String: Any]] = json?["data"] as? [[String: Any]] {
                        /// search through all devices
                        for device in data {
                            if let services: [[String: String]] = device["services"] as? [[String: String]] {
                                /// search through all services
                                for service in services {
                                    if let rid: String = service["rid"],
                                       let rtype: String = service["rtype"],
                                       rtype == "light_level",
                                       /// got rtype and rid, now get name
                                       let metadata: [String: String] = device["metadata"] as? [String: String],
                                       let name: String = metadata["name"] {
                                        completion(name, rid)
                                    }
                                }
                            }
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

// MARK: HueV2 Inputs
struct HueV2Inputs: View {
    @Binding var hueV2: HueV2
    @Binding var restartMode: Bool
    
    var hueDiscovery: HueBridgeDiscovery = HueBridgeDiscovery()
    
    var body: some View {
        LabeledContent("Refresh Interval (min)", content: {
            TextField("Refresh Interval (min)", value: $hueV2.refreshInterval, format: .number)
                .textFieldStyle(.custom)
        })
        
        Divider()
            .onChange(of: hueV2.ipAddress, perform: saveChange)
            .onChange(of: hueV2.hueApplicationKey, perform: saveChange)
            .onChange(of: hueV2.rid, perform: saveChange)
            .onChange(of: hueV2.customThreshold, perform: saveChange)
            .onChange(of: hueV2.refreshInterval, perform: saveChange)
        
        LabeledContent(content: {
            TextField("Bridge IP", text: $hueV2.ipAddress, prompt: Text("192.168.x.x"))
                .textFieldStyle(.custom)
        }, label: {
            HStack(content: {
                Text("Bridge IP")
                
                Button(action: bridgeSearchAction, label: {
                    Image(systemName: "magnifyingglass")
                })
                .buttonStyle(.plain)
                .help("Search for Philips Hue Bridges")
                .sheet(isPresented: .constant(!hueV2.foundBridges.isEmpty), content: { bridgeSheet })
            })
        })
        
        LabeledContent(content: {
            TextField("API Key", text: $hueV2.hueApplicationKey)
                .textFieldStyle(.custom)
        }, label: {
            HStack(content: {
                Text("API Key")
                
                Button(action: hueApplicationKeyCreateAction, label: {
                    Image(systemName: "plus")
                })
                .buttonStyle(.plain)
                .disabled(!hueV2.hueApplicationKey.isEmpty)
                .help(hueV2.ipAddress.isEmpty ? "Missing IP Address" : !hueV2.hueApplicationKey.isEmpty ? "Delete current API Key to create a new Key" : "Create New API Key")
            })
        })
        
        LabeledContent(content: {
            TextField("Sensor number", text: $hueV2.rid)
                .textFieldStyle(.custom)
        }, label: {
            HStack(content: {
                Text("Sensor Number")
                
                Button(action: findSensorAction, label: {
                    Image(systemName: "magnifyingglass")
                })
                .buttonStyle(.plain)
                .help(hueV2.ipAddress.isEmpty ? "Missing IP Address" : hueV2.hueApplicationKey.isEmpty ? "Missing API Key" : "Search for Sensors")
                .disabled(hueV2.ipAddress.isEmpty || hueV2.hueApplicationKey.isEmpty)
                .sheet(isPresented: .constant(!hueV2.foundSensors.isEmpty), content: { sensorSheet })
            })
        })
        
        Divider()
        
        LabeledContent("Threshold Value", content: {
            TextField("Threshold Value", value: $hueV2.customThreshold, format: .number)
                .textFieldStyle(.custom)
        })
    }
    
    
    // MARK: Alerts
    var bridgeSheet: some View {
        VStack(content: {
            HStack(content: {
                HueBridgeIcon(size: 50, version: 0)
                    .shadow(radius: 10)
                
                Text(hueV2.foundBridges.isEmpty ? "Searching..." : "Select Bridge")
                    .font(.headline)
            })
            
            ForEach(hueV2.foundBridges, id: \.id, content: { bridge in
                Button(action: {
                    hueV2.ipAddress = bridge.ipAddress
                    
                    hueV2.foundBridges = []
                }, label: {
                    Text("\(bridge.name) - \(bridge.ipAddress)")
                        .frame(minWidth: 0, maxWidth: .infinity)
                })
            })
            
            Divider()
            
            Button(action: {
                hueV2.foundBridges = []
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
                    .shadow(radius: 10)
                
                Text(hueV2.foundSensors.isEmpty ? "Searching..." : "Select Sensor")
                    .font(.headline)
            })
            
            ForEach(hueV2.foundSensors, id: \.id, content: { sensor in
                Button(action: {
                    hueV2.rid = sensor.rid
                    
                    hueV2.foundSensors = []
                }, label: {
                    Text("\(sensor.name) - \(sensor.rid)")
                        .frame(minWidth: 0, maxWidth: .infinity)
                })
            })
            
            Divider()
            
            Button(action: {
                hueV2.foundSensors = []
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
    private func bridgeSearchAction() {
        hueV2.foundBridges = []
        
        hueDiscovery.startDiscovery(completion: { name, ipAddress in
            let newBridge: HueV2.Bridge = .init(name: name, ipAddress: ipAddress)
            hueV2.foundBridges.append(newBridge)
        })
    }
    private func hueApplicationKeyCreateAction() {
        DispatchQueue.global().async(execute: {
            hueV2.createHueApplicationKey(completion: { success, hueApplicationKey in
                DispatchQueue.main.async(execute: {
                    hueV2.hueApplicationKey = hueApplicationKey
                })
            })
        })
    }
    private func findSensorAction() {
        hueV2.foundSensors = []
        
        DispatchQueue.global().async(execute: {
            hueV2.findLightSensors(completion: { name, rid in
                let newSensor: HueV2.Sensor = .init(name: name, rid: rid)
                DispatchQueue.main.async(execute: {
                    hueV2.foundSensors.append(newSensor)
                })
            })
        })
    }
    private func saveChange(_ any: any Equatable) {
        restartMode.toggle()
        UserDefaults.standard.set(try? PropertyListEncoder().encode(hueV2), forKey: "hueV2")
    }
}

// MARK: HueV2 Info
struct HueV2Info: View {
    let refreshTimer: Timer?
    let sensorData: HueV2.SensorData?
    
    @State private var updateViewTimer: Timer?
    @State private var now: Date = Date.now
    
    static let dateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    
    var body: some View {
        HStack(content: {
            Image(systemName: "clock.arrow.2.circlepath")
            
            if let fireDate: Date = refreshTimer?.fireDate {
                Text(Formatter.relativeDateFormatter.localizedString(for: fireDate, relativeTo: now))
                    .onAppear(perform: {
                        updateViewTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(1), repeats: true, block: { _ in now = Date.now })
                        updateViewTimer?.tolerance = 2.0
                    })
                    .onDisappear(perform: { updateViewTimer?.invalidate() })
            } else {
                Text("-")
            }
            
            if let sensor: HueV2.SensorData = sensorData {
                Text("\(sensor.lightlevel / 1000) lux, at \(HueV2Info.dateFormatter.date(from: sensor.changed)?.formatted(date: .omitted, time: .standard) ?? "-")")
            } else {
                Label("No Sensor Data", systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
        })
        .font(.footnote)
    }
}
