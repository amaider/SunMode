// 07.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import SwiftUI
import SunKit
import CoreLocation

// MARK: Model
struct Coordinates: Codable {
    var latitude: Double = 37.335
    var longitude: Double = -122.009
    var timeZone: Double = 0
    
    var sunriseOffset: Int = 30
    var sunsetOffset: Int = -30
    
    var locationName: String = ""
    var restartMode: Bool = false   /// single variable for onChange ( to restart model.startMode() ) to subscribe to instead of each struct variable seperately
    
    /// Helpers
    private var _sun: Sun {
        let _location: CLLocation = CLLocation(latitude: self.latitude, longitude: self.longitude)
        return Sun(location: _location, timeZone: self.timeZone)
    }
    private var _sunriseToday: Date { _sun.sunrise.addingTimeInterval(TimeInterval(sunriseOffset * 60)) }
    private var _sunsetToday: Date { _sun.sunset.addingTimeInterval(TimeInterval(sunsetOffset * 60)) }
    
    private var _sunTomorrow: Sun {
        let tomorrow: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date.now)!
        
        let sunTomorrow: Sun = _sun
        try? sunTomorrow.setDate(tomorrow)
        return sunTomorrow
    }
    private var _sunriseTomorrow: Date { _sunTomorrow.sunrise.addingTimeInterval(TimeInterval(sunriseOffset * 60)) }
    private var _sunsetTomorrow: Date { _sunTomorrow.sunset.addingTimeInterval(TimeInterval(sunsetOffset * 60)) }
    
    
    var currAppearance: SystemAppearances {
        if _sunriseToday > Date.now {
            /// before sunrise
            return .dark
        } else if _sunsetToday > Date.now {
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

// MARK: Coordinates Inputs
struct CoordinatesInputs: View {
    @Binding var coord: Coordinates
    @State private var locationManager: LocationManager? = nil
    
    var body: some View {
        LabeledContent(content: {
            Button(action: locateMeAction, label: {
                Spacer()
                Image(systemName: locationManager?.manager.authorizationStatus == .authorized ? "location" : "location.slash")
            }).buttonStyle(.plain)
        }, label: {
            Text(coord.locationName)
                .foregroundColor(.gray)
        })
        
        LabeledContent("Latitude", content: {
            TextField("Latitude", value: $coord.latitude, formatter: Formatter.decimal)
                .textFieldStyle(.custom)
        })
        LabeledContent("Longitude", content: {
            TextField("Longitude", value: $coord.longitude, formatter: Formatter.decimal)
                .textFieldStyle(.custom)
        })
        
        LabeledContent("Time Zone (min)", content: {
            TextField("Time Zone", value: $coord.timeZone, formatter: Formatter.decimal)
                .textFieldStyle(.custom)
        })
        
        Divider()
        
        LabeledContent("Offset Sunrise (min)", content: {
            TextField("Offset Sunrise (min)", value: $coord.sunriseOffset, format: .number)
                .textFieldStyle(.custom)
        })
        LabeledContent("Offset Sunset (min)", content: {
            TextField("Offset Sunset (min)", value: $coord.sunsetOffset, format: .number)
                .textFieldStyle(.custom)
        })
        .onChange(of: coord.latitude, perform: saveChange)
        .onChange(of: coord.longitude, perform: saveChange)
        .onChange(of: coord.timeZone, perform: saveChange)
        .onChange(of: coord.sunriseOffset, perform: saveChange)
        .onChange(of: coord.sunsetOffset, perform: saveChange)
        .onAppear(perform: {
            locationManager = LocationManager(locationCompletionHandler: { location in
                coord.latitude = location.coordinate.latitude
                coord.longitude = location.coordinate.longitude
            }, geoCompletionHandler: { placemark in
                coord.locationName = placemark?.locality ?? "-"
                coord.timeZone = Double((placemark?.timeZone?.secondsFromGMT() ?? 0) / 3600)
            })
        })
    }
    
    // MARK: Functions
    private func locateMeAction() {
        locationManager?.manager.requestLocation()
    }
    
    private func saveChange(_ any: any Equatable) {
        coord.locationName = "..."
        coord.restartMode.toggle()
        
        UserDefaults.standard.set(try? PropertyListEncoder().encode(coord), forKey: "coord")
        
        let location: CLLocation = CLLocation(latitude: coord.latitude, longitude: coord.longitude)
        locationManager?.geoLocation(for: location)
        // parseLocation(for: location)
    }
    
    /// set Location Name and TimeZone
    private func parseLocation(for location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(location, completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) in
            if (error != nil) { NSLog("CLGeocoder() error: \(String(describing: error))") }
            
            coord.locationName = placemarks?.first?.locality ?? "-"
            coord.timeZone = Double((placemarks?.first?.timeZone?.secondsFromGMT() ?? 0) / 3600)
            
            if !CLGeocoder().isGeocoding {
                CLGeocoder().cancelGeocode()
            }
        })
    }
}

// MARK: Coordinates Info
struct CoordinatesInfo: View {
    let nextChanges: (Date, String, Date, String)
    
    var body: some View {
        HStack(content: {
            Image(systemName: nextChanges.1)
            Text(nextChanges.0.formatted(date: .omitted, time: .shortened))
            Text("|")
            Image(systemName: nextChanges.3)
            Text(nextChanges.2.formatted(date: .omitted, time: .shortened))
        })
    }
}
