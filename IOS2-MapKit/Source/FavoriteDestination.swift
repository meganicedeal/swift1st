//
//  FavoriteDestination.swift
//  IOS2-MapKit
//
//  Modelul de date pentru o destinație salvată de utilizator.
//
//  TEORIE — ce este @Model?
//  SwiftData este framework-ul de persistență introdus de Apple în iOS 17,
//  gândit ca un înlocuitor mai simplu pentru Core Data. Atributul `@Model`
//  transformă o clasă Swift obișnuită într-o entitate persistentă: SwiftData
//  generează automat, în spate, tot ce ține de stocare (schema, tabelele),
//  fără fișiere `.xcdatamodeld` separate ca la Core Data.
//
//  Practic, `FavoriteDestination` e o clasă Swift ca oricare alta — o poți
//  crea cu `FavoriteDestination(name:...)`, îi poți citi proprietățile — dar
//  odată inserată într-un `ModelContext` (vezi FavoritesService.swift),
//  SwiftData se ocupă să o salveze pe disc și să o aducă înapoi la
//  următoarea lansare a aplicației.
//

import Foundation
import SwiftData
import CoreLocation

@Model
final class FavoriteDestination {

    var name: String
    var latitude: Double
    var longitude: Double
    var dateAdded: Date

    // Coordonatele se rețin ca `Double`-uri simple (nu ca
    // `CLLocationCoordinate2D`), pentru că tipul acela nu este direct
    // compatibil cu modelul de persistență SwiftData. Proprietatea
    // calculată `coordinate` de mai jos face conversia înapoi, ca restul
    // codului (RouteService, MapKit) să lucreze în continuare cu tipul
    // obișnuit CLLocationCoordinate2D.
    init(name: String, latitude: Double, longitude: Double, dateAdded: Date = .now) {
        self.name = name
        self.latitude = latitude
        self.longitude = longitude
        self.dateAdded = dateAdded
    }

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}
