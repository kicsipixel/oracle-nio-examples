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
            .post("filter", use: filter)
    }

    // MARK: - create

    /// Creates a new park with a `name`, `address` and `coordinates`
    /// Usage: curl -X "POST" "http://localhost:8080/api/v1/parks" \
    ///              -H 'Content-Type: application/json' \
    ///              -d $'{
    ///                     "name": "Test Park",
    ///                     "address": "Test 17800 Praha Czech Republic",
    ///                     "coordinates": {
    ///                       "latitde": 50.50,
    ///                       "longitude": "14.14"
    ///                     }
    ///         }'
    @Sendable
    func create(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let park = try await request.decode(as: Park.self, context: context)

        _ = try await client.withConnection { conn in
            try await conn.execute(
                """
                INSERT INTO spatialparks (
                    name
                    ,address
                    ,geometry
                    )
                VALUES (
                    \(park.name)
                    ,\(park.address)
                    ,SDO_GEOMETRY(\(park.coordinates.latitude), \(park.coordinates.longitude))
                )
                """,
                logger: logger)
        }
        return .created
    }

    // MARK: - index

    /// List all parks in the database
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
                                coordinates: Park.Coordinates(latitude: latitude,
                                                              longitude: longitude))
                parks.append(park)
            }
        }
        return parks
    }

    // MARK: - show

    /// Returns a single park with id
    /// Usage: `curl "http://localhost:8080/api/v1/parks/2179C563-F93E-2F37-E063-020011AC0285"`
    @Sendable
    func show(_: Request, context: Context) async throws -> Park? {
        let id = try context.parameters.require("id", as: String.self)
        let guid = id.replacingOccurrences(of: "-", with: "")

        return try await client.withConnection { conn in
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
                WHERE id = HEXTORAW(\(guid))
                """,
                logger: logger)

            for try await (id, name, address, latitude, longitude) in rows
                .decode((UUID, String, String, Double, Double).self)
            {
                return Park(id: id,
                            name: name,
                            address: address,
                            coordinates: Park.Coordinates(latitude: latitude,
                                                          longitude: longitude))
            }
            return nil
        }
    }

    // MARK: - filter

    /// Search all parks withint the given distance
    /// Usage: curl -X "POST" "http://localhost:8080/api/v1/parks/filter" \
    ///              -H 'Content-Type: application/json' \
    ///              -d $'{
    ///                     "userPosition": {
    ///                                       "longitude": 14.411944,
    ///                                        "latitude": 50.086389
    ///                      },
    ///                     "distance": 0.27,
    ///                     "unit": "mile"
    ///         }'
    @Sendable
    func filter(_ request: Request, context: Context) async throws -> [Park] {
        let filter = try await request.decode(as: Filter.self, context: context)
        var parks = [Park]()

        try await client.withConnection { conn in
            let distanceUnitString = "distance=\(filter.distance) unit=\(filter.unit)"
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
                    SDO_GEOMETRY(\(filter.userPosition.latitude),\(filter.userPosition.longitude)),
                    '\(distanceUnitString)'
                  ) = 'TRUE'
                """

            let rows = try await conn.execute(OracleStatement(stringLiteral: query))

            for try await (id, name, address, latitude, longitude) in rows
                .decode((UUID, String, String, Double, Double).self)
            {
                let park = Park(id: id,
                                name: name,
                                address: address, coordinates: Park.Coordinates(latitude: latitude,
                                                                                longitude: longitude))
                parks.append(park)
            }
        }
        return parks
    }
}
