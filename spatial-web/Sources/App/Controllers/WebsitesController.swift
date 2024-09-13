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

struct WebsitesController {
    let mustacheLibrary: MustacheLibrary
    let client: OracleClient
    let logger: Logger

    func addRoutes(to router: Router<some RequestContext>) {
        router.get("/", use: index)
        router.post("/", use: indexPost)
        router.get("filter/:distance", use: filter)
    }

    @Sendable
    func index(request _: Request, context _: some RequestContext) async throws -> HTML {
        var parks = [Park]()
        try await client.withConnection { conn in
            let rows = try await conn.execute(
                """
                    SELECT
                        p.id,
                        p.name,
                        p.address,
                        p.geometry.SDO_POINT.X AS longitude,
                        p.geometry.SDO_POINT.Y AS latitude
                    FROM
                        spatialparks p
                """)

            for try await (id, name, address, latitude, longitude) in rows
                .decode((UUID, String, String, Double, Double).self)
            {
                let park = Park(id: id,
                                name: name,
                                address: address,
                                coordinates: Park.Coordinates(latitude: latitude,
                                                              longitude: longitude))
                parks.append(park)
            }
        }

        let context = IndexContext(parks: parks, location: getCoordinates("Karlův most")!)
        guard let html = mustacheLibrary.render(context, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }
        return HTML(html: html)
    }

    @Sendable
    func indexPost(request: Request, context: some RequestContext) async throws -> HTML {
        let data = try await request.decode(as: FormData.self, context: context)

        var parks = [Park]()

        guard let coordinates = getCoordinates(data.location) else {
            throw HTTPError(.badRequest)
        }

        let distanceUnitString = "distance=\(data.distance) unit=\(data.unit)"

        try await client.withConnection { conn in
            let query =
                """
                    SELECT
                      p.id,
                      p.name,
                      p.address,
                      p.geometry.SDO_POINT.X AS longitude,
                      p.geometry.SDO_POINT.Y AS latitude
                    FROM
                      spatialparks p
                    WHERE
                      SDO_WITHIN_DISTANCE(
                        geometry,
                        SDO_GEOMETRY(\(coordinates.latitude), \(coordinates.longitude)),
                        '\(distanceUnitString)'
                      ) = 'TRUE'
                """

            let rows = try await conn.execute(OracleStatement(stringLiteral: query))

            for try await (id, name, address, latitude, longitude) in rows
                .decode((UUID, String, String, Double, Double).self)
            {
                let park = Park(id: id,
                                name: name,
                                address: address,
                                coordinates: Park.Coordinates(latitude: latitude,
                                                              longitude: longitude))
                parks.append(park)
            }
        }

        let context = IndexContext(parks: parks, location: getCoordinates(data.location)!)
        guard let html = mustacheLibrary.render(context, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }
        return HTML(html: html)
    }

    @Sendable
    func filter(request _: Request, context: some RequestContext) async throws -> HTML {
        let queryString = try context.parameters.require("distance", as: String.self)

        // Variables
        var parks = [Park]()
        var parameters: [String: Any] = [:]

        let pairs = queryString.split(separator: "&")
        for pair in pairs {
            let keyValue = pair.split(separator: "=")
            if keyValue.count == 2 {
                let key = String(keyValue[0])
                let value = String(keyValue[1])
                parameters[key] = value
            } else {
                throw HTTPError(.badRequest)
            }
        }

        guard let distance = parameters["distance"],
              let unit = parameters["unit"] else { throw HTTPError(.badRequest) }

        try await client.withConnection { conn in
            let distanceUnitString = "distance=\(distance) unit=\(unit)"
            let query =
                """
                    SELECT
                      p.id,
                      p.name,
                      p.address,
                      p.geometry.SDO_POINT.X AS longitude,
                      p.geometry.SDO_POINT.Y AS latitude
                    FROM
                      spatialparks p
                    WHERE
                      SDO_WITHIN_DISTANCE(
                        geometry,
                        SDO_GEOMETRY(50.086389, 14.411944),
                        '\(distanceUnitString)'
                      ) = 'TRUE'
                """

            let rows = try await conn.execute(OracleStatement(stringLiteral: query))

            for try await (id, name, address, latitude, longitude) in rows
                .decode((UUID, String, String, Double, Double).self)
            {
                let park = Park(id: id,
                                name: name,
                                address: address,
                                coordinates: Park.Coordinates(latitude: latitude,
                                                              longitude: longitude))
                parks.append(park)
            }
        }

        let context = IndexContext(parks: parks, location: getCoordinates("Karlův most")!)
        guard let html = mustacheLibrary.render(context, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }
        return HTML(html: html)
    }
}

struct IndexContext {
    let parks: [Park]
    let location: Park.Coordinates
}

struct FormData: Codable {
    let location: String
    let distance: String
    let unit: Unit

    enum Unit: String, Codable {
        case km
        case mile
    }
}

func getCoordinates(_ location: String) -> Park.Coordinates? {
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
