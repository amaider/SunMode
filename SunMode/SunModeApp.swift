// 04.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI

@main
struct SunModeApp: App {
    let wakeUpPub = NSWorkspace.shared.notificationCenter.publisher(for: NSWorkspace.didWakeNotification)
    
    @StateObject var model: Model = Model()
    
    var body: some Scene {
        MenuBarExtra(content: {
            ContentView(model: model)
                .background(Blur())
        }, label: {
            MenuBarIcon(model: model)
                .onAppear(perform: {
                    model.systemAppearance = getSystemAppearance()
                    model.startMode()
                })
                .onReceive(wakeUpPub, perform: { _ in
                    model.systemAppearance = getSystemAppearance()
                    model.startMode()
                })
            
                .onChange(of: model.mode, perform: { _ in model.startMode() })
                .onChange(of: model.coord.restartMode, perform: { _ in model.startMode() })
                .onChange(of: model.hueV1.restartMode, perform: { _ in model.startMode() })
                .onChange(of: model.staticTime.restartMode, perform: { _ in model.startMode() })
        })
        .menuBarExtraStyle(.window)
    }
}

