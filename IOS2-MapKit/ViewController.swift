//
//  ViewController.swift
//  IOS2-MapKit
//
//  Combines live location tracking (the original MapKit exercise) with
//  destination search + route drawing (the feature the separate
//  "Navigation" exercise was meant to build), merged into one screen.
//

import UIKit
import MapKit

class ViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!

    private let locationManager = CLLocationManager()
    private let routeService = RouteService()

    private var currentCoordinate = CLLocationCoordinate2D()
    private var currentRoute: MKRoute?

    private let coordinatePanel = UICoordinatePanel()
    private let routeInfoPanel = UIRouteInfoPanel()

    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "Search for a destination"
        bar.searchBarStyle = .minimal
        bar.backgroundColor = .white.withAlphaComponent(0.9)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startUpdatingLocation()
    }

    // MARK: - Setup

    private func initialize() {
        coordinatePanel.delegate = self
        routeInfoPanel.delegate = self
        searchBar.delegate = self

        mapView.delegate = self
        locationManager.delegate = self

        mapView.addSubviews(searchBar, coordinatePanel, routeInfoPanel)
        routeInfoPanel.isHidden = true

        applyConstraints()
    }

    private func applyConstraints() {
        searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8).isActive = true
        searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true

        coordinatePanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        coordinatePanel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4).isActive = true
        coordinatePanel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        coordinatePanel.heightAnchor.constraint(equalToConstant: 70).isActive = true

        routeInfoPanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        routeInfoPanel.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
        routeInfoPanel.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -16).isActive = true
    }

    // MARK: - Location

    private func startUpdatingLocation() {
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
    }

    private func centerMap(on coordinate: CLLocationCoordinate2D, latLongDelta: CLLocationDegrees = 0.01) {
        let span = MKCoordinateSpan(latitudeDelta: latLongDelta, longitudeDelta: latLongDelta)
        mapView.setRegion(MKCoordinateRegion(center: coordinate, span: span), animated: true)
    }

    // MARK: - Route drawing

    private func drawRoute(to destination: MKMapItem) {
        routeService.calculateRoute(from: currentCoordinate, to: destination.placemark.coordinate) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let route):
                    self.showRoute(route, destination: destination)
                case .failure(let error):
                    self.presentError(error)
                }
            }
        }
    }

    private func showRoute(_ route: MKRoute, destination: MKMapItem) {
        clearRoute(keepAnnotations: false)

        currentRoute = route
        mapView.addOverlay(route.polyline, level: .aboveRoads)

        let pin = MKPointAnnotation()
        pin.coordinate = destination.placemark.coordinate
        pin.title = destination.name ?? "Destination"
        mapView.addAnnotation(pin)

        mapView.setVisibleMapRect(
            route.polyline.boundingMapRect,
            edgePadding: UIEdgeInsets(top: 100, left: 40, bottom: 140, right: 40),
            animated: true
        )

        routeInfoPanel.distanceText = formattedDistance(route.distance)
        routeInfoPanel.durationText = "≈ " + formattedDuration(route.expectedTravelTime)
        routeInfoPanel.isHidden = false
    }

    private func clearRoute(keepAnnotations: Bool = true) {
        if let route = currentRoute {
            mapView.removeOverlay(route.polyline)
            currentRoute = nil
        }
        if !keepAnnotations {
            mapView.removeAnnotations(mapView.annotations)
        }
        routeInfoPanel.isHidden = true
    }

    private func formattedDistance(_ meters: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        return formatter.string(fromDistance: meters)
    }

    private func formattedDuration(_ seconds: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: seconds) ?? "--"
    }

    private func presentError(_ error: Error) {
        let alert = UIAlertController(title: "Oops", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

// MARK: - CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }
        locationManager.stopUpdatingLocation()

        currentCoordinate = location.coordinate
        centerMap(on: currentCoordinate)

        coordinatePanel.latitude = currentCoordinate.latitude
        coordinatePanel.longitude = currentCoordinate.longitude
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        presentError(error)
    }
}

// MARK: - MKMapViewDelegate

extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        guard let polyline = overlay as? MKPolyline else {
            return MKOverlayRenderer(overlay: overlay)
        }
        let renderer = MKPolylineRenderer(polyline: polyline)
        renderer.strokeColor = .systemBlue
        renderer.lineWidth = 5
        return renderer
    }
}

// MARK: - UICoordinatePanelDelegate

extension ViewController: UICoordinatePanelDelegate {
    func coordinatePanelButtonTapped(_ sender: Any?) {
        startUpdatingLocation()
    }
}

// MARK: - UIRouteInfoPanelDelegate

extension ViewController: UIRouteInfoPanelDelegate {
    func routeInfoPanelClearButtonTapped(_ sender: Any?) {
        clearRoute(keepAnnotations: false)
    }
}

// MARK: - UISearchBarDelegate

extension ViewController: UISearchBarDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.resignFirstResponder()

        guard let query = searchBar.text, !query.isEmpty else { return }

        let region = MKCoordinateRegion(
            center: currentCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.1, longitudeDelta: 0.1)
        )

        routeService.searchPlaces(matching: query, region: region) { [weak self] result in
            guard let self = self else { return }
            DispatchQueue.main.async {
                switch result {
                case .success(let items):
                    guard let destination = items.first else { return }
                    self.drawRoute(to: destination)
                case .failure(let error):
                    self.presentError(error)
                }
            }
        }
    }
}
