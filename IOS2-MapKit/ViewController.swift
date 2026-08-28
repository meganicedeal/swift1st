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
//  - Closures & @escaping completion handlers -> addWaypoint(_:), searchBarSearchButtonClicked
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
    private var currentCoordinate = CLLocationCoordinate2D()

    // Rută cu mai multe opriri: `waypoints` reține, în ordine, fiecare
    // oprire adăugată (căutare sau favorit selectat); `currentLegs` reține
    // câte un MKRoute pentru fiecare "etapă" între două opriri consecutive
    // (poziția curentă -> prima oprire -> a doua oprire -> ...). MapKit nu
    // oferă un singur request cu mai multe puncte de trecere — de-asta
    // avem nevoie de o rută separată, calculată, pentru fiecare etapă.
    // `legStepCounts` reține câte instrucțiuni vocale are fiecare etapă,
    // ca să putem determina, dintr-un `currentStepIndex` unic, cărei
    // opriri îi aparține pasul curent — vezi currentLegIndex(forStepIndex:).
    private var waypoints: [MKMapItem] = []
    private var currentLegs: [MKRoute] = []
    private var legStepCounts: [Int] = []

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

    // Coordonatele complete ale rutei curente (nu doar etapele), folosite
    // ca să detectăm dacă utilizatorul s-a abătut de la drum — vezi
    // distanceToRoute(from:) mai jos. `isCalculatingRoute` previne
    // trimiterea mai multor cereri de rută simultan (fie la adăugarea
    // unei opriri noi, fie la recalculare), cât timp una e deja în
    // desfășurare (MKDirections e asincron, iar poziția se actualizează
    // des în timpul navigării).
    private var routeCoordinates: [CLLocationCoordinate2D] = []
    private var isCalculatingRoute = false

    // Serviciul de favorite (SwiftData) și destinația curent afișată pe
    // hartă — ultima oprire din `waypoints`, reținută separat ca să știm
    // ce nume și ce coordonate să salvăm/previzualizăm (Look Around)
    // atunci când utilizatorul apasă butoanele din UIRouteInfoPanel.
    private let favoritesService = FavoritesService()
    private var currentDestination: MKMapItem?

    private let btnFavorites: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "star.fill"), for: .normal)
        btn.backgroundColor = .white.withAlphaComponent(0.9)
        btn.layer.cornerRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

    private let btnSettings: UIButton = {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: "gearshape.fill"), for: .normal)
        btn.backgroundColor = .white.withAlphaComponent(0.9)
        btn.layer.cornerRadius = 8
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

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

        mapView.addSubviews(searchBar, coordinatePanel, routeInfoPanel, btnFavorites, btnSettings)
        routeInfoPanel.isHidden = true

        btnFavorites.addTarget(self, action: #selector(favoritesButtonTapped), for: .touchUpInside)
        btnSettings.addTarget(self, action: #selector(settingsButtonTapped), for: .touchUpInside)

        // Aplicăm de la pornire aspectul de hartă salvat anterior (zi sau
        // noapte) — altfel, la fiecare relansare a aplicației, harta ar
        // reveni implicit la modul zi, ignorând alegerea utilizatorului.
        applyMapAppearance()

        applyConstraints()
    }

    @objc private func favoritesButtonTapped() {
        let listController = FavoritesListViewController(favoritesService: favoritesService)
        listController.delegate = self
        present(UINavigationController(rootViewController: listController), animated: true)
    }

    @objc private func settingsButtonTapped() {
        let settingsController = SettingsViewController()
        settingsController.delegate = self
        present(UINavigationController(rootViewController: settingsController), animated: true)
    }

    /// Setează stilul de interfață forțat pe MKMapView, care face ca
    /// MapKit să-și redeseneze automat toate culorile hărții (drumuri,
    /// clădiri, etichete) în varianta închisă la culoare, potrivită
    /// pentru condus noaptea — fără să fi fost nevoie să desenăm noi
    /// vreo culoare manual.
    private func applyMapAppearance() {
        mapView.overrideUserInterfaceStyle = UserPreferences.shared.mapAppearance == .night ? .dark : .light
    }

    private func applyConstraints() {
        searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 8).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: btnSettings.leadingAnchor, constant: -4).isActive = true
        searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true

        btnFavorites.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -8).isActive = true
        btnFavorites.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor).isActive = true
        btnFavorites.widthAnchor.constraint(equalToConstant: 44).isActive = true
        btnFavorites.heightAnchor.constraint(equalToConstant: 36).isActive = true

        btnSettings.trailingAnchor.constraint(equalTo: btnFavorites.leadingAnchor, constant: -4).isActive = true
        btnSettings.centerYAnchor.constraint(equalTo: searchBar.centerYAnchor).isActive = true
        btnSettings.widthAnchor.constraint(equalToConstant: 44).isActive = true
        btnSettings.heightAnchor.constraint(equalToConstant: 36).isActive = true

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

    // MARK: - Rută cu mai multe opriri

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

    /// Adaugă o nouă oprire la sfârșitul traseului curent și recalculează
    /// întregul drum (poziția curentă → prima oprire → ... → cea nouă).
    /// Dacă nu exista nicio oprire înainte, comportamentul e identic cu
    /// vechiul "calculează o rută simplă către o singură destinație" —
    /// rutele cu o singură oprire sunt doar cazul particular, cu un
    /// singur element, al rutelor cu mai multe opriri.
    private func addWaypoint(_ destination: MKMapItem) {
        guard !isCalculatingRoute else { return }

        waypoints.append(destination)
        isCalculatingRoute = true

        calculateLegs(for: waypoints) { [weak self] result in
            guard let self = self else { return }
            self.isCalculatingRoute = false

            switch result {
            case .success(let legs):
                self.showMultiStopRoute(legs)
            case .failure(let error):
                // Nu păstrăm o oprire pentru care nu s-a putut calcula
                // nicio rută — altfel utilizatorul ar rămâne cu o oprire
                // "fantomă", nedesenată nicăieri pe hartă.
                self.waypoints.removeLast()
                self.presentError(error)
            }
        }
    }

    /// Calculează, în ordine, câte o rută (MKRoute) pentru fiecare etapă
    /// dintre opririle date: poziția curentă → waypoints[0], apoi
    /// waypoints[0] → waypoints[1], și tot așa. MKDirections calculează o
    /// singură etapă pe cerere, așa că funcția se apelează recursiv pe
    /// ea însăși, o etapă pe rând, adunând rezultatele în `accumulated`,
    /// până când toate etapele sunt gata — moment în care apelează
    /// `completion` o singură dată, cu toate rutele, în ordine.
    private func calculateLegs(
        for waypoints: [MKMapItem],
        originIndex: Int = 0,
        accumulated: [MKRoute] = [],
        completion: @escaping (Result<[MKRoute], Error>) -> Void
    ) {
        guard originIndex < waypoints.count else {
            completion(.success(accumulated))
            return
        }

        let origin = originIndex == 0
            ? currentCoordinate
            : waypoints[originIndex - 1].placemark.coordinate
        let destination = waypoints[originIndex].placemark.coordinate

        routeService.calculateRoute(from: origin, to: destination) { [weak self] result in
            guard let self = self else { return }
            // Network/location callbacks can land on a background thread.
            // ALL UIKit calls (updating labels, adding map overlays, etc.)
            // must happen on the main thread, so we hop back explicitly.
            DispatchQueue.main.async {
                switch result {
                case .success(let route):
                    self.calculateLegs(
                        for: waypoints,
                        originIndex: originIndex + 1,
                        accumulated: accumulated + [route],
                        completion: completion
                    )
                case .failure(let error):
                    completion(.failure(error))
                }
            }
        }
    }

    /// Desenează pe hartă întregul traseu cu mai multe opriri și pornește
    /// (sau reia) navigarea. `legs` trebuie să corespundă, în ordine, cu
    /// `waypoints` curent — un MKRoute pentru fiecare etapă.
    private func showMultiStopRoute(_ legs: [MKRoute]) {
        clearRoute(keepAnnotations: false, keepWaypoints: true)

        currentLegs = legs
        currentDestination = waypoints.last

        for leg in legs {
            mapView.addOverlay(leg.polyline, level: .aboveRoads)
        }

        for (index, waypoint) in waypoints.enumerated() {
            let pin = MKPointAnnotation()
            pin.coordinate = waypoint.placemark.coordinate
            let isFinalStop = index == waypoints.count - 1
            pin.title = waypoint.name ?? (isFinalStop ? "Destinație" : "Oprire \(index + 1)")
            mapView.addAnnotation(pin)
        }

        if let combinedRect = boundingMapRect(of: legs) {
            mapView.setVisibleMapRect(
                combinedRect,
                edgePadding: UIEdgeInsets(top: 100, left: 40, bottom: 140, right: 40),
                animated: true
            )
        }

        let totalDistance = legs.reduce(0) { $0 + $1.distance }
        let totalDuration = legs.reduce(0) { $0 + $1.expectedTravelTime }
        routeInfoPanel.distanceText = formattedDistance(totalDistance)
        routeInfoPanel.durationText = "≈ " + formattedDuration(totalDuration)
        routeInfoPanel.isHidden = false

        // Fiecare etapă își aduce propriile instrucțiuni (route.steps);
        // le concatenăm într-o singură listă unică, în ordinea în care
        // trebuie parcurse. `legStepCounts` reține câte instrucțiuni are
        // fiecare etapă, ca să putem afla mai târziu (currentLegIndex)
        // cărei opriri îi aparține un anumit pas din lista combinată.
        let stepsByLeg = legs.map { leg in leg.steps.filter { !$0.instructions.isEmpty } }
        routeSteps = stepsByLeg.flatMap { $0 }
        legStepCounts = stepsByLeg.map { $0.count }
        currentStepIndex = 0
        isNavigating = true

        // La fel, coordonatele tuturor etapelor se concatenează într-o
        // singură listă — pentru detectarea abaterii de la traseu nu
        // contează unde se termină o etapă și începe alta, doar traseul
        // complet, ca întreg.
        routeCoordinates = legs.flatMap { polylineCoordinates($0.polyline) }

        // E posibil ca actualizările continue de poziție să fi fost deja
        // oprite după prima citire (vezi didUpdateLocations mai jos); din
        // momentul în care o rută devine activă, avem nevoie de un flux
        // constant de poziții ca să știm când utilizatorul a ajuns la
        // următorul viraj.
        locationManager.startUpdatingLocation()
        announceCurrentStep()
    }

    /// Dreptunghiul (în coordonate de hartă) care încadrează toate
    /// etapele rutei, folosit ca să centrăm harta pe întregul traseu,
    /// indiferent de câte opriri are.
    private func boundingMapRect(of legs: [MKRoute]) -> MKMapRect? {
        legs.map { $0.polyline.boundingMapRect }
            .reduce(nil) { result, rect in
                guard let result = result else { return rect }
                return result.union(rect)
            }
    }

    private func clearRoute(keepAnnotations: Bool = true, keepWaypoints: Bool = false) {
        for leg in currentLegs {
            mapView.removeOverlay(leg.polyline)
        }
        currentLegs = []

        if !keepAnnotations {
            mapView.removeAnnotations(mapView.annotations)
        }
        routeInfoPanel.isHidden = true

        isNavigating = false
        routeSteps = []
        legStepCounts = []
        currentStepIndex = 0
        currentDestination = nil
        routeCoordinates = []

        if !keepWaypoints {
            waypoints = []
        }
    }

    // MARK: - Ghidare vocală

    /// Rostește instrucțiunea pentru etapa spre care ne îndreptăm acum.
    /// Dacă pasul curent e chiar primul dintr-o etapă nouă (adică tocmai
    /// am ajuns la o oprire intermediară), anunțăm întâi sosirea la acea
    /// oprire — într-un singur mesaj vocal, nu două separate, ca să nu se
    /// suprapună (vezi `speak(_:)` în VoiceGuide.swift, care oricum ar
    /// întrerupe mesajul anterior).
    private func announceCurrentStep() {
        guard currentStepIndex < routeSteps.count else { return }

        let instruction = routeSteps[currentStepIndex].instructions
        guard !instruction.isEmpty else {
            advanceToNextStep()
            return
        }

        if isLegBoundary(currentStepIndex) {
            let stopNumber = currentLegIndex(forStepIndex: currentStepIndex)
            voiceGuide.speak("Ați ajuns la oprirea \(stopNumber). \(instruction)")
        } else {
            voiceGuide.speak(instruction)
        }
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
        let coordinates = polylineCoordinates(step.polyline)
        return coordinates.last ?? step.polyline.coordinate
    }

    /// Extrage lista de coordonate dintr-un MKPolyline. MapKit nu oferă
    /// direct un array de coordonate — punctele stau într-un buffer C
    /// intern (`getCoordinates(_:range:)`), pe care îl copiem într-un
    /// array Swift obișnuit, mult mai ușor de folosit în restul codului.
    private func polylineCoordinates(_ polyline: MKPolyline) -> [CLLocationCoordinate2D] {
        let pointCount = polyline.pointCount
        guard pointCount > 0 else { return [] }

        var coordinates = [CLLocationCoordinate2D](repeating: kCLLocationCoordinate2DInvalid, count: pointCount)
        polyline.getCoordinates(&coordinates, range: NSRange(location: 0, length: pointCount))
        return coordinates
    }

    /// Indexul etapei (0 = poziția curentă → prima oprire, 1 = prima
    /// oprire → a doua etc.) căreia îi aparține un anumit pas din lista
    /// combinată `routeSteps`. Funcționează numărând câte instrucțiuni
    /// are fiecare etapă (`legStepCounts`) și văzând unde cade `stepIndex`
    /// în acea numărătoare cumulativă.
    private func currentLegIndex(forStepIndex stepIndex: Int) -> Int {
        var cumulative = 0
        for (index, count) in legStepCounts.enumerated() {
            cumulative += count
            if stepIndex < cumulative { return index }
        }
        return max(legStepCounts.count - 1, 0)
    }

    /// Adevărat dacă `stepIndex` este chiar primul pas al unei etape noi
    /// (adică utilizatorul tocmai a ajuns la o oprire intermediară).
    /// Ultima etapă e exclusă deliberat: ajungerea la finalul ei înseamnă
    /// sosirea la destinația finală, tratată separat în
    /// `advanceToNextStep`, nu ca o "oprire intermediară".
    private func isLegBoundary(_ stepIndex: Int) -> Bool {
        guard legStepCounts.count > 1 else { return false }

        var cumulative = 0
        for count in legStepCounts.dropLast() {
            cumulative += count
            if stepIndex == cumulative { return true }
        }
        return false
    }

    // MARK: - Recalculare rută la abatere

    /// Verifică dacă poziția curentă e prea departe de traseul desenat pe
    /// hartă și, dacă da, pornește o recalculare a rutei rămase — de la
    /// poziția actuală, prin toate opririle nevizitate încă (cea spre
    /// care ne îndreptam, plus cele de după ea).
    private func recalculateRouteIfOffTrack(currentLocation: CLLocation) {
        guard !isCalculatingRoute, !waypoints.isEmpty else { return }
        guard let distanceFromRoute = distanceToRoute(from: currentLocation) else { return }

        // Prag de abatere: sub 50m considerăm că utilizatorul e încă "pe
        // drum" (GPS-ul oricum are o marjă de eroare de câțiva metri).
        // Peste 50m — a ratat un viraj, a luat-o pe altă stradă etc. — și
        // are sens o rută nouă, calculată de unde se află acum.
        let offRouteThreshold: CLLocationDistance = 50
        guard distanceFromRoute > offRouteThreshold else { return }

        isCalculatingRoute = true
        voiceGuide.speak("Recalculăm ruta.")

        // Opririle deja vizitate rămân în urmă — recalculăm doar de la
        // oprirea spre care ne îndreptam în momentul abaterii, încolo.
        let legIndex = currentLegIndex(forStepIndex: currentStepIndex)
        let remainingWaypoints = Array(waypoints[legIndex...])

        calculateLegs(for: remainingWaypoints) { [weak self] result in
            guard let self = self else { return }
            self.isCalculatingRoute = false

            switch result {
            case .success(let legs):
                // showMultiStopRoute înlocuiește complet starea de
                // navigare (routeSteps, routeCoordinates, legStepCounts,
                // currentStepIndex) cu cele ale rutei noi și reia
                // anunțurile vocale de la prima ei etapă.
                self.waypoints = remainingWaypoints
                self.showMultiStopRoute(legs)
            case .failure(let error):
                self.presentError(error)
            }
        }
    }

    /// Distanța minimă (în metri) de la o poziție dată până la traseul
    /// curent, calculată segment cu segment din polilinia rutei.
    private func distanceToRoute(from location: CLLocation) -> CLLocationDistance? {
        guard routeCoordinates.count > 1 else { return nil }

        let point = MKMapPoint(location.coordinate)
        var minimumDistance = CLLocationDistance.greatestFiniteMagnitude

        for index in 0..<(routeCoordinates.count - 1) {
            let segmentStart = MKMapPoint(routeCoordinates[index])
            let segmentEnd = MKMapPoint(routeCoordinates[index + 1])
            let distance = distance(from: point, toSegmentBetween: segmentStart, and: segmentEnd)
            minimumDistance = min(minimumDistance, distance)
        }

        return minimumDistance
    }

    /// Distanța de la un punct la cel mai apropiat loc de pe un segment
    /// de dreaptă (nu doar la capetele lui). Standard: proiectăm punctul
    /// pe dreapta suport a segmentului, apoi limităm proiecția să rămână
    /// între cele două capete (`t` clampat între 0 și 1) — altfel am putea
    /// "proiecta" în afara segmentului, spre o zonă a drumului pe care
    /// utilizatorul de fapt nu se află lângă ea.
    private func distance(from point: MKMapPoint, toSegmentBetween start: MKMapPoint, and end: MKMapPoint) -> CLLocationDistance {
        let dx = end.x - start.x
        let dy = end.y - start.y
        let lengthSquared = dx * dx + dy * dy

        guard lengthSquared > 0 else {
            return MKMetersBetweenMapPoints(point, start)
        }

        let t = max(0, min(1, ((point.x - start.x) * dx + (point.y - start.y) * dy) / lengthSquared))
        let projected = MKMapPoint(x: start.x + t * dx, y: start.y + t * dy)
        return MKMetersBetweenMapPoints(point, projected)
    }

    // MARK: - ETA și distanță live

    /// Actualizează panoul de rută cu distanța rămasă și ETA-ul curent,
    /// recalculate din poziția live a utilizatorului — nu doar valorile
    /// statice, calculate o singură dată când ruta a fost afișată.
    private func updateLiveProgress(currentLocation: CLLocation) {
        guard currentStepIndex < routeSteps.count else { return }

        let currentStep = routeSteps[currentStepIndex]
        let stepEndLocation = CLLocation(
            latitude: stepEndCoordinate(currentStep).latitude,
            longitude: stepEndCoordinate(currentStep).longitude
        )

        // Distanța rămasă = ce mai e de parcurs din etapa curentă (de la
        // poziția live până la finalul ei) + suma distanțelor tuturor
        // etapelor care urmează. `step.distance` e oferit direct de
        // MKRoute.Step, în metri.
        let distanceLeftInCurrentStep = currentLocation.distance(from: stepEndLocation)
        let remainingStepsDistance = routeSteps[(currentStepIndex + 1)...]
            .reduce(0) { $0 + $1.distance }
        let totalRemainingDistance = distanceLeftInCurrentStep + remainingStepsDistance

        let speed = currentSpeed(currentLocation: currentLocation)
        let remainingSeconds = speed > 0 ? totalRemainingDistance / speed : 0

        routeInfoPanel.distanceText = formattedDistance(totalRemainingDistance)
        routeInfoPanel.durationText = "≈ " + formattedDuration(remainingSeconds)
    }

    /// Viteza folosită pentru estimarea ETA-ului, în metri/secundă.
    ///
    /// `CLLocation.speed` este viteza reală, măsurată de GPS — cea mai
    /// bună sursă când e disponibilă. Dar GPS-ul are nevoie de câteva
    /// citiri consecutive ca să o poată estima corect, iar până atunci
    /// întoarce o valoare negativă (de obicei -1) ca semnal "nu știu
    /// încă". În acel caz, ne întoarcem la viteza medie a întregului
    /// traseu (suma distanțelor tuturor etapelor / suma duratelor lor
    /// estimate de MapKit) — mai puțin precisă, dar mereu disponibilă.
    private func currentSpeed(currentLocation: CLLocation) -> Double {
        if currentLocation.speed > 0.5 {
            return currentLocation.speed
        }

        let totalDistance = currentLegs.reduce(0) { $0 + $1.distance }
        let totalDuration = currentLegs.reduce(0) { $0 + $1.expectedTravelTime }
        guard totalDuration > 0 else { return 0 }
        return totalDistance / totalDuration
    }

    private func formattedDistance(_ meters: CLLocationDistance) -> String {
        let formatter = MKDistanceFormatter()
        formatter.unitStyle = .abbreviated
        // Formatter-ul MapKit știe deja să convertească și să afișeze
        // corect metri/kilometri sau picioare/mile — noi îi spunem doar
        // care sistem să folosească, pe baza preferinței salvate.
        formatter.units = UserPreferences.shared.unitSystem == .imperial ? .imperial : .metric
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

    // MARK: - Look Around

    /// Cere și afișează o scenă Look Around (echivalentul Apple pentru
    /// Street View) pentru coordonata dată.
    ///
    /// TEORIE — `async`/`await` și `Task { ... }`:
    /// `MKLookAroundSceneRequest.scene` este o proprietate `async`, adică
    /// citirea ei poate dura (o cerere de rețea către serverele Apple
    /// Maps) fără să blocheze thread-ul curent. Cod `async` poate fi
    /// apelat doar din alt cod `async` — dar `lookAroundTapped` (mai sus)
    /// e un simplu handler de buton, sincron. `Task { ... }` face
    /// legătura: pornește o nouă sarcină asincronă, în care putem folosi
    /// `await` liber, în timp ce restul aplicației continuă normal.
    /// E, practic, alternativa modernă la closure-urile `@escaping`
    /// folosite de RouteService (completion handlers) — ambele rezolvă
    /// aceeași problemă ("fă ceva, apoi anunță-mă când e gata"), dar
    /// sintaxa `async`/`await` se citește liniar, de sus în jos, în loc
    /// de imbricată în closure-uri.
    private func showLookAround(for coordinate: CLLocationCoordinate2D) {
        Task {
            do {
                let request = MKLookAroundSceneRequest(coordinate: coordinate)
                guard let scene = try await request.scene else {
                    presentLookAroundUnavailable()
                    return
                }

                let lookAroundController = MKLookAroundViewController(scene: scene)
                present(lookAroundController, animated: true)
            } catch {
                presentError(error)
            }
        }
    }

    /// Nu toate locurile au acoperire Look Around (Apple nu a fotografiat
    /// peste tot) — `request.scene` întoarce pur și simplu `nil` în acest
    /// caz, nu o eroare, așa că merită un mesaj dedicat, mai prietenos
    /// decât un "Oops" generic.
    private func presentLookAroundUnavailable() {
        let alert = UIAlertController(
            title: "Indisponibil",
            message: "Look Around nu are imagini pentru această destinație.",
            preferredStyle: .alert
        )
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

            // Verificăm întâi dacă utilizatorul s-a abătut de la traseu.
            // Dacă da, se pornește o recalculare (asincronă) și sărim
            // peste verificarea de progres pentru actualizarea asta — nu
            // are sens să anunțăm "apropiere de viraj" pe o rută care
            // oricum urmează să fie înlocuită.
            if !isCalculatingRoute {
                recalculateRouteIfOffTrack(currentLocation: location)
            }
            if !isCalculatingRoute {
                checkProgressAlongRoute(currentLocation: location)
                updateLiveProgress(currentLocation: location)
            }
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
        clearRoute(keepAnnotations: false, keepWaypoints: false)
    }

    func routeInfoPanelSaveButtonTapped(_ sender: Any?) {
        guard let destination = currentDestination else { return }

        let name = destination.name ?? "Destinație salvată"
        favoritesService.save(name: name, coordinate: destination.placemark.coordinate)

        let alert = UIAlertController(
            title: "Salvat",
            message: "\"\(name)\" a fost adăugat la favorite.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    func routeInfoPanelLookAroundButtonTapped(_ sender: Any?) {
        guard let destination = currentDestination else { return }
        showLookAround(for: destination.placemark.coordinate)
    }
}

// MARK: - FavoritesListViewControllerDelegate

extension ViewController: FavoritesListViewControllerDelegate {
    func favoritesList(_ controller: FavoritesListViewController, didSelect favorite: FavoriteDestination) {
        // Reconstruim un MKMapItem din coordonatele salvate, ca să putem
        // adăuga favoritul ca oprire nouă, exact ca un rezultat venit din
        // căutare.
        let placemark = MKPlacemark(coordinate: favorite.coordinate)
        let mapItem = MKMapItem(placemark: placemark)
        mapItem.name = favorite.name

        addWaypoint(mapItem)
    }
}

// MARK: - SettingsViewControllerDelegate

extension ViewController: SettingsViewControllerDelegate {
    func settingsDidChange(_ controller: SettingsViewController) {
        applyMapAppearance()

        // Dacă o rută e deja afișată, distanța/durata arătate pe panou
        // trebuie recalculate imediat cu noua unitate de măsură — altfel
        // ar rămâne în unitatea veche până la următoarea actualizare de
        // poziție (sau chiar deloc, dacă utilizatorul nu se mai mișcă).
        guard !currentLegs.isEmpty else { return }

        let totalDistance = currentLegs.reduce(0) { $0 + $1.distance }
        let totalDuration = currentLegs.reduce(0) { $0 + $1.expectedTravelTime }
        routeInfoPanel.distanceText = formattedDistance(totalDistance)
        routeInfoPanel.durationText = "≈ " + formattedDuration(totalDuration)
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
                    // Fiecare căutare adaugă o oprire nouă la traseu, nu
                    // înlocuiește ruta existentă — așa se construiește o
                    // rută cu mai multe opriri, o căutare pe rând.
                    self.addWaypoint(destination)
                case .failure(let error):
                    self.presentError(error)
                }
            }
        }
    }
}
