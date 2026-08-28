# Swift & iOS, from zero to this project

This is a from-scratch walkthrough of the Swift/iOS concepts you need to
read and extend this project, in the order you'd naturally learn them.
Every concept links to the exact file where it's used and commented
in the code itself — this document is the map, the code comments are the
territory.

If you only remember one thing: **almost everything unusual in this
codebase exists to answer one question — "how does object A tell object B
that something happened, without A needing to know what B is?"** That's
the delegate pattern, and it's the backbone of the whole app.

---

## 1. The absolute basics

### Variables and constants
```swift
let locationManager = CLLocationManager()   // constant: can't be reassigned
var currentRoute: MKRoute?                  // variable: can be reassigned
```
`let` and `var` are the only two ways to declare a name in Swift. Default to
`let`; the compiler will *tell you* to change it to `var` if you ever try to
reassign it. This isn't pedantry — a codebase full of `let` is a codebase
where you can trust that a value won't quietly change somewhere else.

See it in: `ViewController.swift`, top of the class.

### Optionals — Swift's answer to "null"
```swift
private var currentRoute: MKRoute?   // either an MKRoute, or nil
```
The `?` means "this might not have a value." Swift forces you to deal with
that possibility before you can use it — you can't accidentally call a
method on `nil` and crash the way you can in many other languages (that
class of bug is close to eliminated by the type system here).

Three ways you'll see optionals handled in this project:
```swift
// 1. guard let — "if this is nil, bail out of the function early"
guard let location = locations.first else { return }

// 2. if let — "if this has a value, use it in this scope"
if let route = currentRoute { mapView.removeOverlay(route.polyline) }

// 3. force unwrap (!) — "I am certain this has a value; crash if I'm wrong"
@IBOutlet weak var mapView: MKMapView!
```
Force-unwrapping (`!`) is used exactly once in this project, on the
storyboard-connected `mapView`, because Xcode guarantees it's set before
`viewDidLoad()`. Everywhere else, prefer `guard let` / `if let`.

See it in: `ViewController.swift` (`locationManager(_:didUpdateLocations:)`,
`clearRoute`), `RouteService.swift` (`calculateRoute`).

### Functions and named parameters
```swift
func calculateRoute(from source: CLLocationCoordinate2D,
                     to destination: CLLocationCoordinate2D,
                     transportType: MKDirectionsTransportType = .automobile,
                     completion: @escaping (Result<MKRoute, Error>) -> Void)
```
Swift functions have two names per parameter: an external name used at the
call site (`from`, `to`) and an internal name used inside the function
body (`source`, `destination`). This is why calling this function reads
almost like English: `calculateRoute(from: a, to: b)`. `transportType` also
has a **default value** (`.automobile`), so callers can omit it entirely.

See it in: `RouteService.swift`.

---

## 2. Object-oriented Swift

### Classes vs. structs
- **Classes** (`class ViewController`, `class UICoordinatePanel`) are
  *reference types* — when you pass one around, everyone shares the same
  instance. UIKit views and controllers are always classes, because the
  system needs to hold a persistent reference to the exact same object.
- **Structs** (`CLLocationCoordinate2D`, `MKCoordinateRegion`) are *value
  types* — each variable gets its own independent copy. Apple's own
  geometry/data types (points, regions, routes' underlying coordinate
  data) are almost all structs, which is why you never worry about two
  parts of the code accidentally sharing and mutating the same coordinate.

### Inheritance
```swift
class ViewController: UIViewController { ... }
class UICoordinatePanel: UIView { ... }
```
`ViewController` *is a* `UIViewController` — it inherits everything a
generic view controller can do (a `view` property, lifecycle methods like
`viewDidLoad()`) and adds its own behavior on top. Same idea for
`UICoordinatePanel` inheriting from `UIView`.

### Properties and property observers
```swift
public var latitude: Double = 0 {
    didSet {
        self.lblLatitude.text = String(format: "%.6f", latitude)
    }
}
```
`didSet` runs automatically right after the property's value changes. This
means setting `coordinatePanel.latitude = 45.5` from anywhere in the code
updates the on-screen label for free — the panel takes care of its own
display logic, and nobody outside it needs to remember to do that manually.

See it in: `CustomUI/UICoordinatePanel.swift`, `CustomUI/UIRouteInfoPanel.swift`.

### Access control (`private`, `public`)
`private` restricts a property/method to the file it's declared in;
`public` (and the unmarked default, `internal`) allow wider access. Most
implementation details in this project (constraint setup, helper methods)
are `private` — only the handful of things another file genuinely needs
(like `UICoordinatePanel.latitude`) are exposed as `public`.

---

## 3. Protocols and the delegate pattern — the most important section

This is **the** idiom to understand in iOS development. Almost every
built-in UIKit class (table views, text fields, map views, search bars,
location managers) uses it to talk back to your code.

### The problem it solves
`CLLocationManager` (an Apple framework class) needs to tell *someone* "the
user's location just updated." But Apple's framework code was written years
before your `ViewController` existed — it can't possibly `import` your
class and call a method on it directly.

