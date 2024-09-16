import Foundation
import Hummingbird
import Logging
import Mustache
import OracleNIO

/// Application arguments protocol. We use a protocol so we can call
/// `buildApplication` inside Tests as well as in the App executable.
/// Any variables added here also have to be added to `App` in App.swift and
/// `TestArguments` in AppTest.swift
public protocol AppArguments {
    var hostname: String { get }
    var port: Int { get }
    var logLevel: Logger.Level? { get }
    var seed: Bool { get }
}

struct HTMLFormRequestContext: RequestContext {
    var coreContext: CoreRequestContextStorage

    init(source: Source) {
        self.coreContext = .init(source: source)
    }

    var requestDecoder: URLFormRequestDecoder { .init() }
}

// Request context used by application
typealias AppRequestContext = BasicRequestContext

public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "spatial-web")
        logger.logLevel =
            arguments.logLevel ??
            environment.get("LOG_LEVEL").map { Logger.Level(rawValue: $0) ?? .info } ??
            .info
        return logger
    }()

    let router = buildRouter()
    // Template library - Mustache
    let library = try await MustacheLibrary(directory: Bundle.module.bundleURL.path)
    assert(library.getTemplate(named: "base") != nil)

    let env = try await Environment.dotEnv()

    /// Database configuration
    /// Use `docker exec -it ora23ai ./setPassword.sh Welcome1` to change thedefault random password
    let config = OracleConnection.Configuration(
        host: env.get("DATABASE_HOST") ?? "127.0.0.1",
        port: 1522,
        service: .sid(env.get("SID") ?? "XE"),
        username: env.get("DATABASE_USERNAME") ?? "SYSTEM",
        password: env.get("DATABASE_PASSWORD") ?? "secr3t")

    let connection = try await OracleConnection.connect(
        configuration: config,
        id: 1,
        logger: logger)

    /// Create the table in the database using the new `IF NOT EXISTS` keyword
    try await connection.execute(
        """
        CREATE TABLE IF NOT EXISTS spatialparks (
            id RAW (16) DEFAULT SYS_GUID () PRIMARY KEY,
        name VARCHAR2 (100),
        address VARCHAR2 (100),
        geometry SDO_GEOMETRY
        )
        """,
        logger: logger)

    /// Close your connection once done
    try await connection.close()

    /// Create the client
    let client = OracleClient(configuration: config, backgroundLogger: logger)

    /// Controller
    ParksController(client: client, logger: logger).addRoutes(to: router.group("api/v1/parks"))
    WebsitesController(mustacheLibrary: library, client: client, logger: logger).addRoutes(to: router)

    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "spatial-web"),
        logger: logger)

    if arguments.seed {
        try await app.seedDatabase(config: config)
    }

    app.addServices(client)

    return app
}

func buildRouter() -> Router<HTMLFormRequestContext> {
    let router = Router(context: HTMLFormRequestContext.self)

    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
        FileMiddleware()
    }

    // Add health endpoint
    router.get("/health") { _, _ -> HTTPResponse.Status in
        .ok
    }

    return router
}
