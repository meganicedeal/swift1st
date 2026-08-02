//
//  RouteService.swift
//  IOS2-MapKit
//
//  Wraps MapKit's search + directions APIs so the view controller doesn't
//  have to deal with MKLocalSearch / MKDirections directly. This is the
//  "Navigation" feature (destination search + route calculation) merged
//  into the original location-tracking MapKit project.
//

import Foundation
import MapKit

enum RouteServiceError: LocalizedError {
    case noResultsFound
    case noRouteFound

    var errorDescription: String? {
        switch self {
        case .noResultsFound:
            return "No place matched that search."
        case .noRouteFound:
            return "No route could be found between these two points."
        }
    }
}

final class RouteService {

    /// Searches for places matching a free-text query, biased around a region
    /// (typically the user's current location) so results are relevant.
    func searchPlaces(matching query: String,
                       region: MKCoordinateRegion,
                       completion: @escaping (Result<[MKMapItem], Error>) -> Void) {

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query
        request.region = region

        MKLocalSearch(request: request).start { response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            let items = response?.mapItems ?? []
            if items.isEmpty {
                completion(.failure(RouteServiceError.noResultsFound))
            } else {
                completion(.success(items))
            }
        }
    }

    /// Calculates a route between two coordinates for the given transport type.
    func calculateRoute(from source: CLLocationCoordinate2D,
                         to destination: CLLocationCoordinate2D,
                         transportType: MKDirectionsTransportType = .automobile,
                         completion: @escaping (Result<MKRoute, Error>) -> Void) {

        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: source))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: destination))
        request.transportType = transportType

        MKDirections(request: request).calculate { response, error in
            if let error = error {
                completion(.failure(error))
                return
            }
            guard let route = response?.routes.first else {
                completion(.failure(RouteServiceError.noRouteFound))
                return
            }
            completion(.success(route))
        }
    }
}
