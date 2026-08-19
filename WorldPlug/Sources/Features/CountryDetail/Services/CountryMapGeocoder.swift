//
//  CountryMapGeocoder.swift
//  WorldPlug
//
//  Created by Antonino.Musolino on 13/07/2026.
//

import CoreLocation
import MapKit

// MARK: - CountryMapLookup

struct CountryMapLookup: Sendable {
    let code: String
}

// MARK: - CountryMapFocus

struct CountryMapFocus {
    let coordinate: CLLocationCoordinate2D
    let region: MKCoordinateRegion
    let cameraDistance: CLLocationDistance
}

// MARK: - CountryMapGeocoder

actor CountryMapGeocoder {
    static let shared = CountryMapGeocoder()

    private var cache: [String: CountryMapFocus] = [:]
    /// Country codes already queried this app session with no usable map focus found — avoids
    /// re-issuing the same failing `MKLocalSearch` every time the country's detail screen is
    /// revisited. Naturally resets on the next app launch.
    private var codesWithoutAFocus: Set<String> = []

    func focus(for country: CountryMapLookup) async -> CountryMapFocus? {
        if let cached = cache[country.code] {
            return cached
        }
        guard !codesWithoutAFocus.contains(country.code) else {
            return nil
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = Locale(identifier: "en_US").localizedString(forRegionCode: country.code)
        request.region = .world
        request.resultTypes = [.address]

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let mapItem = bestMapItem(in: response.mapItems, for: country) else {
                codesWithoutAFocus.insert(country.code)
                return nil
            }

            let coordinate = mapItem.location.coordinate
            let region = response.boundingRegion
            let radius = max(region.approximateHighlightRadius, 140_000)
            let focusRegion = MKCoordinateRegion(
                center: region.center.latitude == 0 && region.center.longitude == 0 ? coordinate : region.center,
                latitudinalMeters: radius * 5.4,
                longitudinalMeters: radius * 5.4
            )

            let focus = CountryMapFocus(
                coordinate: coordinate,
                region: focusRegion,
                cameraDistance: max(radius * 10, 550_000)
            )
            cache[country.code] = focus
            return focus
        } catch {
            codesWithoutAFocus.insert(country.code)
            return nil
        }
    }

    /// Prefers an exact region-identifier match, but falls back to the first result rather than
    /// nothing — a same-country-but-inexact result (common for small states, overseas
    /// territories, or a country whose English display name doesn't map to a single MapKit
    /// result) is still a better outcome than never focusing the map at all.
    private func bestMapItem(
        in mapItems: [MKMapItem],
        for country: CountryMapLookup
    ) -> MKMapItem? {
        let normalizedCode = country.code.uppercased()
        let exactMatch = mapItems.first { mapItem in
            mapItem.addressRepresentations?.region?.identifier.uppercased() == normalizedCode
        }
        return exactMatch ?? mapItems.first
    }
}

extension MKCoordinateRegion {
    static let world = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 22, longitude: 11),
        span: MKCoordinateSpan(latitudeDelta: 120, longitudeDelta: 120)
    )

    var approximateHighlightRadius: CLLocationDistance {
        max(span.latitudeDelta, span.longitudeDelta) * 111_000 / 3
    }
}
