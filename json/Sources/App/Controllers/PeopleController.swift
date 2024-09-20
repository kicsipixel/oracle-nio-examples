import Foundation
import Hummingbird
import Logging
import OracleNIO

struct PeopleController<Context: RequestContext> {
    let client: OracleClient
    let logger: Logger
    
    func addRoutes(to group: RouterGroup<Context>) {
        group
            .get(use: self.index)
    }
    
    /// Lists all the people in the database
    @Sendable
    func index(_: Request, context _: Context) async throws -> [Person] {
        var people = [Person]()
        
        try await client.withConnection { conn in
            let rows = try await conn.execute(
                """
                SELECT * from people
                """,
                logger: logger)
            
           
        }
        return people
    }
}
