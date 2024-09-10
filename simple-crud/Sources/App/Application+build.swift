import Hummingbird
import Logging
import OracleNIO

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable.
/// Any variables added here also have to be added to `App` in App.swift and
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
}

public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "simple-crud")
        logger.logLevel =
            arguments.logLevel ??
            environment.get("LOG_LEVEL").map { Logger.Level(rawValue: $0) ?? .info } ??
            .info
        return logger
    }()

    let router = Router()
    /// Add logging
    router.add(middleware: LogRequestsMiddleware(.info))

    /// Add health endpoint
    /// Checks server health status
    router.get("/health") { _, _ -> HTTPResponse.Status in
        .ok
    }

    /// Database configuration
    /// Use `docker exec -it ora23ai ./setPassword.sh Welcome1` to change thedefault random password
    let config = OracleConnection.Configuration(
        host: "127.0.0.1",
        port: 1522,
        service: .sid("FREE"),
        username: "SYSTEM",
        password: "Welcome1")

    let connection = try await OracleConnection.connect(
        configuration: config,
        id: 1,
        logger: logger)

    /// Create the table in the database using the new `IF NOT EXISTS` keyword
    try await connection.execute(
        """
            CREATE TABLE IF NOT EXISTS parks (
              id RAW (16) DEFAULT SYS_GUID () PRIMARY KEY,
              name VARCHAR2 (100),
              latitude FLOAT,
              longitude FLOAT
        )
        """,
        logger: logger)

    /// Close your connection once done
    try await connection.close()

    /// Create client
    let client = OracleClient(configuration: config, backgroundLogger: logger)

    /// Controller
    ParksController(client: client, logger: logger).addRoutes(to: router.group("api/v1/parks"))

    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "simple-crud"),
        logger: logger)

    app.addServices(client)

    return app
}
