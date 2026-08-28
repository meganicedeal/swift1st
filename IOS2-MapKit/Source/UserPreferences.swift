//
//  UserPreferences.swift
//  IOS2-MapKit
//
//  Preferințele configurabile de utilizator: unitatea de măsură (metric
//  sau imperial) și aspectul hărții (zi sau noapte). Salvate persistent
//  cu UserDefaults, ca să rămână setate și după ce aplicația e închisă.
//
//  DE CE UN FIȘIER SEPARAT?
//  Aceeași filozofie ca la RouteService, VoiceGuide și FavoritesService:
//  izolăm framework-ul de sistem (aici UserDefaults) într-o clasă mică,
//  cu o singură responsabilitate. Restul codului nu știe și nu are
//  nevoie să știe că preferințele stau în UserDefaults — ar putea la
//  fel de bine sta în SwiftData sau într-un fișier, fără ca vreun alt
//  fișier din proiect să se schimbe.
//
//  TEORIE — de ce `static let shared` (un singleton)?
//  Spre deosebire de RouteService sau FavoritesService (create o singură
//  dată, în ViewController, și pasate mai departe), preferințele trebuie
//  citite din mai multe locuri independente (ViewController, dar și un
//  eventual ecran de setări separat) fără să ținem minte manual cine
//  deține instanța. UserDefaults.standard e el însuși un singleton
//  oferit de sistem, așa că a avea și noi unul singur, la rândul nostru,
//  e o potrivire naturală — nu există niciun motiv practic să existe mai
//  multe instanțe ale acestei clase în aceeași aplicație.
//

import Foundation

enum UnitSystem: String {
    case metric
    case imperial
}

enum MapAppearance: String {
    case day
    case night
}

final class UserPreferences {

    static let shared = UserPreferences()

    private enum Keys {
        static let unitSystem = "unitSystem"
        static let mapAppearance = "mapAppearance"
    }

    private let defaults = UserDefaults.standard

    private init() {}

    var unitSystem: UnitSystem {
        get { UnitSystem(rawValue: defaults.string(forKey: Keys.unitSystem) ?? "") ?? .metric }
        set { defaults.set(newValue.rawValue, forKey: Keys.unitSystem) }
    }

    var mapAppearance: MapAppearance {
        get { MapAppearance(rawValue: defaults.string(forKey: Keys.mapAppearance) ?? "") ?? .day }
        set { defaults.set(newValue.rawValue, forKey: Keys.mapAppearance) }
    }
}
