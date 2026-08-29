import AppIntents
import Foundation
import Repository
import SwiftData

// MARK: - PlugEntity

struct PlugEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource(
            "intent.plug.entity.type",
            defaultValue: "Plug"
        )
    )
    static let defaultQuery = PlugEntityQuery()

    let id: String
    @Property(
        title: LocalizedStringResource(
            "intent.plug.property.type",
            defaultValue: "Plug type"
        )
    )
    var type: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(LocalizationKeys.plugTypePrefix.localized(type))",
            image: .init(systemName: "powerplug.fill")
        )
    }

    @MainActor
    init(plug: Plug) {
        self.id = plug.id
        self.type = plug.id
    }
}

// MARK: - PlugEntityQuery

struct PlugEntityQuery: EntityStringQuery {
    func entities(for identifiers: [PlugEntity.ID]) async throws -> [PlugEntity] {
        let identifiers = Set(identifiers.map { $0.uppercased() })
        return await plugEntities { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [PlugEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return try await suggestedEntities()
        }

        return await plugEntities {
            $0.id.localizedCaseInsensitiveContains(query)
        }
    }

    func suggestedEntities() async throws -> [PlugEntity] {
        await plugEntities { _ in true }
    }

    @MainActor
    private func plugEntities(matching predicate: (Plug) -> Bool) -> [PlugEntity] {
        let descriptor = FetchDescriptor<Plug>(sortBy: [SortDescriptor(\.id)])
        let plugs = (try? Repository.sharedModelContainer.mainContext.fetch(descriptor)) ?? []
        return plugs.filter(predicate).map(PlugEntity.init)
    }
}

// MARK: - TripCheckEntity

struct TripCheckEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource(
            "intent.trip.check.entity.type",
            defaultValue: "Trip Check"
        )
    )
    static let defaultQuery = TripCheckEntityQuery()

    let id: UUID
    @Property(title: LocalizedStringResource("next.trip.name", defaultValue: "Trip name"))
    var name: String
    @Property(title: LocalizedStringResource("next.trip.destination", defaultValue: "Destination"))
    var destinationCode: String
    @Property(title: LocalizedStringResource("next.trip.departure", defaultValue: "Departure"))
    var departureDate: Date
    @Property(title: LocalizedStringResource("next.trip.return.date", defaultValue: "Return date"))
    var returnDate: Date
    @Property(title: LocalizedStringResource("trip.check.devices", defaultValue: "Devices"))
    var deviceCount: Int

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(destinationCode) · \(departureDate.formatted(date: .abbreviated, time: .omitted))",
            image: .init(systemName: "suitcase.rolling.fill")
        )
    }

    init(tripCheck: TripCheck) {
        self.id = tripCheck.id
        self.name = tripCheck.name?.nilIfBlank ?? tripCheck.countryCode
        self.destinationCode = tripCheck.countryCode
        self.departureDate = tripCheck.departureDate
        self.returnDate = tripCheck.returnDate
        self.deviceCount = tripCheck.devices.count
    }
}

// MARK: - TripCheckEntityQuery

struct TripCheckEntityQuery: EntityStringQuery {
    private let preferencesProvider: @MainActor @Sendable () -> TravelPreferences

    init() {
        self.preferencesProvider = {
            ICloudTravelPreferencesStore.readPreferencesSnapshot()
        }
    }

    init(preferencesProvider: @escaping @MainActor @Sendable () -> TravelPreferences) {
        self.preferencesProvider = preferencesProvider
    }

    func entities(for identifiers: [TripCheckEntity.ID]) async throws -> [TripCheckEntity] {
        let identifiers = Set(identifiers)
        return await tripCheckEntities { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [TripCheckEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return try await suggestedEntities()
        }

        return await tripCheckEntities {
            $0.name?.localizedCaseInsensitiveContains(query) == true ||
                $0.countryCode.localizedCaseInsensitiveContains(query)
        }
    }

    func suggestedEntities() async throws -> [TripCheckEntity] {
        await tripCheckEntities { _ in true }
    }

    @MainActor
    private func tripCheckEntities(matching predicate: (TripCheck) -> Bool) -> [TripCheckEntity] {
        preferencesProvider().tripChecks
            .filter(predicate)
            .sorted { $0.departureDate > $1.departureDate }
            .map(TripCheckEntity.init)
    }
}

// MARK: - PackDeviceEntity

struct PackDeviceEntity: AppEntity {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(
        name: LocalizedStringResource(
            "intent.device.entity.type",
            defaultValue: "Device"
        )
    )
    static let defaultQuery = PackDeviceEntityQuery()

    let id: UUID
    @Property(title: LocalizedStringResource("trip.check.device.name", defaultValue: "Device name"))
    var name: String
    @Property(title: LocalizedStringResource("trip.check.device.voltage", defaultValue: "Input voltage"))
    var voltage: String
    @Property(title: LocalizedStringResource("trip.check.device.frequency", defaultValue: "Frequency"))
    var frequency: String
    var symbolName: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: "\(electricalSummary)",
            image: .init(systemName: symbolName)
        )
    }

    init(device: PackDevice) {
        self.id = device.id
        self.symbolName = device.symbolName
        self.name = device.name
        self.voltage = device.voltage
        self.frequency = device.frequency
    }

    private var electricalSummary: String {
        [voltage, frequency]
            .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .joined(separator: " · ")
    }
}

// MARK: - PackDeviceEntityQuery

struct PackDeviceEntityQuery: EntityStringQuery {
    private let preferencesProvider: @MainActor @Sendable () -> TravelPreferences

    init() {
        self.preferencesProvider = {
            ICloudTravelPreferencesStore.readPreferencesSnapshot()
        }
    }

    init(preferencesProvider: @escaping @MainActor @Sendable () -> TravelPreferences) {
        self.preferencesProvider = preferencesProvider
    }

    func entities(for identifiers: [PackDeviceEntity.ID]) async throws -> [PackDeviceEntity] {
        let identifiers = Set(identifiers)
        return await deviceEntities { identifiers.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [PackDeviceEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return try await suggestedEntities()
        }

        return await deviceEntities {
            $0.name.localizedCaseInsensitiveContains(query)
        }
    }

    func suggestedEntities() async throws -> [PackDeviceEntity] {
        await deviceEntities { _ in true }
    }

    @MainActor
    private func deviceEntities(matching predicate: (PackDevice) -> Bool) -> [PackDeviceEntity] {
        preferencesProvider().tripChecks
            .flatMap(\.devices)
            .filter(predicate)
            .map(PackDeviceEntity.init)
    }
}

private extension String {
    var nilIfBlank: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
