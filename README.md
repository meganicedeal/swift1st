# MapKit Navigator

O aplicație de navigare pentru iOS, construită cu **UIKit + MapKit**, care
arată poziția curentă pe hartă, caută destinații, calculează și desenează
rute — cu ghidare vocală, opriri multiple, favorite salvate și alte
funcționalități adăugate treptat.

## Povestea proiectului

Proiectul a pornit ca temă de facultate: două exerciții separate de
Xcode, unul despre urmărirea locației live (`IOS2-MapKit`), altul despre
căutare de destinații și calcul de rută (`Navigation`). Cel de-al doilea
era doar un schelet, așa că funcționalitatea de navigare a fost
reconstruită de la zero și pusă peste proiectul de bază, deja funcțional.

De acolo, aplicația a fost transformată treptat într-un proiect mult mai
avansat — nu dintr-o dată, ci funcționalitate cu funcționalitate, fiecare
cu propriul ei commit: ghidare vocală, recalculare automată la abatere de
la traseu, rute cu mai multe opriri, destinații favorite, distanță și ETA
live, previzualizare Look Around, o identitate vizuală proprie și istoric
de căutări. `LEARNING.md` documentează fiecare pas al acestei evoluții,
în ordine, cu explicația tehnică din spatele lui.

## Funcționalități

- Cere permisiunea de locație și centrează harta pe poziția utilizatorului
- Panou plutitor cu latitudine/longitudine live (buton de recentrare)
- Bară de căutare pentru destinații (`MKLocalSearch`)
- **Rută cu mai multe opriri** — fiecare căutare (sau favorit selectat)
  adaugă o oprire nouă, nu înlocuiește traseul existent
- **Ghidare vocală turn-by-turn**, cu anunț separat la fiecare oprire
  intermediară și la destinația finală
- **Recalculare automată a rutei** dacă utilizatorul se abate de la
  traseul desenat
- **Distanță rămasă și ETA live**, actualizate continuu din poziția GPS
- **Destinații favorite**, persistate cu SwiftData
- **Look Around** (Street View-ul Apple) la destinație
- **Istoric de căutări recente**, cu sugestii sub bara de căutare
- Preferințe: unitate de măsură (metric/imperial) și aspect hartă
  (zi/noapte)
- Identitate vizuală proprie ("temă de cartograf") — vezi `AppTheme.swift`

## Structura proiectului

```
IOS2-MapKit/
├── AppDelegate.swift
├── SceneDelegate.swift
├── ViewController.swift              # Harta, bara de căutare, navigarea
├── Info.plist
├── CustomUI/
│   ├── UICoordinatePanel.swift       # Panou latitudine/longitudine
│   ├── UIRouteInfoPanel.swift        # Panou distanță/ETA + acțiuni rută
│   ├── FavoritesListViewController.swift  # Listă favorite (modal)
│   └── SettingsViewController.swift       # Ecran preferințe (modal)
├── Source/
│   ├── RouteService.swift            # MKLocalSearch + MKDirections
│   ├── VoiceGuide.swift              # AVSpeechSynthesizer (ghidare vocală)
│   ├── FavoritesService.swift        # SwiftData (destinații favorite)
│   ├── FavoriteDestination.swift     # Model SwiftData
│   ├── SearchHistoryStore.swift      # UserDefaults (istoric căutări)
│   ├── UserPreferences.swift         # UserDefaults (preferințe)
│   ├── WaypointAnnotation.swift      # Pin hartă (oprire vs. destinație)
│   ├── AppTheme.swift                # Culori și tipografie centralizate
│   └── Extension/
│       ├── UIView_addSubViews.swift
│       └── UIView_enableTapGestureRecognizer.swift
└── Base.lproj/
    ├── Main.storyboard               # Găzduiește doar MKMapView
    └── LaunchScreen.storyboard
```

Panourile de UI (coordonate, info rută), bara de căutare și tabelul de
istoric sunt toate adăugate și poziționate **programatic**, în
`ViewController.swift` — storyboard-ul găzduiește doar `MKMapView`.

## Cerințe

- Xcode 15+ (proiectul țintește iOS 17.0, necesar pentru SwiftData)
- Un dispozitiv fizic sau un simulator cu o locație simulată, pentru că
  aplicația are nevoie de o poziție GPS ca să centreze harta și să
  calculeze rute

## Învățare Swift din acest proiect

Dacă folosești proiectul ca să înveți Swift/iOS, vezi
[`LEARNING.md`](LEARNING.md) — un ghid complet, în ordinea în care au
apărut lucrurile: de la concepte de bază (optionals, delegate pattern,
closures) până la fiecare funcționalitate adăugată ulterior, fiecare
secțiune trimițând la codul exact care o ilustrează.

## Primii pași

1. Clonează repo-ul și deschide `IOS2-MapKit.xcodeproj` în Xcode.
2. Selectează target-ul `IOS2-MapKit` → **Signing & Capabilities** →
   alege propriul team (ID-ul original a fost eliminat din acest repo).
3. Opțional, schimbă `PRODUCT_BUNDLE_IDENTIFIER` dacă vrei propriul bundle ID.
4. Compilează și rulează. În simulator, folosește **Features → Location**
   ca să simulezi o poziție dacă nu ai un fix GPS real.
5. Acordă acces la locație când ești întrebat, apoi caută o destinație în
   bara de căutare.

## Posibili pași următori

- Segmented control pentru a alege între mers pe jos/mașină/transport
  public (`MKDirectionsTransportType`)
- O listă completă de rezultate la căutare, nu doar primul rezultat
- Widget iOS / Live Activity pentru ETA (necesită un target nou de
  extensie în Xcode — vezi discuția din `LEARNING.md`)
- Suport CarPlay (necesită entitlement aprobat de Apple)
- Teste automate — `RouteService` a fost scris ca o clasă mică,
  independentă, special ca să poată fi testată unitar (cu un protocol +
  un mock), dacă se adaugă vreodată un target de teste

## Licență

MIT — vezi [LICENSE](LICENSE).
