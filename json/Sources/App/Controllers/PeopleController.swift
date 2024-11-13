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
                SELECT id, people_list from people
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
    
    
    // MARK: - filter
    /// Filters people in the database based on criterias
    /// Usage: curl -X "POST" "http://localhost:8080/api/v1/people/filter" \
    ///    -H 'Content-Type: application/json' \
    ///    -d $'{
    /// "query": [
    ///   {
    ///     "operator": "AND",
    ///     "conditions": [
    ///       {
    ///         "key": "hobbies",
    ///         "value": "running"
    ///       },
    ///       {
    ///         "key": "nat",
    ///         "value": "NL"
    ///       },
    ///       {
    ///         "key": "hobbies",
    ///         "value": "movies"
    ///       }
    ///     ]
    ///   }
    /// ]
    ///}'
    ///
    ///
    ///
    ///
    @Sendable
    func filter(request: Request, context: Context) async throws -> [Person] {
        let filter = try await request.decode(as: Filter.self, context: context)
        var people = [Person]()
      
        return try await client.withConnection { conn in
            if filter.query.count == 1 {
                let conditions = filter.query[0].conditions
                if conditions.count >= 1 {
                    var query = """
                    SELECT *
                    FROM people
                    WHERE
                    """
                    
                    for (index, condition) in conditions.enumerated() {
                        if index > 0 {
                            query += " \(filter.query[0].queryOperator) "
                        }
                        if condition.key == "hobbies" {
                            let hobbies = condition.value.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
                            let hobbiesConditions = hobbies.map { " JSON_EXISTS(people_list, '$.hobbies[*]?(@ == \"\($0)\")')" }
                            query += hobbiesConditions.joined(separator: " AND ")
                        } else {
                            query += " JSON_VALUE(people_list, '$.\(condition.key)') = '\(condition.value)'"
                        }
                    }
                    
                    let rows = try await conn.execute(OracleStatement(stringLiteral: query), logger: logger)
                    
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
                    
                    return people
                } else {
                    throw HTTPError(.badRequest, message: "Invalid filter: conditions must contain 1 or more elements.")
                }
            } else {
                throw HTTPError(.badRequest, message: "Invalid filter: query must contain 1 condition.")
            }
        }
    }
}