### The solution: protocols
```swift
protocol UICoordinatePanelDelegate {
    func coordinatePanelButtonTapped(_ sender: Any?)
}
```
A `protocol` is a contract with no implementation — just a method
signature. `CLLocationManagerDelegate`, `MKMapViewDelegate`, and
`UISearchBarDelegate` (all from Apple) work exactly the same way as this
custom `UICoordinatePanelDelegate` we wrote ourselves.

Three steps make the pattern work, all present in this project:
1. **Declare** the protocol (`UICoordinatePanelDelegate` in
   `UICoordinatePanel.swift`).
2. **Register** a delegate: `locationManager.delegate = self` — "when
   something happens, tell *me*." (`ViewController.initialize()`)
3. **Conform**: `extension ViewController: CLLocationManagerDelegate { ... }`
   — implement the methods the protocol promises.

### Making delegate methods "optional"
```swift
extension UICoordinatePanelDelegate {
    func coordinatePanelButtonTapped(_ sender: Any?) { /* no code */ }
}
```
A **protocol extension** can supply a default (empty) implementation. This
means conforming types don't strictly have to implement the method — if
they don't, this do-nothing version runs instead. It's how you simulate
"optional" delegate methods in pure Swift.

### Organizing conformances with extensions
```swift
extension ViewController: CLLocationManagerDelegate { ... }
extension ViewController: MKMapViewDelegate { ... }
extension ViewController: UICoordinatePanelDelegate { ... }
extension ViewController: UIRouteInfoPanelDelegate { ... }
extension ViewController: UISearchBarDelegate { ... }
```
`ViewController.swift` conforms to **five** different delegate protocols.
Rather than dumping every method onto one giant class body, each
conformance gets its own `extension` block. This is purely organizational
(the compiler treats it identically either way) but it makes a five-role
class much easier to navigate.

See the fully-commented version in: `ViewController.swift`,
`CustomUI/UICoordinatePanel.swift`, `CustomUI/UIRouteInfoPanel.swift`.

---

## 4. Extensions on types you don't own

```swift
extension UIView {
    func addSubviews(_ subviews: UIView...) { ... }
    func enableTapGestureRecognizer(target: Any?, action: Selector?) { ... }
}
```
Swift lets you add methods to *any* existing type — even ones from Apple's
own frameworks that you can't edit the source of. This project adds two
small conveniences to every `UIView` in the app: adding several subviews
in one call, and attaching a tap gesture recognizer in one line instead of
four.

See it in: `Source/Extension/UIView_addSubViews.swift`,
`Source/Extension/UIView_enableTapGestureRecognizer.swift`.

---

## 5. Closures and asynchronous code

A **closure** is a chunk of code you can pass around as a value, the same
way you'd pass an integer or a string.

```swift
routeService.calculateRoute(from: a, to: b) { [weak self] result in
    guard let self = self else { return }
    DispatchQueue.main.async {
        switch result {
        case .success(let route): self.showRoute(route, destination: destination)
        case .failure(let error): self.presentError(error)
        }
    }
}
```

Unpacking this line by line:
- `{ [weak self] result in ... }` is the closure itself — the trailing
  `{ }` after a function call is Swift's "trailing closure syntax."
- `calculateRoute` doesn't run this code immediately. It stores it and
  calls it **later**, once `MKDirections` gets a response from the network.
  A closure parameter that can be called after the function returns must
  be marked `@escaping` in the function's own signature (see
  `RouteService.swift`).
- `[weak self]` avoids a **retain cycle**: without it, the ViewController
  would keep this closure alive (because it stored the coordinatePanel
  etc.) and the closure would keep the ViewController alive (because it
  captures `self`) — neither would ever be freed from memory. Marking the
  capture `weak` breaks that cycle.
- `Result<MKRoute, Error>` forces you to handle both the success and
  failure case via `switch` — there's no way to accidentally use a route
  that doesn't exist.
- `DispatchQueue.main.async` hops back to the **main thread**. Network
  callbacks can land on a background thread, but all UIKit calls (updating
  a label, adding a map annotation) must happen on the main thread — this
  is a rule, not a suggestion; breaking it causes crashes or visual glitches
  that are hard to reproduce.

