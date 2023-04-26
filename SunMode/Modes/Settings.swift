// 20.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI
import ServiceManagement

struct Settings: Codable {
    var menuBarIconAdvanced: Bool = true
    
    // var restartMode: Bool = false    /// single variable for onChange ( to restart model.startMode() ) to subscribe to instead of each struct variable seperately
}

// MARK: Settings Inputs
struct SettingsInputs: View {
    @Binding var settings: Settings
    
    var body: some View {
        Toggle(isOn: $settings.menuBarIconAdvanced, label: { Text("Detailed MenuBar Icon") })
            .toggleStyle(.switch)
            .scaleEffect(0.75)
            .padding(.trailing, -10)
            .help("MenuBarIcon: show next Sunset/Sunrise or current lightlevel")
            .onChange(of: settings.menuBarIconAdvanced, perform: saveChange)
        
        
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
            .scaleEffect(0.75)
            .padding(.trailing, -10)
        
        Button("Quit SunMode", action: quitAction)
        
        Text("SunMode v\(Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String)")
            .foregroundColor(.gray)
    }
    
    // MARK: Functions
    private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
    private func saveChange(_ any: any Equatable) {
        // settings.restartMode.toggle()
        UserDefaults.standard.set(try? PropertyListEncoder().encode(settings), forKey: "settings")
    }
}

struct SettingsInputs_Previews: PreviewProvider {
    static var previews: some View {
        SettingsInputs(settings: .constant(Settings()))
    }
}

// MARK: SettingsInfo
struct SettingsInfo: View {
    var body: some View {
        HStack(content: {
            Spacer()
            Button(action: quitAction, label: {
                Text("Quit")
                    .foregroundColor(.blue)
            })
        })
    }
    
    // MARK: Funcitons
    private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}
