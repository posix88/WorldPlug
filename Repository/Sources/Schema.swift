@preconcurrency import SwiftData

// MARK: - SchemaV2

public enum SchemaV2: VersionedSchema {
    public static let versionIdentifier = Schema.Version(2, 0, 0)
    public static let models: [any PersistentModel.Type] = [Country.self, Plug.self]
}

// MARK: - MigrationPlan

// public enum SchemaV3: VersionedSchema {
//    public static let versionIdentifier = Schema.Version(3, 0, 0)
//    public static let models: [any PersistentModel.Type] = [Country.self, Plug.self]
// }

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV2.self]
    }

//    static var migrateV2toV3: MigrationStage {
//        .custom(fromVersion: SchemaV2.self, toVersion: SchemaV3.self) { context in
//           let t = try! context.fetch(FetchDescriptor<Country>())
//           let b = try! context.fetch(FetchDescriptor<Plug>())
//            for c in t {
//                context.delete(c)
//            }
//            for a in b {
//                context.delete(a)
//            }
//
//        } didMigrate: {_ in}
//    }

    static var stages: [MigrationStage] {
        []
    }
}
