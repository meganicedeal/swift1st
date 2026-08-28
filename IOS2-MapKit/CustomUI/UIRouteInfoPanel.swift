//
//  UIRouteInfoPanel.swift
//  IOS2-MapKit
//
//  Floating panel shown at the bottom of the map once a route has been
//  calculated. Displays distance + estimated travel time, and offers
//  buttons to clear the route, save it as a favorite, and preview it
//  with Look Around. Mirrors the style/pattern already established by
//  UICoordinatePanel.
//
//  This file deliberately reuses the exact same shape as UICoordinatePanel:
//  a protocol + a default-implementation extension (delegate pattern), and
//  `didSet` property observers on distanceText/durationText. See the
//  detailed comments in UICoordinatePanel.swift — once you understand that
//  file, this one is the same pattern applied to a second, unrelated piece
//  of UI. Recognizing "I've seen this shape before" is a big part of
//  reading unfamiliar Swift/iOS code productively.
//
//  Toate culorile și fonturile de mai jos vin din AppTheme.swift, nu sunt
//  alese pe loc — asta ține panoul vizual consecvent cu restul aplicației
//  și face schimbarea temei o modificare într-un singur loc, nu zece.
//

import UIKit

protocol UIRouteInfoPanelDelegate {
    func routeInfoPanelClearButtonTapped(_ sender: Any?)
    func routeInfoPanelSaveButtonTapped(_ sender: Any?)
    func routeInfoPanelLookAroundButtonTapped(_ sender: Any?)
}

extension UIRouteInfoPanelDelegate {
    // Default no-op implementation, same pattern as UICoordinatePanelDelegate,
    // so conforming types only need to implement what they care about.
    func routeInfoPanelClearButtonTapped(_ sender: Any?) {}
    func routeInfoPanelSaveButtonTapped(_ sender: Any?) {}
    func routeInfoPanelLookAroundButtonTapped(_ sender: Any?) {}
}

class UIRouteInfoPanel: UIView {

    public var delegate: UIRouteInfoPanelDelegate?

    // Bară subțire, colorată, lipită de marginea de sus a panoului — un
    // detaliu mic, dar e semnătura vizuală care leagă acest panou de
    // restul interfeței (aceeași culoare ca ruta desenată pe hartă și ca
    // butoanele principale).
    private let accentBar: UIView = {
        let view = UIView()
        view.backgroundColor = AppTheme.primary
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()

    // Distanța e "cifra mare" a panoului — de aceea folosește fontul
    // rotunjit, la o dimensiune vizibil mai mare decât restul textului,
    // ca un afișaj de bord, nu doar o etichetă printre altele.
    private let lblDistance: UILabel = {
        let lbl = UILabel()
        lbl.text = "--"
        lbl.font = AppTheme.roundedFont(size: 24, weight: .bold)
        lbl.textColor = AppTheme.textPrimary
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let lblDuration: UILabel = {
        let lbl = UILabel()
        lbl.text = "--"
        lbl.font = UIFont.systemFont(ofSize: 14, weight: .medium)
        lbl.textColor = AppTheme.textSecondary
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private static func iconButton(systemName: String, tintColor: UIColor) -> UIButton {
        let btn = UIButton(type: .system)
        btn.setImage(UIImage(systemName: systemName), for: .normal)
        btn.tintColor = tintColor
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }

    // Butonul de previzualizare Look Around folosește accentul principal
    // (aceeași culoare ca ruta de pe hartă) — e cea mai "importantă"
    // acțiune secundară din panou. Salvarea la favorite primește
    // accentul secundar (teal), iar Clear rămâne discret, în gri — e o
    // acțiune de resetare, nu una pe care vrem s-o scoatem în evidență.
    private let btnLookAround = UIRouteInfoPanel.iconButton(systemName: "binoculars", tintColor: AppTheme.primary)
    private let btnSave = UIRouteInfoPanel.iconButton(systemName: "star", tintColor: AppTheme.secondary)
    private let btnClear = UIRouteInfoPanel.iconButton(systemName: "xmark.circle", tintColor: AppTheme.textSecondary)

    public var distanceText: String = "--" {
        didSet { lblDistance.text = distanceText }
    }

    public var durationText: String = "--" {
        didSet { lblDuration.text = durationText }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialize() {
        translatesAutoresizingMaskIntoConstraints = false
        backgroundColor = AppTheme.panelBackground
        layer.cornerRadius = AppTheme.cardCornerRadius
        clipsToBounds = true

        addSubviews(accentBar, lblDistance, lblDuration, btnClear, btnSave, btnLookAround)
        btnClear.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)
        btnSave.addTarget(self, action: #selector(saveTapped), for: .touchUpInside)
        btnLookAround.addTarget(self, action: #selector(lookAroundTapped), for: .touchUpInside)

        applyConstraints()
    }

    @objc private func clearTapped() {
        delegate?.routeInfoPanelClearButtonTapped(self)
    }

    @objc private func saveTapped() {
        delegate?.routeInfoPanelSaveButtonTapped(self)
    }

    @objc private func lookAroundTapped() {
        delegate?.routeInfoPanelLookAroundButtonTapped(self)
    }

    private func applyConstraints() {
        accentBar.topAnchor.constraint(equalTo: topAnchor).isActive = true
        accentBar.leadingAnchor.constraint(equalTo: leadingAnchor).isActive = true
        accentBar.trailingAnchor.constraint(equalTo: trailingAnchor).isActive = true
        accentBar.heightAnchor.constraint(equalToConstant: 4).isActive = true

        lblDistance.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        lblDistance.topAnchor.constraint(equalTo: accentBar.bottomAnchor, constant: 10).isActive = true

        lblDuration.leadingAnchor.constraint(equalTo: lblDistance.leadingAnchor).isActive = true
        lblDuration.topAnchor.constraint(equalTo: lblDistance.bottomAnchor, constant: 2).isActive = true
        lblDuration.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -10).isActive = true

        btnClear.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        btnClear.centerYAnchor.constraint(equalTo: centerYAnchor, constant: 2).isActive = true

        btnSave.trailingAnchor.constraint(equalTo: btnClear.leadingAnchor, constant: -18).isActive = true
        btnSave.centerYAnchor.constraint(equalTo: btnClear.centerYAnchor).isActive = true

        btnLookAround.trailingAnchor.constraint(equalTo: btnSave.leadingAnchor, constant: -18).isActive = true
        btnLookAround.centerYAnchor.constraint(equalTo: btnClear.centerYAnchor).isActive = true
    }
}
