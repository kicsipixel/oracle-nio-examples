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
        router.get("filter/:distance", use: filter)
    }

    @Sendable
    func index(request _: Request, context _: some RequestContext) async throws -> HTML {
        var parks = [ParkContext]()
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
                let park = ParkContext(id: id,
                                       name: name,
                                       address: address,
                                       latitude: latitude,
                                       longitude: longitude)
                parks.append(park)
            }
        }

        let context = IndexContext(park: parks)
        guard let html = mustacheLibrary.render(context, withTemplate: "index") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }
        return HTML(html: html)
    }

    @Sendable
    func filter(request _: Request, context: some RequestContext) async throws -> HTML {
        let queryString = try context.parameters.require("distance", as: String.self)

        // Variables
        var parks = [ParkContext]()
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
                let park = ParkContext(id: id,
                                       name: name,
                                       address: address,
                                       latitude: latitude,
                                       longitude: longitude)
                parks.append(park)
            }
        }

        print(parks.count)

        let context = IndexContext(park: parks)
        guard let html = mustacheLibrary.render(context, withTemplate: "filter") else {
            throw HTTPError(.internalServerError, message: "Failed to render template.")
        }
        return HTML(html: html)
    }
}

struct IndexContext {
    let park: [ParkContext]
}

struct ParkContext {
    let id: UUID?
    let name: String
    let address: String
    let latitude: Double
    let longitude: Double
}
