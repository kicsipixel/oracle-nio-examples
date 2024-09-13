import Foundation
import Hummingbird
import Logging
import OracleNIO

/// Extension to seed the database with inital values form Public directory
/// The `filename` and `fileURLWithPath` are hard coded. 🤦
/// The `decoder` uses `Seed` model
extension Application {
    func seedDatabase(_ app: any ApplicationProtocol, config: OracleConnection.Configuration) async throws {
        let publicDirectory = app.directory.publicDirectory

        let data = try Data(contentsOf: URL(fileURLWithPath: publicDirectory)
            .appendingPathComponent("parksofprague.json", isDirectory: false))
        let features = try JSONDecoder().decode(Seed.self, from: data)

        let connection = try await OracleConnection.connect(
            configuration: config,
            id: 1,
            logger: logger)

        for feature in features {
            let id = UUID().generateSysGuid()

            try await connection.execute(
                """
                INSERT INTO spatialparks (
                    id
                    ,name
                    ,address
                    ,geometry
                    )
                VALUES (
                    \(id)
                    ,\(feature.properties.name)
                    ,\(feature.properties.address.addressFormatted)
                    ,SDO_GEOMETRY(\(feature.geometry.coordinates[1]), \(feature.geometry.coordinates[0]))
                )
                """,
                logger: logger)
        }
        try await connection.close()
    }
}
