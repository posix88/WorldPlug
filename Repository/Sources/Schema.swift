import SwiftData

public enum SchemaV2: VersionedSchema {
    public static let versionIdentifier = Schema.Version(2, 0, 0)
    public static let models: [any PersistentModel.Type] = [Country.self, Plug.self]
}


enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
