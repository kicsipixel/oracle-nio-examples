import Foundation
import Hummingbird
import Logging
import OracleNIO

struct ParksController<Context: RequestContext> {
    let client: OracleClient
    let logger: Logger

    func addRoutes(to group: RouterGroup<Context>) {
        group
            .get(use: index)
            .get("/distance", use: filter)
    }

    // MARK: - index

    /// list all parks in the database
    /// Usage: 'curl http://localhost:8080/api/v1/parks/'
    @Sendable
    func index(_: Request, context _: Context) async throws -> [Park] {
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
                                latitude: latitude,
                                longitude: longitude)
                parks.append(park)
            }
        }
        return parks
    }

    // MARK: - filter

    /// Search all parks withint the given distance
    /// Usage: 'curl http://localhost:8080/api/v1/parks/distance?mile=1'
    @Sendable
    func filter(_ request: Request, context _: Context) async throws -> [Park] {
        var parks = [Park]()
        var unit = ""
        var distance = 0
        let distanceKm = request.uri.queryParameters.get("km")
        let distanceMile = request.uri.queryParameters.get("mile")

        guard let _ = distanceKm ?? distanceMile else {
            throw HTTPError(.badRequest)
        }

        if let km = distanceKm {
            unit = "KM"
            distance = Int(km) ?? 0
        } else if let mile = distanceMile {
            unit = "MILE"
            distance = Int(mile) ?? 0
        }

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
                                latitude: latitude,
                                longitude: longitude)
                parks.append(park)
            }
        }
        return parks
    }
}
