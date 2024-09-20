import Foundation
import Hummingbird
import Logging
import OracleNIO

/// Extension to seed the database with inital values form Public directory
/// The `forResource` as file name and `withExtension` as file extension are hard coded. 🤦
/// The `decoder` uses `Seed` model
extension Application {
    func seedDatabase(_: any ApplicationProtocol, config: OracleConnection.Configuration) async throws {
        guard let source = Bundle.module.url(forResource: "people", withExtension: "json") else {
            throw HTTPError(.notFound, message: "File not found.")
        }

        let data = try Data(contentsOf: source)
        let people = try JSONDecoder().decode(Seed.self, from: data)

        let connection = try await OracleConnection.connect(
            configuration: config,
            id: 1,
            logger: logger)

        for person in people {
            let id = UUID().generateSysGuid()

            let query =
                """
                INSERT INTO people(id, people_list) VALUES('\(id)', '{
                "name" : {
                "title": "\(person.name.title)",
                "first": "\(person.name.firstName)",
                "last": "\(person.name.lastName)"
                }, "email": "\(person.email)", "nat": "\(person.nationality)", "hobbies": \(person.hobbies)
                }')
                """

            try await connection.execute(OracleStatement(stringLiteral: query))
        }
        try await connection.close()
    }
}
