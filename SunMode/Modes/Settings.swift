// 20.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI
import ServiceManagement

// MARK: Settings Inputs
struct SettingsInputs: View {
    @AppStorage("menuBarIconAdvanced") var menuBarIconAdvanced: Bool = true
    // @AppStorage("restartMode") var restartMode: Bool = false    /// single variable for onChange ( to restart model.startMode() ) to subscribe to instead of each struct variable seperately
    
    @State var newVersion: String = ""
    
    var body: some View {
        VStack(content: {
            Toggle(isOn: $menuBarIconAdvanced, label: { Text("Detailed MenuBar Icon") })
                .toggleStyle(.switch)
                .help("MenuBarIcon: show next Sunset/Sunrise or current lightlevel")
            
            
            let launchItemBinding: Binding<Bool> = Binding(
                get: { SMAppService.mainApp.status == .enabled },
                set: {
                    /// add or remove LoginItem
                    if $0 {
                        do {
                            try SMAppService.mainApp.register()
                        } catch {
                            NSLog("add LoginItem Error: \(error)")
                        }
                    } else {
                        do {
                            try SMAppService.mainApp.unregister()
                        } catch {
                            NSLog("remove LoginItem Error: \(error)")
                        }
                    }
                }
            )
            Toggle("Lauch on Start Up", isOn: launchItemBinding)
                .toggleStyle(.switch)
            
            HStack(content: {
                Button("Check for Update", action: checkLatestRelease)
                if !newVersion.isEmpty {
                    Link("New Version v\(newVersion)", destination: URL(string: "https://www.github.com/amaider/SunMode/releases/latest")!)
                }
            })
        })
    }
    
    // MARK: Functions
    private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
    
    private func checkLatestRelease() {
        let url: URL = URL(string: "https://api.github.com/repos/amaider/SunMode/releases/latest")!
        
        let task: URLSessionDataTask = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            if let error = error { NSLog("Error: \(error.localizedDescription)") }
            guard let data = data else { return }
            
            do {
                if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    if let latestVersion = json["tag_name"] as? String {
                        if latestVersion != (Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String) {
                            newVersion = latestVersion
                        } else {
                            newVersion = ""
                        }
                    }
                }
            } catch {
                NSLog("Error parsing github: \(error.localizedDescription)")
            }
        })
        task.resume()
    }
}

struct SettingsInputs_Previews: PreviewProvider {
    static var previews: some View {
        SettingsInputs()
    }
}

// MARK: Settings Info
struct SettingsInfo: View {
    var body: some View {
        HStack(content: {
            Text("SunMode v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)")
                .foregroundColor(.gray)

            Button("Quit SunMode", action: quitAction)
        })
    }
    
    // MARK: Funcitons
    private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}
