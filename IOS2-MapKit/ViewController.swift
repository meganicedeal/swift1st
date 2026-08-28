//
//  ViewController.swift
//  IOS2-MapKit
//
//  Combines live location tracking (the original MapKit exercise) with
//  destination search + route drawing (the feature the separate
//  "Navigation" exercise was meant to build), merged into one screen.
//
//  THIS FILE IS THE "CONTROLLER" IN MVC (Model-View-Controller).
//  In an iOS app, a UIViewController is responsible for one screen: it
//  owns the views (the map, the panels, the search bar), reacts to user
//  input, and asks other objects (RouteService, CLLocationManager) to do
//  the actual work. The controller itself should stay "thin" — notice
//  that all the MapKit networking logic lives in RouteService.swift, not
//  here. That separation is a deliberate design choice, not an accident.
//
//  Swift/iOS concepts you'll see below, and where:
//  - Properties (`let` vs `var`)              -> right below, in the property list
//  - Optionals (`?`, `!`, `guard let`)         -> mapView, locationManager callbacks
//  - The Delegate pattern (protocols)          -> "extension ViewController: ..." blocks
//  - Extensions to organize conformances      -> one `extension` per protocol
//  - Closures & @escaping completion handlers -> drawRoute(to:), searchBarSearchButtonClicked
//  - [weak self] to avoid retain cycles       -> inside every closure below
//  - DispatchQueue.main.async                 -> jumping back to the main/UI thread
//

import UIKit
import MapKit

class ViewController: UIViewController {

    // `@IBOutlet weak var` connects this property to a view placed in the
    // storyboard (Main.storyboard). It's declared as an Implicitly
    // Unwrapped Optional (MKMapView!) because Xcode guarantees it will be
    // set before viewDidLoad() runs — but only once. Force-unwrapping
    // anywhere else in your own code is usually a smell; here it's safe
    // because the storyboard connection is doing the unwrapping for us.
    @IBOutlet weak var mapView: MKMapView!

    // `let` = constant reference: once assigned, this property can never
    // point to a *different* CLLocationManager or RouteService instance.
    // (Its internal state can still change — `let` protects the binding,
    // not necessarily the object's mutability.) Use `let` by default and
    // only reach for `var` when a value genuinely needs to be reassigned —
    // it documents intent and lets the compiler catch accidental mutation.
    private let locationManager = CLLocationManager()
    private let routeService = RouteService()

    // `var` because these DO get reassigned as the user moves / searches.
    // `currentRoute: MKRoute?` is an Optional — it means "either an MKRoute
    // value, or nil". There's no route until the user searches for one, so
    // modeling it as optional (rather than some fake placeholder route)
    // makes illegal states unrepresentable.
    private var currentCoordinate = CLLocationCoordinate2D()
    private var currentRoute: MKRoute?

    private let coordinatePanel = UICoordinatePanel()
    private let routeInfoPanel = UIRouteInfoPanel()

    // Starea pentru ghidarea vocală turn-by-turn.
    // `routeSteps` reține fiecare etapă a rutei curente (ex. "Virează
    // dreapta pe Str. Republicii"); `currentStepIndex` ține evidența
    // etapei spre care ne îndreptăm în acest moment; `isNavigating`
    // schimbă comportamentul din didUpdateLocations (mai jos) din "o
    // singură citire de poziție, apoi stop" în "urmărire continuă +
    // verificare a progresului pe rută", cât timp o rută e activă.
    private let voiceGuide = VoiceGuide()
    private var routeSteps: [MKRoute.Step] = []
    private var currentStepIndex = 0
    private var isNavigating = false

    // This is a "closure-based property initializer": the `{ ... }()` right
    // after the type is a closure that runs ONCE, immediately, to compute
    // the initial value. It's a common Swift pattern for configuring a view
    // with several lines of setup without cluttering initialize() below.
    // Note the `()` at the very end — that's what actually *calls* the
    // closure; without it, `searchBar` would be a closure, not a UISearchBar.
    private let searchBar: UISearchBar = {
        let bar = UISearchBar()
        bar.placeholder = "Search for a destination"
        bar.searchBarStyle = .minimal
        bar.backgroundColor = .white.withAlphaComponent(0.9)
        bar.translatesAutoresizingMaskIntoConstraints = false
        return bar
    }()

    // Every UIViewController goes through a fixed lifecycle. viewDidLoad()
    // fires ONCE, right after the view hierarchy is loaded into memory —
    // it's the right place for one-time setup. `override` is required
    // because we're replacing UIViewController's own (empty) implementation;
    // `super.viewDidLoad()` still calls the parent's version first, which
    // is a convention you should always follow unless you have a reason not to.
    override func viewDidLoad() {
        super.viewDidLoad()
        initialize()
    }

    // viewDidAppear(_:) fires every time the screen becomes visible
    // (including returning from a modal), unlike viewDidLoad() which only
    // fires once — that's why location updates are (re)started here rather
    // than in viewDidLoad().
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

