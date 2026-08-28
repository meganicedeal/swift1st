//
//  AppTheme.swift
//  IOS2-MapKit
//
//  Paleta de culori și tipografia aplicației, centralizate într-un singur
//  loc — aceeași idee ca RouteService, VoiceGuide sau FavoritesService:
//  izolăm o responsabilitate (aici, identitatea vizuală) ca restul
//  codului să nu mai împrăștie valori hardcodate (.systemBlue, .white)
//  prin fiecare fișier de UI. Dacă vrem vreodată să schimbăm accentul
//  aplicației, se schimbă o singură dată, aici — nu în zece fișiere.
//
//  DIRECȚIA VIZUALĂ ("temă de cartograf"):
//  În loc de albul și albastrul de sistem, implicite pe orice aplicație
//  iOS necustomizată, am ales o paletă inspirată de hărțile de navigație
//  clasice, pe hârtie: fundal cald, gen pergament, pentru panouri, cu
//  accent bleumarin ("Ink Navy") pentru elementele principale și un teal
//  domol ("Compass Teal") pentru cele secundare. Cifrele (distanță,
//  durată) folosesc SF Rounded — o variantă rotunjită a fontului de
//  sistem, oferită gratuit de iOS, fără să fie nevoie de niciun font
//  extern adăugat în proiect.
//

import UIKit

enum AppTheme {

    // MARK: - Culori
    // Denumite după rolul lor în interfață, nu după cum arată ("primary"
    // nu "navy") — ca numele să rămână corecte chiar dacă alegem
    // vreodată o altă nuanță concretă.

    /// Accentul principal al aplicației — butoane primare, ruta desenată
    /// pe hartă, pinul destinației finale. "Ink Navy", #1B3B4B.
    static let primary = UIColor(red: 0.106, green: 0.231, blue: 0.294, alpha: 1)

    /// Accent secundar, pentru acțiuni auxiliare — pinii opririlor
    /// intermediare, butonul de salvare la favorite. "Compass Teal",
    /// #2F6E62.
    static let secondary = UIColor(red: 0.184, green: 0.431, blue: 0.384, alpha: 1)

    /// Fundalul panourilor plutitoare (căutare, coordonate, info rută) —
    /// un alb cald, gen pergament, în loc de alb rece de sistem.
    /// "Parchment", #FBF6ED.
    static let panelBackground = UIColor(red: 0.984, green: 0.965, blue: 0.929, alpha: 0.94)

    /// Text principal, pe fundal deschis. "Graphite", #23262B.
    static let textPrimary = UIColor(red: 0.137, green: 0.149, blue: 0.169, alpha: 1)

    /// Text secundar/etichete — mai discret decât textul principal, dar
    /// tot suficient de contrastant pentru accesibilitate. "Slate".
    static let textSecondary = UIColor(red: 0.420, green: 0.447, blue: 0.502, alpha: 1)

    // MARK: - Tipografie

    /// Variantă rotunjită a fontului de sistem — folosită pentru cifrele
    /// importante (distanță, durată), ca un afișaj de bord de mașină,
    /// prietenos, nu un simplu text de etichetă.
    static func roundedFont(size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        guard let descriptor = systemFont.fontDescriptor.withDesign(.rounded) else {
            return systemFont
        }
        return UIFont(descriptor: descriptor, size: size)
    }

    // MARK: - Formă

    /// Raza de colț folosită uniform pe toate panourile plutitoare, ca
    /// să pară că aparțin aceluiași sistem vizual.
    static let cardCornerRadius: CGFloat = 16
}
