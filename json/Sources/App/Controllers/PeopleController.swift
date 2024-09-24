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
            .get(":id", use: self.show)
            .post("/filter", use: self.filter)
    }
    
    // MARK: - index
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
            
            for try await (id, people_list) in rows.decode((UUID, OracleJSON<Result>).self) {
                let person = Person(id: id,
                                    name: Name(title: people_list.value.name.title,
                                               firstName: people_list.value.name.firstName,
                                               lastName: people_list.value.name.lastName),
                                    email: people_list.value.email,
                                    nationality: people_list.value.nationality,
                                    hobbies: people_list.value.hobbies)
                people.append(person)
            }
        }
        return people
    }
    
    // MARK: - show
    /// Returns a single person with id
    @Sendable
    func show(_: Request, context: Context) async throws -> Person? {
        let id = try context.parameters.require("id", as: String.self)
        let guid = id.replacingOccurrences(of: "-", with: "")
        
        return try await client.withConnection { conn in
            let query =
                  """
                    SELECT
                        id,
                        people_list
                    FROM
                        people
                    WHERE id = '\(guid)'
                  """
            
            let rows = try await conn.execute(OracleStatement(stringLiteral: query), logger: logger)
            
            for try await (id, people_list) in rows.decode((UUID, OracleJSON<Result>).self) {
                return Person(id: id,
                              name: Name(title: people_list.value.name.title,
                                         firstName: people_list.value.name.firstName,
                                         lastName: people_list.value.name.lastName),
                              email: people_list.value.email,
                              nationality: people_list.value.nationality,
                              hobbies: people_list.value.hobbies)
            }
            return nil
        }
    }
    
    
    // MARK: - index
    /// Lists all the people in the database
    @Sendable
    func filter(request: Request, context: Context) async throws -> [Person] {
        let filter = try await request.decode(as: Filter.self, context: context)
        var people = [Person]()
        
        let level1Field = filter.query[0].criteria[0].group[0].conditions[0].field
        let level1Value = filter.query[0].criteria[0].group[0].conditions[0].value
        guard let level1Operator = filter.query[0].criteria[0].group[0].groupOperator else {
            throw HTTPError(.internalServerError)
        }
        
        
        let query =
        """
            SELECT *
             FROM people
             WHERE JSON_VALUE(people_list, '$.\(level1Field)' = '\(level1Value)'
               \(level1Operator) (JSON_VALUE(people_list, '$.nat') = 'DE'
                   );
        """
        
        print(query)
        return people
    }
}
