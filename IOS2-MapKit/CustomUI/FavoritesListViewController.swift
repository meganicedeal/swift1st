//
//  FavoritesListViewController.swift
//  IOS2-MapKit
//
//  Ecran simplu, cu listă (UITableViewController), care afișează
//  destinațiile favorite salvate și permite selectarea uneia (pentru a
//  calcula ruta către ea) sau ștergerea ei prin swipe.
//
//  Este prezentat modal, peste harta principală, ca să nu complicăm
//  navigația existentă din ViewController — vezi apelul din
//  ViewController.swift (favoritesButtonTapped).
//

import UIKit

protocol FavoritesListViewControllerDelegate: AnyObject {
    func favoritesList(_ controller: FavoritesListViewController, didSelect favorite: FavoriteDestination)
}

final class FavoritesListViewController: UITableViewController {

    private static let cellIdentifier = "FavoriteCell"

    weak var delegate: FavoritesListViewControllerDelegate?

    private let favoritesService: FavoritesService
    private var favorites: [FavoriteDestination] = []

    // Injectăm FavoritesService din exterior (nu îl creăm aici) ca să
    // existe o singură instanță de serviciu — și, implicit, un singur
    // ModelContext — folosită în toată aplicația. Acest tip de
    // "dependency injection" prin inițializator e același principiu ca
    // la RouteService, care e creat o singură dată în ViewController.
    init(favoritesService: FavoritesService) {
        self.favoritesService = favoritesService
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        title = "Favorite"
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )

        reload()
    }

    private func reload() {
        favorites = favoritesService.fetchAll()
        tableView.reloadData()
    }

    @objc private func closeTapped() {
        dismiss(animated: true)
    }

    // MARK: - UITableViewDataSource

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        favorites.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        cell.textLabel?.text = favorites[indexPath.row].name
        return cell
    }

    // MARK: - UITableViewDelegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let favorite = favorites[indexPath.row]
        dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            self.delegate?.favoritesList(self, didSelect: favorite)
        }
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        guard editingStyle == .delete else { return }

        let favorite = favorites[indexPath.row]
        favoritesService.delete(favorite)
        favorites.remove(at: indexPath.row)
        tableView.deleteRows(at: [indexPath], with: .automatic)
    }
}
