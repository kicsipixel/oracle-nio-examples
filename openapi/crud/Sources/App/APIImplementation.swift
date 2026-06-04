import AppAPI
import Foundation
import OpenAPIRuntime
import OracleNIO

// MARK: - "Hello"
struct APIImplementation: APIProtocol {
    let client: OracleClient

    func getHello(_ input: AppAPI.Operations.GetHello.Input) async throws -> AppAPI.Operations.GetHello.Output {
        return .ok(.init(body: .plainText("Hello!")))
    }

    // MARK: - Server health
    func getHealth(_: AppAPI.Operations.GetHealth.Input) async throws -> AppAPI.Operations.GetHealth.Output {
        return .ok(.init())
    }

    // MARK: - Park Operations
    /// Creates a park
    /// ```
    /// curl -i -X "POST" "http://localhost:8080/api/v1/parks" \
    ///      -H 'Content-Type: application/json' \
    ///      -d $'{
    ///        "details": {
    ///          "name": "Letenské sady"
    ///        },
    ///        "coordinates": {
    ///          "longitude": 4.4202892,
    ///          "latitude": 50.0959721
    ///        }
    ///      }'
    /// ```
    func createPark(_ input: AppAPI.Operations.CreatePark.Input) async throws -> AppAPI.Operations.CreatePark.Output {
        guard case .json(let park) = input.body,
            let parkDetails = park.details,
            let parkCoordinates = park.coordinates
        else {
            return .badRequest(.init())
        }

        let detailsJSON = OracleJSON(parkDetails)

        let query: OracleStatement = try
            "INSERT INTO parks (coordinates, details) VALUES (SDO_GEOMETRY(\(parkCoordinates.latitude), \(parkCoordinates.longitude)), \(detailsJSON))"

        _ = try await client.withConnection { conn in
            try await conn.execute(query)
        }

        return .created(.init())
    }

    /// Retrieves all parks
    /// ```
    /// curl -i http://localhost:8080/api/v1/parks
    /// ```
    func getAllParks(_ input: AppAPI.Operations.GetAllParks.Input) async throws -> AppAPI.Operations.GetAllParks.Output {
        var parks = [Components.Schemas.Park]()

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

            for try await (id, latitude, longitude, details) in stream.decode(
                (UUID, Double, Double, OracleJSON<Components.Schemas.Park.DetailsPayload>).self
            ) {
                parks.append(
                    .init(
                        id: "\(id)",
                        details: details.value,
                        coordinates: .init(latitude: latitude, longitude: longitude)
                    )
                )
            }
        }

        return .ok(.init(body: .json(parks)))
    }

    /// Retrieves a park by id
    /// ```
    /// curl -i http://localhost:8080/api/v1/parks/535B2001-FBD4-0B23-E063-03D7A8C0763D
    /// ```
    func getParkById(_ input: AppAPI.Operations.GetParkById.Input) async throws -> AppAPI.Operations.GetParkById.Output {
        /// Oracle GUID and UUID are tno the same, since GUID has no dashes.
        let guid = input.path.id.replacingOccurrences(of: "-", with: "")

        return try await client.withConnection { conn in
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

            for try await (id, latitude, longitude, details) in stream.decode(
                (UUID, Double, Double, OracleJSON<Components.Schemas.Park.DetailsPayload>).self
            ) {
                return .ok(
                    .init(
                        body: .json(
                            Components.Schemas.Park(
                                id: "\(id)",
                                details: details.value,
                                coordinates: .init(latitude: latitude, longitude: longitude)
                            )
                        )
                    )
                )
            }

            return .notFound(.init())
        }
    }

    /// Updates a park by id
    /// ```
    /// curl -X "PUT" "http://localhost:8080/api/v1/parks/535B2001-FBD4-0B23-E063-03D7A8C0763D" \
    ///     -H 'Content-Type: application/json' \
    ///     -d $'{
    ///       "details": {
    ///         "name": "Žernosecká - Čumpelíkova"
    ///       },
    ///       "coordinates": {
    ///         "longitude": 4.4202892,
    ///         "latitude": 50.0959721
    ///       }
    ///     }'
    /// ```
    func updateParkById(_ input: AppAPI.Operations.UpdateParkById.Input) async throws -> AppAPI.Operations.UpdateParkById.Output {
        /// Oracle GUID and UUID are tno the same, since GUID has no dashes.
        let guid = input.path.id.replacingOccurrences(of: "-", with: "")

        guard case .json(let park) = input.body,
            let parkDetails = park.details,
            let parkCoordinates = park.coordinates
        else {
            return .badRequest(.init())
        }

        let detailsJSON = OracleJSON(parkDetails)
        let query: OracleStatement = try """
        UPDATE parks
        SET coordinates = SDO_GEOMETRY(\(parkCoordinates.latitude), \(parkCoordinates.longitude)),
            details = \(detailsJSON)
        WHERE id = HEXTORAW(\(guid))
        """

        return try await client.withConnection { conn in
            let stream = try await conn.execute(query)
            let updatedRows = try await stream.affectedRows
            if updatedRows == 0 {
                return .notFound(.init())
            }

            return .ok(.init())
        }
    }

    /// Deletes a park by ID
    /// ```
    /// curl -X "DELETE" "http://localhost:8080/api/v1/parks/535B2001-FBD4-0B23-E063-03D7A8C0763D"
    /// ```
    func deleteParkById(_ input: AppAPI.Operations.DeleteParkById.Input) async throws -> AppAPI.Operations.DeleteParkById.Output {
        // Oracle GUID and UUID are tno the same, since GUID has no dashes.
        let guid = input.path.id.replacingOccurrences(of: "-", with: "")

        let query: OracleStatement =
            """
            DELETE FROM parks
            WHERE id = HEXTORAW(\(guid))
            """

        return try await client.withConnection { conn in
            let stream = try await conn.execute(query)
            let deletedRows = try await stream.affectedRows
            if deletedRows == 0 {
                return .notFound(.init())
            }

            return .noContent(.init())
        }
    }
}
