//
//  FavoritesService.swift
//  IOS2-MapKit
//
//  Wraps SwiftData's ModelContainer/ModelContext so the rest of the app
//  doesn't need to know anything about the persistence layer directly.
//
//  DE CE UN FIȘIER SEPARAT?
//  Exact aceeași filozofie ca la RouteService.swift și VoiceGuide.swift:
//  izolăm un framework (aici SwiftData) într-o clasă mică, cu o singură
//  responsabilitate — salvarea, citirea și ștergerea destinațiilor
//  favorite. ViewController-ul nu are nevoie să știe ce e un
//  ModelContainer sau un FetchDescriptor, doar apelează
//  `favoritesService.save(...)` sau `favoritesService.fetchAll()`.
//
//  TEORIE — ModelContainer vs. ModelContext:
//  - `ModelContainer` este "baza de date" propriu-zisă: definește schema
//    (aici, un singur tip de model — FavoriteDestination) și se ocupă de
//    fișierul de pe disc unde se stochează efectiv datele.
//  - `ModelContext` este spațiul de lucru în care faci modificări
//    (inserare, ștergere) înainte să le salvezi. E similar cu
//    NSManagedObjectContext din Core Data, pentru cei care au mai văzut
//    framework-ul vechi.
//

import Foundation
import SwiftData
import CoreLocation

final class FavoritesService {

    private let container: ModelContainer
    private let context: ModelContext

    init() {
        do {
            container = try ModelContainer(for: FavoriteDestination.self)
        } catch {
            // Dacă inițializarea bazei locale eșuează, ceva e grav în
            // neregulă cu mediul de rulare (spațiu de stocare corupt,
            // schemă incompatibilă etc.) — nu există o cale rezonabilă de
            // recuperare la runtime, așa că oprim aplicația cu un mesaj
            // clar, în loc s-o lăsăm într-o stare inconsistentă.
            fatalError("Nu s-a putut inițializa baza de date locală (SwiftData): \(error)")
        }
        context = ModelContext(container)
    }

    /// Salvează o nouă destinație favorită.
    func save(name: String, coordinate: CLLocationCoordinate2D) {
        let favorite = FavoriteDestination(
            name: name,
            latitude: coordinate.latitude,
            longitude: coordinate.longitude
        )
        context.insert(favorite)
        try? context.save()
    }

    /// Returnează toate destinațiile favorite, cele mai recent adăugate
    /// primele.
    func fetchAll() -> [FavoriteDestination] {
        let descriptor = FetchDescriptor<FavoriteDestination>(
            sortBy: [SortDescriptor(\.dateAdded, order: .reverse)]
        )
        return (try? context.fetch(descriptor)) ?? []
    }

    /// Șterge o destinație favorită.
    func delete(_ favorite: FavoriteDestination) {
        context.delete(favorite)
        try? context.save()
    }
}
