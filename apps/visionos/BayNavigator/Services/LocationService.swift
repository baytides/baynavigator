import Foundation
import CoreLocation

/// Privacy-first location service for visionOS
/// - All distance calculations are done on-device
/// - Location is never sent to any server
/// - User must explicitly opt-in to location access
@Observable
final class LocationService: NSObject {
    // MARK: - Published Properties
    private(set) var currentLocation: CLLocation?
    private(set) var currentCounty: String?
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined

    var hasLocation: Bool { currentLocation != nil }
    var hasPermission: Bool {
        authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways
    }

    // MARK: - Private
    private let locationManager = CLLocationManager()

    // Bay Area county centers for on-device county detection
    private static let countyCoordinates: [String: CLLocationCoordinate2D] = [
        "Alameda County": CLLocationCoordinate2D(latitude: 37.6017, longitude: -121.7195),
        "Contra Costa County": CLLocationCoordinate2D(latitude: 37.9193, longitude: -121.9277),
        "Marin County": CLLocationCoordinate2D(latitude: 38.0834, longitude: -122.7633),
        "Napa County": CLLocationCoordinate2D(latitude: 38.5025, longitude: -122.2654),
        "San Francisco": CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
        "San Mateo County": CLLocationCoordinate2D(latitude: 37.4969, longitude: -122.3331),
        "Santa Clara County": CLLocationCoordinate2D(latitude: 37.3541, longitude: -121.9552),
        "Solano County": CLLocationCoordinate2D(latitude: 38.2721, longitude: -121.9399),
        "Sonoma County": CLLocationCoordinate2D(latitude: 38.5780, longitude: -122.9888)
    ]

    // MARK: - Initialization
    override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer // Don't need precise
        authorizationStatus = locationManager.authorizationStatus
    }

    // MARK: - Public Methods

    /// Request location permission
    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    /// Get current location (on-device only - never sent to server)
    func getCurrentLocation() {
        guard !isLoading else { return }

        isLoading = true
        error = nil

        if authorizationStatus == .notDetermined {
            requestPermission()
            return
        }

        guard hasPermission else {
            error = "Location permission not granted"
            isLoading = false
            return
        }

        locationManager.requestLocation()
    }

    /// Clear current location
    func clearLocation() {
        currentLocation = nil
        currentCounty = nil
        error = nil
    }

    // MARK: - Distance Calculations (All On-Device)

    /// Calculate distance between two coordinates in miles
    static func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let fromLocation = CLLocation(latitude: from.latitude, longitude: from.longitude)
        let toLocation = CLLocation(latitude: to.latitude, longitude: to.longitude)
        return fromLocation.distance(from: toLocation) / 1609.344 // meters to miles
    }

    /// Calculate distance from user to a program
    func distanceToProgram(latitude: Double?, longitude: Double?) -> Double? {
        guard let location = currentLocation,
              let lat = latitude,
              let lng = longitude else {
            return nil
        }

        let programCoord = CLLocationCoordinate2D(latitude: lat, longitude: lng)
        return Self.calculateDistance(from: location.coordinate, to: programCoord)
    }

    /// Format distance for display
    static func formatDistance(_ miles: Double) -> String {
        if miles < 0.1 {
            return "\(Int(miles * 5280)) ft"
        } else if miles < 10 {
            return String(format: "%.1f mi", miles)
        } else {
            return "\(Int(miles)) mi"
        }
    }

    // MARK: - Private Methods

    /// Find nearest county based on coordinates (on-device only)
    private func findNearestCounty(to coordinate: CLLocationCoordinate2D) -> String {
        var nearestCounty = "Bay Area"
        var minDistance = Double.infinity

        for (county, countyCoord) in Self.countyCoordinates {
            let distance = Self.calculateDistance(from: coordinate, to: countyCoord)
            if distance < minDistance {
                minDistance = distance
                nearestCounty = county
            }
        }

        return nearestCounty
    }
}

// MARK: - CLLocationManagerDelegate
extension LocationService: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }

        // Store location (stays on device!)
        currentLocation = location

        // Determine county (calculated on-device)
        currentCounty = findNearestCounty(to: location.coordinate)

        isLoading = false
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        self.error = "Could not get location: \(error.localizedDescription)"
        isLoading = false
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus

        // If we were waiting for permission, try to get location now
        if isLoading && hasPermission {
            locationManager.requestLocation()
        } else if isLoading && authorizationStatus == .denied {
            error = "Location permission denied"
            isLoading = false
        }
    }
}
