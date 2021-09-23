//
//  LocationPublisher.swift
//  CombineLocationManager
//
//  Created by Palash Das on 20/09/21.
//

import Foundation
import Combine
import CoreLocation

protocol LocationPublisherProtocol: AnyObject {
    var authStatusSubject: PassthroughSubject<CLAuthorizationStatus, Error> { get }
    var locationSubject: PassthroughSubject<[CLLocation], Error> { get }
    var locationManager: CLLocationManager? { get }
    
    func start()
    func stop()
}

final class LocationPublisher: NSObject, LocationPublisherProtocol {
    
    static let `default` = LocationPublisher()
    
    private(set) var authStatusSubject = PassthroughSubject<CLAuthorizationStatus, Error>()
    private(set) var locationSubject = PassthroughSubject<[CLLocation], Error>()
    private(set) var locationManager: CLLocationManager?
    
    override init() {
        super.init()
        initializeLocationManager()
    }
    
    // Initialize location manager
    private func initializeLocationManager() {
        
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        //locationManager.activityType = .fitness
        //locationManager?.distanceFilter = 0.5 // measured in meters
        locationManager?.allowsBackgroundLocationUpdates = true
        locationManager?.pausesLocationUpdatesAutomatically = false
        locationManager?.showsBackgroundLocationIndicator = true
    }
    
    func requestWhenInUseAccess() {
        locationManager?.requestWhenInUseAuthorization()
    }
    
    func start() {
        locationManager?.startUpdatingLocation()
    }
    
    func stop() {
        locationManager?.stopUpdatingLocation()
    }
}

// MARK: - LocationManager Delegates

extension LocationPublisher: CLLocationManagerDelegate {

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // Send locations
        self.locationSubject.send(locations)
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        // Send error if failed to update location
        self.locationSubject.send(completion: .failure(error))
    }
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.accuracyAuthorization {
        case .fullAccuracy:
            break
        case.reducedAccuracy:
            // Send error message if precise location is off
            self.authStatusSubject.send(completion: .failure(LocationError.preciseOff))
            return
        default:
            break
        }
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse:
            locationManager?.requestAlwaysAuthorization()
            break
        case .authorizedAlways:
            break
        case .notDetermined:
            break
        case .restricted, .denied:
            break
        default:
            break
        }
        // Send current authorization status
        self.authStatusSubject.send(manager.authorizationStatus)
    }
}

enum LocationError: Error {
    case locationService
    case preciseOff
    case customMessage(String)
}

extension LocationError: LocalizedError {
    var errorDescription: String? {
        switch self {
        case .locationService:
            return "Please turn on your Location Services to enable accurate map services."
        case .preciseOff:
            return "Location accuracy has been reduced. We respect your decision but this may affect accurate map services.\nRecommended 'Precise Location: On'"
        case .customMessage(let message):
            return message
        }
    }
}
