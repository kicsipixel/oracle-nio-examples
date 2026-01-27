import Foundation
import Hummingbird
import HummingbirdElementary
import Logging
import OracleNIO

struct PagesController<Context: RequestContext> {
  let client: OracleClient
  let logger: Logger

  func addRoutes(to group: RouterGroup<Context>) {
    group
      .get("/parks/create", use: create)
      .post("/parks/create", use: createPost)
      .get("/", use: index)
      .get("/parks/:id", use: show)
      .get("/parks/:id/edit", use: edit)
      .post("/parks/:id/edit", use: editPost)
      .get("/parks/:id/delete", use: delete)
  }

  // MARK: - create
  /// Creates a new park with `coordinates` and `details`
  /// Presents the form to create a new park
  @Sendable
  func create(request: Request, context: Context) async throws -> HTMLResponse {
    HTMLResponse {
      MainLayout(title: "Parks of Prague") {
        CreatePage()
      }
    }
  }

  /// Store the new park in the database
  @Sendable
  func createPost(_ request: Request, context: Context) async throws -> Response {
    let park = try await request.decode(as: CreateParkForm.self, context: context)

    let details = Park.Details(name: park.name)
    let detailsJSON = OracleJSON(details)

    let query: OracleStatement = try "INSERT INTO parks (coordinates, details) VALUES (SDO_GEOMETRY(\(park.latitude), \(park.longitude)), \(detailsJSON))"

    _ = try await client.withConnection { conn in
      try await conn.execute(query, logger: logger)
    }

    return Response(status: .seeOther, headers: [.location: "/"])
  }

  // MARK: - index
  /// Returns with all parks in the database
  @Sendable
  func index(request: Request, context: some RequestContext) async throws -> HTMLResponse {
    var parks = [Park]()

    try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
           p.coordinates.SDO_POINT.X AS latitude,
           p.coordinates.SDO_POINT.Y AS longitude,
           p.details
        FROM
          parks p
        """
      )

      for try await (id, latitude, longitude, details) in stream.decode((UUID, Float, Float, OracleJSON<Park.Details>).self) {
        parks.append(
          .init(
            id: id,
            coordinates: Park.Coordinates.init(latitude: latitude, longitude: longitude),
            details: Park.Details.init(name: details.value.name)
          )
        )
      }
    }

    return HTMLResponse {
      MainLayout(title: "Parks of Prague") {
        IndexPage(parks: parks)
      }
    }
  }

  // MARK: - show
  /// Returns with a park by its id
  @Sendable
  func show(request: Request, context: some RequestContext) async throws -> HTMLResponse {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")
    var park: Park?

    try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
           p.coordinates.SDO_POINT.X AS latitude,
           p.coordinates.SDO_POINT.Y AS longitude,
           p.details
        FROM
          parks p
        WHERE id = HEXTORAW(\(guid))
        """
      )

      for try await (id, latitude, longitude, details) in stream.decode((UUID, Float, Float, OracleJSON<Park.Details>).self) {
        park = Park(
          id: id,
          coordinates: Park.Coordinates.init(latitude: latitude, longitude: longitude),
          details: Park.Details.init(name: details.value.name)
        )
      }
    }

    guard let park = park else {
      throw HTTPError(.notFound)
    }

    return HTMLResponse {
      MainLayout(title: "Parks of Prague") {
        ShowPage(park: park)
      }
    }
  }

  // MARK: - update
  /// Updates a single park with id
  @Sendable
  func edit(request: Request, context: some RequestContext) async throws -> HTMLResponse {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")
    var park: Park?

    try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
           p.coordinates.SDO_POINT.X AS latitude,
           p.coordinates.SDO_POINT.Y AS longitude,
           p.details
        FROM
          parks p
        WHERE id = HEXTORAW(\(guid))
        """
      )

      for try await (id, latitude, longitude, details) in stream.decode((UUID, Float, Float, OracleJSON<Park.Details>).self) {
        park = Park(
          id: id,
          coordinates: Park.Coordinates.init(latitude: latitude, longitude: longitude),
          details: Park.Details.init(name: details.value.name)
        )
      }
    }

    guard let park = park else {
      throw HTTPError(.notFound)
    }

    return HTMLResponse {
      MainLayout(title: "Parks of Prague") {
        CreatePage(isEditing: true, park: park)
      }
    }
  }

  /// Updates new park in the database
  @Sendable
  func editPost(_ request: Request, context: Context) async throws -> Response {
    let park = try await request.decode(as: CreateParkForm.self, context: context)
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")
    let details = Park.Details(name: park.name)
    let detailsJSON = OracleJSON(details)

    let query: OracleStatement = try """
    UPDATE parks
    SET coordinates = SDO_GEOMETRY(\(park.latitude), \(park.longitude)),
        details = \(detailsJSON)
    WHERE id = HEXTORAW(\(guid))
    """

    _ = try await client.withConnection { conn in
      try await conn.execute(query, logger: logger)
    }

    return Response(status: .seeOther, headers: [.location: "/"])
  }

  // MARK: - delete
  /// Deletes park with id
  @Sendable
  func delete(_: Request, context: Context) async throws -> Response {
    let id = try context.parameters.require("id", as: String.self)
    let guid = id.replacingOccurrences(of: "-", with: "")

    return try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        DELETE FROM parks
        WHERE id = HEXTORAW(\(guid))
        """,
        logger: logger
      )
      let deletedRows = try await stream.affectedRows
      if deletedRows == 0 {
        throw HTTPError(.notFound)
      }
      return Response(status: .seeOther, headers: [.location: "/"])
    }
  }
}
