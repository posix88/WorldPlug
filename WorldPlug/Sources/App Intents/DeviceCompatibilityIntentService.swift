import Foundation
import Repository
import SwiftData

// MARK: - DeviceCompatibilityIntentService

@MainActor
struct DeviceCompatibilityIntentService {
    private let modelContext: ModelContext
    private let homeCountryStore: any HomeCountryStoring

    init(modelContext: ModelContext, homeCountryStore: any HomeCountryStoring) {
        self.modelContext = modelContext
        self.homeCountryStore = homeCountryStore
    }

    func assess(
        deviceName: String,
        inputVoltage: String,
        inputFrequency: String?,
        destinationEntity: CountryEntity
    ) throws -> DeviceCompatibilityResult {
        guard let destination = try country(code: destinationEntity.code) else {
            return DeviceCompatibilityResult(
                recommendation: .destinationUnavailable,
                deviceName: deviceName,
                destinationName: destinationEntity.name,
                destinationVoltage: destinationEntity.voltage,
                destinationFrequency: destinationEntity.frequency,
                destinationPlugTypes: destinationEntity.plugTypes,
                explanation: ""
            )
        }

        let homeCountry = try country(code: homeCountryStore.homeCountryCode)
        let device = PackDevice(
            name: deviceName,
            voltage: inputVoltage,
            frequency: inputFrequency ?? ""
        )
        guard let assessment = TripSafetyChecker.assessments(
            devices: [device],
            homeCountry: homeCountry,
            destination: destination
        ).first else {
            throw DeviceCompatibilityIntentServiceError.missingAssessment
        }

        let recommendation = recommendation(
            for: assessment.status,
            hasInputFrequency: inputFrequency?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        )

        return DeviceCompatibilityResult(
            recommendation: recommendation,
            deviceName: deviceName,
            destinationName: destination.localizedName(in: .current),
            destinationVoltage: destination.voltage,
            destinationFrequency: destination.frequency,
            destinationPlugTypes: destination.sortedPlugs.map(\.id),
            explanation: assessment.message
        )
    }

    private func country(code: String) throws -> Country? {
        let normalizedCode = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !normalizedCode.isEmpty else {
            return nil
        }

        var descriptor = FetchDescriptor<Country>(
            predicate: #Predicate { $0.code == normalizedCode }
        )
        descriptor.fetchLimit = 1
        return try modelContext.fetch(descriptor).first
    }

    private func recommendation(
        for status: DeviceSafetyStatus,
        hasInputFrequency: Bool
    ) -> DeviceCompatibilityRecommendation {
        switch status {
        case .ready:
            guard hasInputFrequency else {
                return .frequencyRequired
            }

            return .ready

        case .adapterNeeded:
            return hasInputFrequency ? .adapterNeeded : .frequencyRequired

        case .homeCountryRequired:
            return hasInputFrequency ? .homeCountryRequired : .frequencyRequired

        case .checkLabel:
            return .checkLabel

        case .unsafe:
            return .unsafe
        }
    }

    private enum DeviceCompatibilityIntentServiceError: Error {
        case missingAssessment
    }
}
