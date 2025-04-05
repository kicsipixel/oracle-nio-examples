import Foundation
import Hummingbird
import Logging
import OracleNIO

struct PeopleController<Context: RequestContext> {
  let client: OracleClient
  let logger: Logger

  func addRoutes(to group: RouterGroup<Context>) {
    group
      .post(use: create)
      .get(use: index)
      .get(":id", use: show)
      .put(":id", use: edit)
      .delete(":id", use: delete)
  }

  // MARK: - create
  /// Creates a new person in the database
  @Sendable
  func create(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let person = try await request.decode(as: Person.self, context: context)

    let peopleJSON = OracleJSON(person.details)

    _ = try await client.withConnection { conn in
      try await conn.execute(
        """
          INSERT INTO people (people_list)
          VALUES (\(peopleJSON))
        """
      )
    }
    return .created
  }
  // MARK: - index
  /// Lists all the people in the database
  /// Using optional Uri parameters to filter the results `/api/users?nat=DE&hobbies=reading`
  @Sendable
  func index(_ request: Request, context _: Context) async throws -> [Person] {
    var query: OracleStatement?
    var people = [Person]()

    // Access query parameters
    let queryParams = request.uri.queryParameters

    // Check if the query parameter is present
    if let nationality = queryParams["nat"], let hobbies = queryParams["hobbies"] {
      query = """
        SELECT
            id,
            people_list
        FROM
            people
        WHERE
            JSON_EXISTS ( people_list, '$[0].hobbies[*]?(@ == $V1)' PASSING \((String(hobbies))) AS "V1")
            AND JSON_VALUE(people_list, '$.nationality') = \(String(nationality))
        """
    }
    else if let nationality = queryParams["nat"] {
      query = """
        SELECT
            id,
            people_list
        FROM
            people
        WHERE
            JSON_VALUE(people_list, '$.nationality') = \(String(nationality))
        """
    }
    else if let hobbies = queryParams["hobbies"] {
      query = """
        SELECT
            id,
            people_list
        FROM
            people
        WHERE
            JSON_EXISTS ( people_list, '$[0].hobbies[*]?(@ == $V1)' PASSING \((String(hobbies))) AS "V1")
        """
    }
    else {
      query = """
        SELECT id, people_list from people
        """
    }

    guard let query = query else {
      throw HTTPError(.badRequest, message: "Invalid query parameters")
    }

    try await client.withConnection { conn in
      let stream = try await conn.execute(query, logger: logger)

      for try await (id, people_list) in stream.decode((UUID, OracleJSON<Person.Details>).self) {
        people.append(
          Person(
            id: id,
            details: people_list.value
          )
        )
      }
    }
    return people
  }

  // MARK: - show
  /// Returns a single person with id
  @Sendable
  func show(_: Request, context: Context) async throws -> Person? {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    return try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
          SELECT
              id,
              people_list
          FROM
              people
          WHERE id = HEXTORAW(\(guid))
        """
      )

      for try await (id, people_list) in stream.decode((UUID, OracleJSON<Person.Details>).self) {
        return Person(
          id: id,
          details: people_list.value
        )
      }
      return nil
    }
  }

  // MARK: - edit
  /// Updates a person with id
  @Sendable
  func edit(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    let person = try await request.decode(as: Person.self, context: context)

    let peopleJSON = OracleJSON(person.details)

    _ = try await client.withConnection { conn in
      try await conn.execute(
        """
          UPDATE people
          SET people_list = \(peopleJSON)
          WHERE id = HEXTORAW(\(guid))
        """
      )
    }
    return .ok
  }

  // MARK: - delete
  /// Deletes a person with id
  @Sendable
  func delete(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    _ = try await client.withConnection { conn in
      try await conn.execute(
        """
          DELETE FROM people
          WHERE id = HEXTORAW(\(guid))
        """
      )
    }
    return .noContent
  }
}
