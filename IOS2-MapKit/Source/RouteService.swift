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

// THEORY: why does this file exist separately from ViewController?
// This is the "Service" or "Model" layer: it knows how to talk to MapKit's
// search/directions APIs, and nothing about UIKit, screens, or buttons.
// A ViewController could ask a *fake* RouteService for a route during a
// unit test, without needing GPS or network access — that's the practical
// payoff of keeping this logic separate ("separation of concerns").
//
// Concepts in this file:
// - enum with an associated error message  -> RouteServiceError below
// - Result<Success, Failure>                -> every completion handler
// - @escaping closures                      -> see calculateRoute()
// - `final class`                           -> see RouteService below

// An `enum` (enumeration) lists a fixed, closed set of possible cases —
// here, the only two ways this service can fail. Conforming to
// `LocalizedError` means we can give each case a human-readable message
// via `errorDescription`, which is what `error.localizedDescription`
// returns wherever this error is caught (see ViewController.presentError).
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

// `final` tells the compiler this class can never be subclassed. That's a
// small performance win (the compiler can skip dynamic dispatch checks)
// and, more importantly, a design statement: "this is a leaf utility, not
// meant to be extended via inheritance."
final class RouteService {

    /// Searches for places matching a free-text query, biased around a region
    /// (typically the user's current location) so results are relevant.
    ///
    /// THEORY — reading this signature left to right:
    /// - `completion:` is a parameter whose *type* is a closure/function:
    ///   `(Result<[MKMapItem], Error>) -> Void` — "a function that takes a
    ///   Result and returns nothing".
    /// - `Result<[MKMapItem], Error>` is Swift's built-in type for "either
    ///   a success value (`[MKMapItem]`, an array of map items) OR a
    ///   failure value (`Error`)" — never both, never neither. The caller
    ///   is forced by the compiler to `switch` and handle both cases,
    ///   which is exactly what ViewController does.
    /// - `@escaping` means this closure will be called *after* the function
    ///   has already returned (MKLocalSearch runs asynchronously over the
    ///   network). Swift requires this keyword explicitly because a
    ///   non-escaping closure — the default — is only allowed to run
    ///   *during* the function call, which wouldn't work for anything async.
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
