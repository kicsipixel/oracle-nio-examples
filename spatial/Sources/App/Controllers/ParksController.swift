import Foundation
import Hummingbird
import Logging
import OracleNIO

struct ParksController<Context: RequestContext> {
  let client: OracleClient
  let logger: Logger

  func addRoutes(to group: RouterGroup<Context>) {
    group
      .post(use: create)
      .get(use: index)
      .get(":id", use: show)
      .patch(":id", use: update)
      .delete(":id", use: delete)
  }

  // MARK: - create
  /// Creates a new park with `coordinates` and `details`
  @Sendable
  func create(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let park = try await request.decode(as: Park.self, context: context)

    let detailsJSON = OracleJSON(park.details)

    let query: OracleStatement = try "INSERT INTO spatial (coordinates, details) VALUES (SDO_GEOMETRY(\(park.coordinates.latitude), \(park.coordinates.longitude)), \(detailsJSON))"

    _ = try await client.withConnection { conn in
      try await conn.execute(query, logger: logger)
    }

    return .created
  }

  // MARK: - index
  /// Returns with all parks in the database
  /// Using optional Uri parameters to filter parks by distance from a given point
  @Sendable
  func index(_ request: Request, context: Context) async throws -> [Park] {
    var query: OracleStatement?
    var parks = [Park]()

    // Access query parameters
    let queryParams = request.uri.queryParameters

    if let userPosition = queryParams["latlong"], let distance = queryParams["distance"], let unit = queryParams["unit"] {
      // Validate the user position
      let coordinates = userPosition.components(separatedBy: ",")
      guard coordinates.count == 2,
        let latitude = Double(coordinates[0]),
        let longitude = Double(coordinates[1])
      else {
        throw HTTPError(
          .badRequest,
          message: "Invalid position format. Please provide latitude and longitude separated by comma (e.g., latlong=50.14,14.49). Received: '\(userPosition)'"
        )
      }

      // Validate the unit parameter
      guard unit == "km" || unit == "mile" else {
        throw HTTPError(.badRequest, message: "Invalid unit. Must be 'km' or 'mile'")
      }

      let distanceUnitString = "distance=\(distance) unit=\(unit)"

      query = """
        SELECT
          id,
           p.coordinates.SDO_POINT.X AS latitude,
           p.coordinates.SDO_POINT.Y AS longitude,
           p.details
        FROM
          spatial p
        WHERE
         SDO_WITHIN_DISTANCE(coordinates, SDO_GEOMETRY(\(latitude), \(longitude)), \(distanceUnitString)) = 'TRUE'
        """
    }
    else {
      query = """
              SELECT
                id,
                 p.coordinates.SDO_POINT.X AS latitude,
                 p.coordinates.SDO_POINT.Y AS longitude,
                 p.details
              FROM
                spatial p
        """
    }

    guard let query = query else {
      throw HTTPError(.badRequest, message: "Invalid query")
    }

    try await client.withConnection { conn in
      let stream = try await conn.execute(query, logger: logger)
      for try await (id, latitude, longitude, details) in stream.decode((UUID, Float, Float, OracleJSON<Park.Details>).self) {
        parks.append(
          .init(
            id: id,
            coordinates: Park.Coordinates.init(latitude: latitude, longitude: longitude),
            details: Park.Details.init(name: details.value.name, address: details.value.address)
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
           p.details
        FROM
          spatial p
        WHERE id = HEXTORAW(\(guid))
        """
      )

      for try await (id, latitude, longitude, details) in stream.decode((UUID, Float, Float, OracleJSON<Park.Details>).self) {
        return Park(
          id: id,
          coordinates: Park.Coordinates.init(latitude: latitude, longitude: longitude),
          details: Park.Details.init(name: details.value.name, address: details.value.address)
        )
      }

      return nil
    }
  }

  // MARK: - update
  /// Updates a single park with id
  @Sendable
  func update(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")
    let park = try await request.decode(as: Park.self, context: context)
    let detailsJSON = OracleJSON(park.details)

    let query: OracleStatement = try """
    UPDATE spatial
    SET coordinates = SDO_GEOMETRY(\(park.coordinates.latitude), \(park.coordinates.longitude)),
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
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    return try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        DELETE FROM spatial
        WHERE id = HEXTORAW(\(guid))
        """,
        logger: logger
      )
      let deletedRows = try await stream.affectedRows
      if deletedRows == 0 {
        return .notFound
      }
      return .noContent
    }
  }
}
