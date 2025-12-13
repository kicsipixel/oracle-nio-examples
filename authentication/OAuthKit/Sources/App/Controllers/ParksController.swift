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

        let query: OracleStatement = try
            "INSERT INTO parks (coordinates, details) VALUES (SDO_GEOMETRY(\(park.coordinates.latitude), \(park.coordinates.longitude)), \(detailsJSON))"

        _ = try await client.withConnection { conn in
            try await conn.execute(query, logger: logger)
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
                   p.details
                   p.user_id
                FROM
                  parks p
                """, logger: logger
            )

            for try await (id, latitude, longitude, details, user_id) in stream.decode(
                (UUID, Double, Double, OracleJSON<Park.Details>, String).self)
            {
                parks.append(.init(id: id, coordinates: Park.Coordinates(latitude: latitude, longitude: longitude), details: Park.Details(name: details.value.name), userId: user_id))
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
                """, logger: logger
            )

            for try await (id, latitude, longitude, details, user_id) in stream.decode(
                (UUID, Double, Double, OracleJSON<Park.Details>, String).self)
            {
                return Park(
                   id: id, coordinates: Park.Coordinates(latitude: latitude, longitude: longitude), details: Park.Details(name: details.value.name), userId: user_id)
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
        UPDATE parks
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
                DELETE FROM parks
                WHERE id = HEXTORAW(\(guid))
                """,
                logger: logger
            )
            let deletedRows = try await stream.affectedRows
            if deletedRows == 0 {
                return .notFound
            }
            return .ok
        }
    }
}
