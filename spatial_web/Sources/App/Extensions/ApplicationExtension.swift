import Foundation
import Hummingbird
import Logging
import OracleNIO

/// Extension to seed the database with inital values form Resources directory
/// The `filename` and `fileURLWithPath` are hard coded. 🤦
/// The `decoder` uses ``Seed`` model
extension Application {
  func seedDatabase(_ app: any ApplicationProtocol, config: OracleConnection.Configuration) async throws {

    guard let source = Bundle.module.url(forResource: "parksofprague", withExtension: "json") else {
      throw HTTPError(.notFound, message: "File not found.")
    }

    let data = try Data(contentsOf: source)
    let parks = try JSONDecoder().decode(Seed.self, from: data)

    let connection = try await OracleConnection.connect(
      configuration: config,
      id: 1,
      logger: logger
    )

    for park in parks {
      let details = OracleJSON(Park.Details(name: park.properties.name, address: park.properties.address.addressFormatted))
      /// Generate new UUID for each park
      let guid = UUID().generateSysGuid()

      do {
        try await connection.execute(
          """
          INSERT INTO spatial (
              id,
              coordinates,
              details
              )
          VALUES (
              \(guid),
              SDO_GEOMETRY(\(park.geometry.coordinates[1]), \(park.geometry.coordinates[0])),
              \(details)
          )
          """,
          logger: logger
        )
      }
      catch {
        print(String(reflecting: error))
      }
    }

    try await connection.close()
  }
}
