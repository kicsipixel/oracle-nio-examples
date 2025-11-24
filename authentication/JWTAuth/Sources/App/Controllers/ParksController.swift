import Foundation
import Hummingbird
import HummingbirdAuth
import JWTKit
import Logging
import OracleNIO

struct ParksController {
  let client: OracleClient
  let logger: Logger
  let jwtKeyCollection: JWTKeyCollection
  let kid: JWKIdentifier

  typealias Context = AppRequestContext

  func addRoutes(to group: RouterGroup<Context>) {
    group

      .get(use: index)
      .get(":id", use: show)
      .add(middleware: JWTAuthenticator(jwtKeyCollection: jwtKeyCollection))
      .post(use: create)
      .patch(":id", use: update)
      .delete(":id", use: delete)
  }

  // MARK: - create
  /// Creates a new park with `coordinates` and `details`
  @Sendable
  func create(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let park = try await request.decode(as: NewPark.self, context: context)

    let detailsJSON = OracleJSON(park.details)
    guard let userId = context.identity?.id?.uuidString.replacingOccurrences(of: "-", with: "") else {
      return .unauthorized
    }

    let query: OracleStatement = try "INSERT INTO parks (coordinates, details, user_id) VALUES (SDO_GEOMETRY(\(park.coordinates.latitude), \(park.coordinates.longitude)), \(detailsJSON), \(userId))"

    _ = try await client.withConnection { conn in
      do {
        try await conn.execute(query, logger: logger)
      }
      catch {
        print(String(reflecting: error))
      }
    }

    return .created
  }

  // MARK: - index
  /// Returns with all parks in the database
  @Sendable
  func index(_ request: Request, context: Context) async throws -> [Park] {
    var parks = [Park]()

    try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
           p.coordinates.SDO_POINT.X AS latitude,
           p.coordinates.SDO_POINT.Y AS longitude,
           p.details,
           p.user_id
        FROM
          parks p
        """
      )

      for try await (id, latitude, longitude, details, user_id) in stream.decode((UUID, Float, Float, OracleJSON<Park.Details>, UUID).self) {
        parks.append(
          .init(
            id: id,
            coordinates: Park.Coordinates.init(latitude: latitude, longitude: longitude),
            details: Park.Details.init(name: details.value.name),
            userId: user_id
          )
        )
      }
    }
    return parks
  }

  // MARK: - show
  /// Returns a single park with id
  @Sendable
  func show(_ request: Request, context: Context) async throws -> Park? {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    return try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
           p.coordinates.SDO_POINT.X AS latitude,
           p.coordinates.SDO_POINT.Y AS longitude,
           p.details,
           p.user_id
        FROM
          parks p
        WHERE id = HEXTORAW(\(guid))
        """
      )

      for try await (id, latitude, longitude, details, user_id) in stream.decode((UUID, Float, Float, OracleJSON<Park.Details>, UUID).self) {
        return Park(
          id: id,
          coordinates: Park.Coordinates.init(latitude: latitude, longitude: longitude),
          details: Park.Details.init(name: details.value.name),
          userId: user_id
        )
      }

      return nil
    }
  }

  // MARK: - update
  /// Updates a single park with id
  @Sendable
  func update(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let userInput = try await request.decode(as: UpdatePark.self, context: context)
    // User
    guard let userId = context.identity?.id?.uuidString.replacingOccurrences(of: "-", with: "") else {
      return .badRequest
    }

    // Park
    var originalPark: Park?
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    // Get original park
    _ = try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
           p.coordinates.SDO_POINT.X AS latitude,
           p.coordinates.SDO_POINT.Y AS longitude,
           p.details,
           p.user_id
        FROM
          parks p
        WHERE id = HEXTORAW(\(guid))
        AND user_id = HEXTORAW(\(userId))
        """
      )

      for try await (id, latitude, longitude, details, user_id) in stream.decode((UUID, Float, Float, OracleJSON<Park.Details>, UUID).self) {
        originalPark = Park(
          id: id,
          coordinates: Park.Coordinates.init(
            latitude: latitude,
            longitude: longitude
          ),
          details: Park.Details.init(name: details.value.name),
          userId: user_id
        )
      }
    }

    // Check if the originalPark in the database
    guard let originalPark = originalPark else {
      throw HTTPError(.notFound, message: "Park was not found")
    }

    // Check if there is an update, if not use the original values
    let latitude = userInput.coordinates?.latitude ?? originalPark.coordinates.latitude
    let longitude = userInput.coordinates?.longitude ?? originalPark.coordinates.longitude
    let details = Park.Details(
      name: userInput.details?.name ?? originalPark.details.name
    )

    let detailsJSON = OracleJSON(details)

    let query: OracleStatement = try """
    UPDATE parks
    SET coordinates = SDO_GEOMETRY(\(latitude), \(longitude)),
        details = \(detailsJSON)
    WHERE id = HEXTORAW(\(guid))
    """

    return try await client.withConnection { conn in
      let stream = try await conn.execute(query, logger: logger)
      let updatedRows = try await stream.affectedRows
      if updatedRows == 0 {
        return .notFound
      }
      return .ok
    }
  }

  // MARK: - delete
  /// Deletes park with id
  @Sendable
  func delete(_: Request, context: Context) async throws -> HTTPResponse.Status {
    // User
    guard let userId = context.identity?.id?.uuidString.replacingOccurrences(of: "-", with: "") else {
      return .badRequest
    }

    // Park
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    return try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        DELETE FROM parks
        WHERE id = HEXTORAW(\(guid))
        AND user_id = HEXTORAW(\(userId))
        """,
        logger: logger
      )
      let deletedRows = try await stream.affectedRows
      if deletedRows == 0 {
        throw HTTPError(.badRequest, message: "The park either doesn't exist or you have no persmission to delete it.")
      }
      return .noContent
    }
  }
}
