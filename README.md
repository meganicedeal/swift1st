# MapKit Navigator

An iOS app built with **UIKit + MapKit** that shows your current location on a
map and lets you search for a destination and see a route drawn to it, with
live distance and ETA.

This project merges two earlier learning exercises into one working app:

- a **live location** exercise (`IOS2-MapKit`): request permission, track the
  user's position, and display it on the map with a small custom overlay
  panel showing latitude/longitude,
- a **navigation** exercise (`Navigation`): search for a destination and draw
  a route to it.

Since the "Navigation" project was only a skeleton, that feature was rebuilt
from scratch and layered on top of the working MapKit project below.

## Features

- Requests location permission and centers the map on the user
- Custom floating panel showing live latitude/longitude (tap the target icon
  to re-center)
- Search bar to look up a destination by name/address (`MKLocalSearch`)
- Draws the route to the destination (`MKDirections`) with a highlighted
  polyline
- Bottom panel showing distance + estimated travel time, with a button to
  clear the current route

## Project structure

```
IOS2-MapKit/
├── AppDelegate.swift
├── SceneDelegate.swift
├── ViewController.swift          # Map, search bar, location + route wiring
├── Info.plist
├── CustomUI/
│   ├── UICoordinatePanel.swift   # Lat/long overlay panel
│   └── UIRouteInfoPanel.swift    # Distance/ETA overlay panel
├── Source/
│   ├── RouteService.swift        # MKLocalSearch + MKDirections wrapper
│   └── Extension/
│       ├── UIView_addSubViews.swift
│       └── UIView_enableTapGestureRecognizer.swift
└── Base.lproj/
    ├── Main.storyboard           # Just hosts the MKMapView
    └── LaunchScreen.storyboard
```

The UI panels (coordinate panel, route info panel) and the search bar are all
added and laid out **programmatically** in `ViewController.swift` — the
storyboard only hosts the `MKMapView` itself, so there's very little to wire
up by hand in Interface Builder.

## Requirements

- Xcode 13+ (project targets iOS 15.2)
- A physical device or simulator with a simulated location, since the app
  needs a location fix to center the map and calculate routes

## Getting started

1. Clone the repo and open `IOS2-MapKit.xcodeproj` in Xcode.
2. Select the `IOS2-MapKit` target → **Signing & Capabilities** → choose your
   own team (the original developer's team ID was removed from this repo).
3. Optionally change `PRODUCT_BUNDLE_IDENTIFIER` if you want your own bundle ID.
4. Build and run. On the simulator, use **Features → Location** to simulate a
   position if you don't have a real GPS fix.
5. Grant location access when prompted, then type a destination in the search
   bar and hit search to see the route.

## Notes / possible next steps

- Route calculation currently defaults to driving directions
  (`MKDirectionsTransportType.automobile`); a segmented control to switch
  between driving/walking/transit would be a natural next step.
- Search only takes the first result from `MKLocalSearch`; a results list
  would make it more robust for ambiguous queries.
- No automated tests yet — `RouteService` was written as a small standalone
  class specifically so it could be unit-tested (with a protocol + mock) if
  you want to add a test target later.

## License

MIT — see [LICENSE](LICENSE).
