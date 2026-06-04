import Configuration
import Hummingbird
import Logging
import OpenAPIHummingbird
import OracleNIO

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter reader: configuration reader
func buildApplication(reader: ConfigReader) async throws -> some ApplicationProtocol {
    let logger = {
        var logger = Logger(label: "crud")
        logger.logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)
        return logger
    }()

    let isDevelopment = reader.bool(forKey: "development", default: false)

    // MARK: - Database setup
    let databaseService = try await DatabaseService(isDevelopment: isDevelopment)
    let client = try await databaseService.createClient()
    if let connection = try await databaseService.createConnection() {
        /// Create the table in the database using the new `IF NOT EXISTS` keyword
        do {
            try await connection.execute(
                """
                    CREATE TABLE IF NOT EXISTS parks (
                      id RAW (16) DEFAULT SYS_GUID () PRIMARY KEY,
                      coordinates SDO_GEOMETRY NOT NULL,
                      details JSON NOT NULL
                )
                """,
                logger: logger
            )
        } catch {
            print(String(reflecting: error))
        }

        /// Close your connection once done
        try await connection.close()
    }

    let router = try buildRouter(client: client)
    var app = Application(
        router: router,
        configuration: ApplicationConfiguration(reader: reader.scoped(to: "http")),
        logger: logger
    )
    app.addServices(client)
    return app
}

/// Build router
func buildRouter(client: OracleClient) throws -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
        // store request context in TaskLocal
        OpenAPIRequestContextMiddleware()
    }
    // Add OpenAPI handlers
    let api = APIImplementation(client: client)
    try api.registerHandlers(on: router)
    return router
}
