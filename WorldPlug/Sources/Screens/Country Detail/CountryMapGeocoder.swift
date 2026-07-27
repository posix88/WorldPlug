//
//  CountryMapGeocoder.swift
//  WorldPlug
//
//  Created by Antonino.Musolino on 13/07/2026.
//

import CoreLocation
import MapKit

struct CountryMapLookup: Sendable {
    let code: String
}

// MARK: - CountryMapFocus

struct CountryMapFocus {
    let coordinate: CLLocationCoordinate2D
    let region: MKCoordinateRegion
    let cameraDistance: CLLocationDistance
}

actor CountryMapGeocoder {
    static let shared = CountryMapGeocoder()

    private var cache: [String: CountryMapFocus] = [:]

    func focus(for country: CountryMapLookup) async -> CountryMapFocus? {
        if let cached = cache[country.code] {
            return cached
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = Locale(identifier: "en_US").localizedString(forRegionCode: country.code)
        request.region = .world
        request.resultTypes = [.address]

        do {
            let response = try await MKLocalSearch(request: request).start()
            guard let mapItem = bestMapItem(in: response.mapItems, for: country) else {
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
            return nil
        }
    }

    private func bestMapItem(
        in mapItems: [MKMapItem],
        for country: CountryMapLookup
    ) -> MKMapItem? {
        let normalizedCode = country.code.uppercased()
        return mapItems.first { mapItem in
            mapItem.addressRepresentations?.region?.identifier.uppercased() == normalizedCode
        }
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
