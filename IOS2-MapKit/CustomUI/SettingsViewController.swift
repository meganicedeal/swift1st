//
//  SettingsViewController.swift
//  IOS2-MapKit
//
//  Ecran simplu de preferințe: unitatea de măsură (km/mi) și aspectul
//  hărții (zi/noapte). Prezentat modal, la fel ca FavoritesListViewController
//  — aceeași convenție de navigare pentru toate ecranele secundare din
//  aplicație.
//

import UIKit

protocol SettingsViewControllerDelegate: AnyObject {
    func settingsDidChange(_ controller: SettingsViewController)
}

final class SettingsViewController: UIViewController {

    weak var delegate: SettingsViewControllerDelegate?

    private let unitLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Unități de măsură"
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let unitControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Metric (km)", "Imperial (mi)"])
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    private let appearanceLabel: UILabel = {
        let lbl = UILabel()
        lbl.text = "Aspect hartă"
        lbl.font = UIFont.boldSystemFont(ofSize: 16)
        lbl.translatesAutoresizingMaskIntoConstraints = false
        return lbl
    }()

    private let appearanceControl: UISegmentedControl = {
        let control = UISegmentedControl(items: ["Zi", "Noapte"])
        control.translatesAutoresizingMaskIntoConstraints = false
        return control
    }()

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Preferințe"
        view.backgroundColor = .systemBackground

        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        // La deschidere, segmentele reflectă preferințele deja salvate —
        // ecranul nu are stare proprie, doar citește și scrie direct în
        // UserPreferences.shared.
        unitControl.selectedSegmentIndex = UserPreferences.shared.unitSystem == .imperial ? 1 : 0
        appearanceControl.selectedSegmentIndex = UserPreferences.shared.mapAppearance == .night ? 1 : 0

        unitControl.addTarget(self, action: #selector(unitChanged), for: .valueChanged)
        appearanceControl.addTarget(self, action: #selector(appearanceChanged), for: .valueChanged)

        view.addSubview(unitLabel)
        view.addSubview(unitControl)
        view.addSubview(appearanceLabel)
        view.addSubview(appearanceControl)

        applyConstraints()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    @objc private func unitChanged() {
        UserPreferences.shared.unitSystem = unitControl.selectedSegmentIndex == 1 ? .imperial : .metric
        delegate?.settingsDidChange(self)
    }

    @objc private func appearanceChanged() {
        UserPreferences.shared.mapAppearance = appearanceControl.selectedSegmentIndex == 1 ? .night : .day
        delegate?.settingsDidChange(self)
    }

    private func applyConstraints() {
        unitLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 24).isActive = true
        unitLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true

        unitControl.topAnchor.constraint(equalTo: unitLabel.bottomAnchor, constant: 8).isActive = true
        unitControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        unitControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true

        appearanceLabel.topAnchor.constraint(equalTo: unitControl.bottomAnchor, constant: 24).isActive = true
        appearanceLabel.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true

        appearanceControl.topAnchor.constraint(equalTo: appearanceLabel.bottomAnchor, constant: 8).isActive = true
        appearanceControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 16).isActive = true
        appearanceControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -16).isActive = true
    }
}
