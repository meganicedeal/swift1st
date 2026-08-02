//
//  UIRouteInfoPanel.swift
//  IOS2-MapKit
//
//  Floating panel shown at the bottom of the map once a route has been
//  calculated. Displays distance + estimated travel time, and offers a
//  button to clear the current route. Mirrors the style/pattern already
//  established by UICoordinatePanel.
//
//  This file deliberately reuses the exact same shape as UICoordinatePanel:
//  a protocol + a default-implementation extension (delegate pattern), and
//  `didSet` property observers on distanceText/durationText. See the
//  detailed comments in UICoordinatePanel.swift — once you understand that
//  file, this one is the same pattern applied to a second, unrelated piece
//  of UI. Recognizing "I've seen this shape before" is a big part of
//  reading unfamiliar Swift/iOS code productively.
//

import UIKit

protocol UIRouteInfoPanelDelegate {
    func routeInfoPanelClearButtonTapped(_ sender: Any?)
}

extension UIRouteInfoPanelDelegate {
    // Default no-op implementation, same pattern as UICoordinatePanelDelegate,
    // so conforming types only need to implement what they care about.
    func routeInfoPanelClearButtonTapped(_ sender: Any?) {}
}

class UIRouteInfoPanel: UIView {

    public var delegate: UIRouteInfoPanelDelegate?

    static private func defaultLabel(text: String, bold: Bool = false, size: CGFloat = 16) -> UILabel {
        let lbl = UILabel()
        lbl.text = text
        lbl.font = bold ? UIFont.boldSystemFont(ofSize: size) : UIFont.systemFont(ofSize: size)
        lbl.textColor = .black
        lbl.textAlignment = .left
        lbl.numberOfLines = 1
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }

    private var lblDistance: UILabel = UIRouteInfoPanel.defaultLabel(text: "--", bold: true, size: 17)
    private var lblDuration: UILabel = UIRouteInfoPanel.defaultLabel(text: "--", size: 15)

    private var btnClear: UIButton = {
        let btn = UIButton(type: .system)
        btn.setTitle("Clear", for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 15)
        btn.translatesAutoresizingMaskIntoConstraints = false
        return btn
    }()

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
        backgroundColor = .white.withAlphaComponent(0.9)
        layer.cornerRadius = 14
        clipsToBounds = true

        addSubviews(lblDistance, lblDuration, btnClear)
        btnClear.addTarget(self, action: #selector(clearTapped), for: .touchUpInside)

        applyConstraints()
    }

    @objc private func clearTapped() {
        delegate?.routeInfoPanelClearButtonTapped(self)
    }

    private func applyConstraints() {
        lblDistance.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16).isActive = true
        lblDistance.topAnchor.constraint(equalTo: topAnchor, constant: 8).isActive = true

        lblDuration.leadingAnchor.constraint(equalTo: lblDistance.leadingAnchor).isActive = true
        lblDuration.topAnchor.constraint(equalTo: lblDistance.bottomAnchor, constant: 2).isActive = true
        lblDuration.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8).isActive = true

        btnClear.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16).isActive = true
        btnClear.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
    }
}
