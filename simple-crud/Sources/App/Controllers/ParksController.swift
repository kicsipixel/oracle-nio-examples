import Foundation
import Hummingbird
import Logging
import OracleNIO

struct ParksController<Context: RequestContext> {
    
    let client: OracleClient
    let logger: Logger
    
    func addRoutes(to group:RouterGroup<Context>) {
        group
            .post(use: self.create)
            .get(use: self.index)
            .get(":id", use: self.show)
            .patch(":id", use: self.update)
            .delete(":id", use: self.delete)
    }
    
    // MARK: - create
    /// Creates a new park with a `name` and `coordinates`
    @Sendable func create(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let park = try await request.decode(as: Park.self, context: context)
        
        try await client.withConnection { conn in
            try await conn.execute(
             """
             INSERT INTO parks (name, latitude, longitude)
                     VALUES(\(park.name), \(park.latitude), \(park.longitude))
             """,
             logger: logger
            )
            
            try await conn.close()
        }
        return .created
    }
    
    // MARK: - index
    /// Lists all the parks in the database
    @Sendable func index(_ request: Request, context: Context) async throws -> [Park] {
        var parks = [Park]()
        
        try await client.withConnection { conn in
            let rows = try await conn.execute(
             """
             SELECT
               id,
               name,
               latitude,
               longitude
             FROM
               parks
             """,
             logger: logger
            )
            
            for try await (id, name, latitude, longitude) in rows.decode((UUID, String, Float, Float).self) {
                let park = Park(id: id,
                                name: name,
                                latitude: latitude,
                                longitude: longitude)
                parks.append(park)
            }
            
            try await conn.close()
        }
        
        return parks
    }
    
    // MARK: - show
    /// Returns a single park with id
    @Sendable func show(_ request: Request, context: Context) async throws -> Park? {
        let id = try context.parameters.require("id", as: String.self)
        let guid = id.replacingOccurrences(of: "-", with: "")
        
        return try await client.withConnection { conn in
            let rows = try await conn.execute(
                    """
                    SELECT
                        id,
                        name,
                        latitude,
                        longitude
                    FROM
                        parks
                    WHERE id = HEXTORAW(\(guid))
                    """,
                    logger: logger
            )
            
            for try await (id, name, latitude, longitude) in rows.decode((UUID, String, Float, Float).self) {
                return Park(id: id,
                            name: name,
                            latitude: latitude,
                            longitude: longitude)
                
            }
            return nil
        }
    }
    
    // MARK: - update
    /// Edits park with id
    @Sendable func update(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let id = try context.parameters.require("id", as: String.self)
        let guid = id.replacingOccurrences(of: "-", with: "")
        let park = try await request.decode(as: Park.self, context: context)
        
        return try await client.withConnection { conn in
            try await conn.execute(
                    """
                    UPDATE parks
                    SET name = \(park.name),
                        latitude = \(park.latitude),
                        longitude = \(park.longitude)
                    WHERE id = HEXTORAW(\(guid))
                    """,
                    logger: logger
            )
            return .ok
        }
    }
    
    // MARK: - delete
    /// Deletes park with id
    @Sendable func delete(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
        let id = try context.parameters.require("id", as: String.self)
        let guid = id.replacingOccurrences(of: "-", with: "")
      
        return try await client.withConnection { conn in
            try await conn.execute(
                    """
                    DELETE FROM parks
                    WHERE id = HEXTORAW(\(guid))
                    """,
                    logger: logger
            )
            return .ok
        }
    }
}
