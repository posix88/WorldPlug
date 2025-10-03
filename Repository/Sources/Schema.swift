@preconcurrency import SwiftData

// MARK: - SchemaV4

public enum SchemaV4: VersionedSchema {
    public static let versionIdentifier = Schema.Version(4, 0, 0)
    public static let models: [any PersistentModel.Type] = [Country.self, Plug.self]
}

// MARK: - MigrationPlan

enum MigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV4.self]
    }

//    static var migrateV2toV3: MigrationStage {
//        .custom(fromVersion: SchemaV3.self, toVersion: SchemaV4.self) { context in
//            let t = try! context.fetch(FetchDescriptor<SchemaV3.Country>())
//            let b = try! context.fetch(FetchDescriptor<SchemaV3.Plug>())
//            for c in t {
//                context.delete(c)
//            }
//            for a in b {
//                context.delete(a)
//            }
//            try? context.save()
//        } didMigrate: {_ in}
//    }

    static var stages: [MigrationStage] {
        []
    }
}
