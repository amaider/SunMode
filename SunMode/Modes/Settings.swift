// 20.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © __YEAR__ amaider. All rights reserved.

import SwiftUI

struct Settings: Codable {
    var menuBarIconAdvanced: Bool = true
    var hasLauncDeamon: Bool = false
    
    /// single variable for onChange to subscribe to instead of each single variable seperately
    var restartMode: Bool = false
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
        
        Toggle("Lauch on Start Up", isOn: $settings.hasLauncDeamon)
            .toggleStyle(.switch)
            .scaleEffect(0.75)
            .padding(.trailing, -10)
            .onChange(of: settings.hasLauncDeamon, perform: {
                saveChange($0)
                
                if $0 {
                    print("todo: enable launch Deamon")
                } else {
                    print("todo: disable launch Deamon")
                }
            })
        
        Button("Quit SunMode", action: quitAction)
    }
    
    // MARK: Functions
    private func launchDeamonAction() {
        print("todo: add to lauch deamons")
    }
    private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
    private func saveChange(_ any: any Equatable) {
        settings.restartMode.toggle()
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
