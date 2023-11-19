// 07.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import Foundation
import SwiftUI

struct StaticTime: Codable {
    var sunrise: Date = Date.now
    var sunset: Date = Date.now
    
    var restartMode: Bool = false   /// single variable for onChange ( to restart model.startMode() ) to subscribe to instead of each struct variable seperately
    
    /// Helpers
    private var _sunriseComponents: DateComponents { Calendar.current.dateComponents([.hour, .minute], from: self.sunrise) }
    private var _sunsetComponents: DateComponents { Calendar.current.dateComponents([.hour, .minute], from: self.sunset) }
    private var _sunriseToday: Date { Calendar.current.date(bySettingHour: _sunriseComponents.hour ?? 0, minute: _sunriseComponents.minute ?? 0, second: 0, of: Date.now)! }
    private var _sunsetToday: Date { Calendar.current.date(bySettingHour: _sunsetComponents.hour ?? 0, minute: _sunsetComponents.minute ?? 0, second: 0, of: Date.now)! }
    private var _tomorrow: Date { Calendar.current.date(byAdding: .day, value: 1, to: Date.now)! }
    private var _sunriseTomorrow: Date { Calendar.current.date(bySettingHour: _sunriseComponents.hour ?? 0, minute: _sunriseComponents.minute ?? 0, second: 0, of: _tomorrow)! }
    private var _sunsetTomorrow: Date { Calendar.current.date(bySettingHour: _sunsetComponents.hour ?? 0, minute: _sunsetComponents.minute ?? 0, second: 0, of: _tomorrow)! }
    
    var currAppearance: SystemAppearances {
        if _sunriseToday >= Date.now {
            /// before sunrise
            return .dark
        } else if _sunsetToday >= Date.now {
            /// before sunset
            return .light
        } else {
            /// after sunset
            return .dark
        }
    }
    
    var nextAppearance: (TimeInterval, SystemAppearances) {
        if _sunriseToday >= Date.now {
            /// before sunrise
            return (_sunriseToday.timeIntervalSinceNow, .light)
        } else if _sunsetToday >= Date.now {
            /// before sunset
            return (_sunsetToday.timeIntervalSinceNow, .dark)
        } else {
            /// after sunset
            return (_sunriseTomorrow.timeIntervalSinceNow, .light)
        }
    }
    
    /// next two sunrise/sunset for Info Footer, each with date and Icon systemName
    var nextChanges: (Date, String, Date, String) {
        if _sunriseToday >= Date.now {
            /// sunriseToday, sunsetToday
            return (_sunriseToday, "sunrise.fill", _sunsetToday, "sunset.fill")
        } else if _sunsetToday >= Date.now {
            /// sunsetToday, sunriseTomorrow
            return (_sunsetToday, "sunset.fill", _sunriseTomorrow, "sunrise.fill")
        } else {
            /// sunriseTomorrow, sunsetTomorrow
            return (_sunriseTomorrow, "sunrise.fill", _sunsetTomorrow, "sunset.fill")
        }
    }
}

// MARK: StaticTime Inputs
struct StaticTimeInputs: View {
    @Binding var staticTime: StaticTime
    
    var body: some View {
        DatePicker("Sunrise", selection: $staticTime.sunrise, displayedComponents: .hourAndMinute)
        DatePicker("Sunset", selection: $staticTime.sunset, displayedComponents: .hourAndMinute)
            .onChange(of: staticTime.sunrise, perform: saveChange)
            .onChange(of: staticTime.sunset, perform: saveChange)
    }
    
    // MARK: Functions
    private func saveChange(_ any: any Equatable) {
        staticTime.restartMode.toggle()
        UserDefaults.standard.set(try? PropertyListEncoder().encode(staticTime), forKey: "staticTime")
    }
}

// MARK: StaticTime Info
struct StaticTimeInfo: View {
    let nextChanges: (Date, String, Date, String)
    
    var body: some View {
        HStack(content: {
            Label(nextChanges.0.formatted(date: .omitted, time: .shortened), systemImage: nextChanges.1)
            Text("|")
            Label(nextChanges.2.formatted(date: .omitted, time: .shortened), systemImage: nextChanges.3)
        })
        .foregroundStyle(.primary, .yellow)
    }
}
