import Foundation
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
    var seed: Bool { get }
}

// Request context used by application
typealias AppRequestContext = BasicRequestContext

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
    let environment = Environment()
    let logger = {
        var logger = Logger(label: "template")
        logger.logLevel =
            arguments.logLevel ??
            environment.get("LOG_LEVEL").map { Logger.Level(rawValue: $0) ?? .info } ??
            .info
        return logger
    }()
    let router = buildRouter()

    let env = try await Environment.dotEnv()
    let resourcePath = Bundle.module.bundleURL.path

    /// Database configuration
    /// Use your connection String to find the relevant information:
    /// (description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.eu-frankfurt-1.oraclecloud.com))(connect_data=(service_name=gdb965aee735fa8_szabolcstothdb_low.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))
    let config = try OracleConnection.Configuration(
        host: env.get("DATABASE_HOST") ?? "adb.eu-frankfurt-1.oraclecloud.com",
        port: env.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 1522,
        service: .serviceName(env.get("DATABASE_SERVICE_NAME") ?? "service_low.adb.oraclecloud.com"),
        username: env.get("DATABASE_USERNAME") ?? "ADMIN",
        password: env.get("DATABASE_PASSWORD") ?? "Secr3t",
        tls: .require(.init(configuration: .makeOracleWalletConfiguration(
            wallet: "\(resourcePath)",
            walletPassword: env.get("DATABASE_WALLET_PASSWORD") ?? "$ecr3t"))))

    let connection = try await OracleConnection.connect(configuration: config, id: 1)

    try await connection.execute(
        """
         CREATE TABLE IF NOT EXISTS people (
            id RAW (16) DEFAULT sys_guid () PRIMARY KEY,
        people_list json)
        """,
        logger: logger)

    try await connection.close()

    let client = OracleClient(configuration: config, backgroundLogger: logger)
    PeopleController(client: client, logger: logger).addRoutes(to: router.group("api/v1/people"))
    
    var app = Application(
        router: router,
        configuration: .init(
            address: .hostname(arguments.hostname, port: arguments.port),
            serverName: "template"),
        logger: logger)

    if arguments.seed {
        try await app.seedDatabase(app, config: config)
    }
    
    app.addServices(client)
    return app
}

/// Build router
func buildRouter() -> Router<AppRequestContext> {
    let router = Router(context: AppRequestContext.self)
    // Add middleware
    router.addMiddleware {
        // logging middleware
        LogRequestsMiddleware(.info)
    }
    // Add health endpoint
    router.get("/health") { _, _ -> HTTPResponse.Status in
        .ok
    }
    return router
}