See it in: `RouteService.swift` (defines the closures' shape),
`ViewController.swift` (`drawRoute`, `searchBarSearchButtonClicked`).

---

## 6. Error handling with enums

```swift
enum RouteServiceError: LocalizedError {
    case noResultsFound
    case noRouteFound

    var errorDescription: String? {
        switch self {
        case .noResultsFound: return "No place matched that search."
        case .noRouteFound: return "No route could be found between these two points."
        }
    }
}
```
An `enum` lists a fixed, closed set of cases. Conforming to `LocalizedError`
lets each case carry its own human-readable message, retrieved anywhere via
`error.localizedDescription` — which is exactly what
`ViewController.presentError(_:)` displays in an alert.

See it in: `RouteService.swift`.

---

## 7. Auto Layout, written in code

Nothing in this project's UI panels or search bar is drawn in Interface
Builder — it's all built and positioned in Swift:

```swift
coordinatePanel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
coordinatePanel.topAnchor.constraint(equalTo: searchBar.bottomAnchor, constant: 4).isActive = true
```
Each `NSLayoutConstraint` is a mathematical relationship ("my leading edge
equals the safe area's leading edge") rather than a fixed pixel position —
that's what makes the layout adapt automatically to every screen size and
orientation. `.isActive = true` is what actually turns the constraint on;
creating one without activating it does nothing.

See it in: `ViewController.applyConstraints()`,
`CustomUI/UICoordinatePanel.applyConstraints()`,
`CustomUI/UIRouteInfoPanel.applyConstraints()`.

---

## 8. The app's lifecycle, end to end

1. **`AppDelegate`** — the single entry point (`@main`) for the whole app;
   handles app-wide launch/background events.
2. **`SceneDelegate`** — handles one window/screen's lifecycle (split out
   from AppDelegate since iOS 13 to support multiple windows on iPad).
3. **`Main.storyboard`** — hosts exactly one thing: the `MKMapView`. Every
   other view (search bar, both panels) is added and laid out in code.
4. **`ViewController`** — owns the map, the two panels, and the search bar;
   registers itself as the delegate for five different protocols; and
   delegates all actual MapKit networking to...
5. **`RouteService`** — a small, UI-free class that wraps `MKLocalSearch`
   and `MKDirections` behind a clean, testable API.

## 9. Walking through a real user action

Say the user types "Eiffel Tower" and taps search. Here's every hop, in
order (this is also drawn as a diagram earlier in the conversation):

1. `UISearchBar` fires `searchBarSearchButtonClicked(_:)` on its delegate —
   `ViewController` (delegate pattern, step 2 above).
2. `ViewController` calls `routeService.searchPlaces(matching:region:completion:)`,
   handing it a closure to run once results come back.
3. `RouteService` wraps the query in an `MKLocalSearch.Request` and starts
   the search — this is asynchronous, so the function returns immediately
   without a result yet.
4. Sometime later, MapKit calls RouteService's completion closure with a
   `Result<[MKMapItem], Error>`.
5. `RouteService` forwards that Result to whichever closure `ViewController`
   passed in back in step 2 — which calls `drawRoute(to:)` on success.
6. `drawRoute(to:)` calls `routeService.calculateRoute(from:to:completion:)`,
   the same request/callback shape as step 2, this time wrapping
   `MKDirections`.
7. Once a route comes back, `showRoute(_:destination:)` draws the polyline,
   drops a pin, and updates `UIRouteInfoPanel`'s `distanceText`/`durationText`
   — which, via their `didSet` observers, update their labels automatically.

Every one of those hops is one of the concepts above: delegation, escaping
closures, `Result`, `guard let`, and property observers, chained together
to get from a tap to a line on a map.

## Where the project could go next

- Add a segmented control to switch `transportType` between
  `.automobile`, `.walking`, and `.transit`.
- Show all of `MKLocalSearch`'s results in a list instead of always taking
  `items.first`.
- Add a unit test target and write tests against `RouteService` (it was
  kept UI-free specifically so this is possible) using a protocol +
  mock implementation instead of hitting the real network.
- Persist recent searches with `UserDefaults` — a good next concept to
  learn once everything above feels comfortable.

---

## 10. Ghidare vocală turn-by-turn (adăugat ulterior)

Peste structura de mai sus s-a adăugat o funcționalitate nouă: aplicația
anunță acum, cu voce, fiecare instrucțiune de pe rută pe măsură ce
utilizatorul se apropie de ea, exact ca într-o aplicație clasică de
navigație.

**Cum funcționează, pe scurt:**

1. `VoiceGuide.swift` — o clasă mică, dedicată exclusiv sintezei vocale,
   construită peste `AVSpeechSynthesizer`/`AVSpeechUtterance` din
   AVFoundation. Ideea de bază pentru configurarea unei `utterance` (voce,
   rată de vorbire) a pornit de la documentația Apple și de la tutorialul
   AppCoda ["Language Detection and Text to Speech in SwiftUI
   Apps"](https://medium.com/appcoda-tutorials/language-detection-and-text-to-speech-in-swiftui-apps-58e783e83db6),
   care explică bine API-ul de bază.
2. `ViewController.swift` a fost extins ca să rețină pașii rutei curente
   (`route.steps`) și să urmărească poziția continuu (nu doar o singură
   citire) cât timp o rută e activă.
3. La fiecare actualizare de poziție, se verifică distanța până la
   finalul etapei curente (`checkProgressAlongRoute`); sub un prag de 30m,
   se trece la instrucțiunea următoare și se rostește cu voce tare.
4. La ultima etapă, aplicația anunță sosirea la destinație și oprește
   urmărirea continuă a poziției (ca să economisească baterie).

Aceeași separare de responsabilități ca la `RouteService`: logica de
"vorbit" stă izolată în `VoiceGuide`, iar `ViewController` decide doar
*când* să apeleze `voiceGuide.speak(...)`.
