//
//  SearchHistoryStore.swift
//  IOS2-MapKit
//
//  Reține ultimele căutări de destinații, persistent, cu UserDefaults.
//  Aceeași filozofie ca UserPreferences: o clasă mică, dedicată exclusiv
//  acestei responsabilități, ca ViewController să nu manipuleze direct
//  UserDefaults sau logica de deduplicare/limitare.
//

import Foundation

final class SearchHistoryStore {

    private let defaults = UserDefaults.standard
    private let key = "recentSearches"

    /// Numărul maxim de căutări reținute — dincolo de acesta, cele mai
    /// vechi sunt eliminate automat la fiecare căutare nouă.
    private let maxEntries = 10

    /// Căutările recente, cea mai nouă prima.
    func recentSearches() -> [String] {
        defaults.stringArray(forKey: key) ?? []
    }

    /// Adaugă o căutare nouă în capul listei. Dacă același text (fără a
    /// ține cont de majuscule) există deja, vechea apariție e eliminată
    /// întâi — altfel aceeași destinație căutată de mai multe ori ar
    /// umple lista cu duplicate, în loc să urce pur și simplu în vârf.
    func addSearch(_ query: String) {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        var searches = recentSearches()
        searches.removeAll { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        searches.insert(trimmed, at: 0)

        if searches.count > maxEntries {
            searches = Array(searches.prefix(maxEntries))
        }

        defaults.set(searches, forKey: key)
    }

    /// Șterge tot istoricul de căutări.
    func clear() {
        defaults.removeObject(forKey: key)
    }
}
