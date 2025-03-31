import Foundation
import Hummingbird
import Logging
import Mustache
import OracleNIO

struct HTML: ResponseGenerator {
  let html: String

  func response(from _: Request, context _: some RequestContext) throws -> Response {
    let buffer = ByteBuffer(string: html)
    return .init(status: .ok, headers: [.contentType: "text/html"], body: .init(byteBuffer: buffer))
  }
}

struct WebpagesController {
  let mustacheLibrary: MustacheLibrary
  let client: OracleClient
  let logger: Logger

  func addRoutes(to router: Router<some RequestContext>) {
    router
      .get("/", use: index)
      .post("/", use: indexPost)
  }

  // MARK: - index
  /// Renders the index page with a list of parks.
  @Sendable
  func index(request _: Request, context _: some RequestContext) async throws -> HTML {
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
          spatial p
        """
      )

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

    let context = IndexContext(
      parks: parks,
      location: getCoordinates("Karlův most") ?? Park.Coordinates(latitude: 50.086389, longitude: 14.411944)
    )
    guard let html = mustacheLibrary.render(context, withTemplate: "index") else {
      throw HTTPError(.internalServerError, message: "Failed to render template.")
    }
    return HTML(html: html)
  }

  // MARK: - indexPost
  /// Handles the form submission from the index page.
  @Sendable
  func indexPost(request: Request, context: some RequestContext) async throws -> HTML {
    let data = try await request.decode(as: FormData.self, context: context)

    var parks = [Park]()

    guard let coordinates = getCoordinates(data.location) else {
      throw HTTPError(.badRequest)
    }

    let distanceUnitString = "distance=\(data.distance) unit=\(data.unit)"

    try await client.withConnection { conn in
      let query: OracleStatement =
        """
        SELECT
          id,
           p.coordinates.SDO_POINT.X AS latitude,
           p.coordinates.SDO_POINT.Y AS longitude,
           p.details
        FROM
          spatial p
        WHERE
         SDO_WITHIN_DISTANCE(coordinates, SDO_GEOMETRY(\(coordinates.latitude), \(coordinates.longitude)), \(distanceUnitString)) = 'TRUE'
        """

      let stream = try await conn.execute(query)
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

    let context = IndexContext(
      parks: parks,
      location: getCoordinates(data.location) ?? Park.Coordinates(latitude: 50.086389, longitude: 14.411944)
    )
    guard let html = mustacheLibrary.render(context, withTemplate: "index") else {
      throw HTTPError(.internalServerError, message: "Failed to render template.")
    }
    return HTML(html: html)
  }

  // MARK: - Helper functions
  /// Converts drop down menu selection to coordinates
  private func getCoordinates(_ location: String) -> Park.Coordinates? {
    switch location {
    case "Karlův most":
      return Park.Coordinates(latitude: 50.086389, longitude: 14.411944)
    case "Staroměstská":
      return Park.Coordinates(latitude: 50.08822, longitude: 14.41763)
    case "Náměstí Míru":
      return Park.Coordinates(latitude: 50.07533, longitude: 14.43769)
    case "Anděl":
      return Park.Coordinates(latitude: 50.0705, longitude: 14.4003)
    default:
      return nil
    }
  }
}

// MARK: - IndexContext
struct IndexContext {
  let parks: [Park]
  let location: Park.Coordinates
}
