import Foundation
import Hummingbird
import Logging
import OracleNIO

/// Extension to seed the database with inital values form Resources directory
/// The `filename` and `fileURLWithPath` are hard coded. 🤦
/// The `decoder` uses ``Seed`` model
extension Application {
  func seedDatabase(_ app: any ApplicationProtocol, config: OracleConnection.Configuration) async throws {

    guard let source = Bundle.module.url(forResource: "people", withExtension: "json") else {
      throw HTTPError(.notFound, message: "File not found.")
    }

    let data = try Data(contentsOf: source)
    let people = try JSONDecoder().decode(Seed.self, from: data)

    let connection = try await OracleConnection.connect(
      configuration: config,
      id: 1,
      logger: logger
    )

    for person in people {
      /// Generate new UUID for each person
      let guid = UUID().generateSysGuid()

      let personJSON = OracleJSON(
        Person.Details(
          name: .init(title: person.name.title, firstName: person.name.firstName, lastName: person.name.lastName),
          email: person.email,
          nationality: person.nationality,
          hobbies: person.hobbies
        )
      )

      do {
        try await connection.execute(
          """
          INSERT INTO people (id, people_list) VALUES (\(guid), \(personJSON))
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