    // `{ [weak self] result in ... }` is a CLOSURE — an anonymous chunk of
    // code passed as a value, the same way you'd pass a number or a string.
    // calculateRoute() doesn't run this closure immediately: it stores it
    // and calls it later, once MKDirections responds over the network.
    // Because the closure might run after `self` (this ViewController) has
    // already been dismissed, we capture it as `[weak self]` — a *weak*
    // reference that doesn't keep the ViewController alive just because a
    // closure might still call it. Without this, you'd get a retain cycle
    // (ViewController keeps routeService's closure alive, closure keeps
    // ViewController alive, neither is ever freed). `guard let self = self`
    // then safely unwraps that weak reference for the rest of the closure.
    private func drawRoute(to destination: MKMapItem) {
        routeService.calculateRoute(from: currentCoordinate, to: destination.placemark.coordinate) { [weak self] result in
            guard let self = self else { return }
            // Network/location callbacks can land on a background thread.
            // ALL UIKit calls (updating labels, adding map overlays, etc.)
            // must happen on the main thread, so we hop back explicitly.
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

        // `route.steps` este un array ordonat de MKRoute.Step, câte unul
        // pentru fiecare manevră (ex. "Virează dreapta pe Str.
        // Republicii"). Unele etape (de obicei prima, "Start") au un
        // `instructions` gol și există doar ca să marcheze punctul de
        // plecare, așa că le filtrăm înainte să le dăm ghidului vocal.
        routeSteps = route.steps.filter { !$0.instructions.isEmpty }
        currentStepIndex = 0
        isNavigating = true

        // E posibil ca actualizările continue de poziție să fi fost deja
        // oprite după prima citire (vezi didUpdateLocations mai jos); din
        // momentul în care o rută devine activă, avem nevoie de un flux
        // constant de poziții ca să știm când utilizatorul a ajuns la
        // următorul viraj.
        locationManager.startUpdatingLocation()
        announceCurrentStep()
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

        isNavigating = false
        routeSteps = []
        currentStepIndex = 0
    }

    // MARK: - Ghidare vocală

    /// Rostește instrucțiunea pentru etapa spre care ne îndreptăm acum.
    /// Dacă o etapă ajunge totuși cu un `instructions` gol (nu ar trebui,
    /// după filtrarea de mai sus, dar verificarea costă puțin), trecem
    /// direct la următoarea în loc să "rostim" o tăcere.
    private func announceCurrentStep() {
        guard currentStepIndex < routeSteps.count else { return }

        let instruction = routeSteps[currentStepIndex].instructions
        guard !instruction.isEmpty else {
            advanceToNextStep()
            return
        }
        voiceGuide.speak(instruction)
    }

    /// Trece la etapa următoare sau, dacă toate etapele au fost parcurse,
    /// anunță sosirea la destinație și oprește navigarea.
    private func advanceToNextStep() {
        currentStepIndex += 1

        guard currentStepIndex < routeSteps.count else {
            voiceGuide.speak("Ați ajuns la destinație.")
            isNavigating = false
            locationManager.stopUpdatingLocation()
            return
        }

        announceCurrentStep()
    }

    /// Compară poziția curentă a utilizatorului cu finalul segmentului de
    /// drum al etapei active. MKRoute.Step nu expune direct o "coordonată
    /// de final", așa că o extragem din propriul polyline al etapei —
    /// ultimul punct de pe acel mini-polyline e locul unde are loc
    /// următoarea manevră.
    private func checkProgressAlongRoute(currentLocation: CLLocation) {
        guard currentStepIndex < routeSteps.count else { return }

        let step = routeSteps[currentStepIndex]
        let endLocation = CLLocation(
            latitude: stepEndCoordinate(step).latitude,
            longitude: stepEndCoordinate(step).longitude
        )

        // Distanța (în metri) la care utilizatorul trebuie să ajungă față
        // de finalul unei etape ca să considerăm că a "ajuns" la ea și
        // trecem la instrucțiunea următoare. 30m lasă puțină marjă pentru
        // imprecizia GPS, fără să anunțe virajul prea devreme.
        let arrivalThreshold: CLLocationDistance = 30

        if currentLocation.distance(from: endLocation) < arrivalThreshold {
            advanceToNextStep()
        }
    }

    private func stepEndCoordinate(_ step: MKRoute.Step) -> CLLocationCoordinate2D {
        let pointCount = step.polyline.pointCount
        guard pointCount > 0 else { return step.polyline.coordinate }

        var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        step.polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates.last ?? step.polyline.coordinate
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

// MARK: - Delegation, explained
//
// Everything below is a set of `extension ViewController: SomeProtocol { ... }`
// blocks. This is THE core iOS design pattern: instead of CLLocationManager
// (an Apple framework class) needing to know about our specific
// ViewController, it only knows about a *protocol* — CLLocationManagerDelegate
// — which is just a contract: "whoever is my delegate must be able to
// respond to didUpdateLocations, didFailWithError, etc."
//
// We say `locationManager.delegate = self` (see initialize() above) to
// register ViewController as the one who'll answer when something happens.
// This is called the DELEGATE PATTERN, and it's how almost all of UIKit
// communicates back to your code: table views, text fields, map views,
// search bars, and CLLocationManager all use it. Splitting each protocol
// into its own `extension` (instead of cramming every method onto the
// class declaration) is a style convention that keeps related methods
// grouped and makes the class declaration itself easy to read.

// MARK: - CLLocationManagerDelegate

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.first else { return }

        currentCoordinate = location.coordinate
        coordinatePanel.latitude = currentCoordinate.latitude
        coordinatePanel.longitude = currentCoordinate.longitude

        if isNavigating {
            // Cât timp navigăm activ, vrem o vedere live, apropiată, care
            // urmărește continuu poziția utilizatorului, plus o verificare
            // a progresului față de următorul viraj.
            centerMap(on: currentCoordinate, latLongDelta: 0.003)
            checkProgressAlongRoute(currentLocation: location)
        } else {
            // În afara navigării, comportamentul rămâne cel de dinainte:
            // o singură citire de poziție ca să plasăm utilizatorul pe
            // hartă, apoi oprim actualizările ca să economisim baterie.
            locationManager.stopUpdatingLocation()
            centerMap(on: currentCoordinate)
        }
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
