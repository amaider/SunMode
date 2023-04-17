// 14.04.23, Swift 5.0, macOS 13.1, Xcode 12.4
// Copyright © 2023 amaider. All rights reserved.

import Foundation
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    let manager = CLLocationManager()
    var locationCompletionHandler: (CLLocation) -> Void
    var geoCompletionHandler: (CLPlacemark) -> Void
    
    init(locationCompletionHandler: @escaping (CLLocation) -> Void, geoCompletionHandler: @escaping (CLPlacemark) -> Void) {
        self.locationCompletionHandler = locationCompletionHandler
        self.geoCompletionHandler = geoCompletionHandler
        
        super.init()
        manager.delegate = self
    }
    
    func temporaryRequest() {
        manager.requestTemporaryFullAccuracyAuthorization(withPurposeKey: "Locate Coordinates", completion: { error in
            if error != nil {
                NSLog("temporaryRequest() error: \(String(describing: error?.localizedDescription)))")
            }
        })
    }
    
    func authRequest() {
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
    }
    
    func geoLocation(for _location: CLLocation) {
        CLGeocoder().reverseGeocodeLocation(_location, completionHandler: { (placemarks: [CLPlacemark]?, error: Error?) in
            if error != nil {
                NSLog("CLGeocoder() error: \(String(describing: error?.localizedDescription)))")
            }
            
            guard let placemark: CLPlacemark = placemarks?.first else { return }
            self.geoCompletionHandler(placemark)
            
            if(!CLGeocoder().isGeocoding){
                CLGeocoder().cancelGeocode()
            }
        })
    }
    
    // MARK: CLLocationManager Delegates
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        NSLog("locationManager() error: \(error.localizedDescription))")
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        manager.stopUpdatingLocation()
        
        guard let location: CLLocation = locations.first else { return }
        locationCompletionHandler(location)
    }
}
