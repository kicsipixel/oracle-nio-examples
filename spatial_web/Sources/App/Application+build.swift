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

///  Build application
/// - Parameter arguments: application arguments
public func buildApplication(_ arguments: some AppArguments) async throws -> some ApplicationProtocol {
  let environment = Environment()
  let logger = {
    var logger = Logger(label: "spatial_web")
    logger.logLevel =
      arguments.logLevel ?? environment.get("LOG_LEVEL").flatMap { Logger.Level(rawValue: $0) }
      ?? .info
    return logger
  }()

  let router = buildRouter()
  let env = try await Environment.dotEnv()

  // Template library - Mustache
  let library = try await MustacheLibrary(directory: Bundle.module.bundleURL.path)
  assert(library.getTemplate(named: "base") != nil)

  /// Database configuration
  /// Use `docker  run --name oracle23ai -p 1521:1521 -e ORACLE_PWD=OracleIsAwesome container-registry.oracle.com/database/free:latest-lite`
  let config = OracleConnection.Configuration(
    host: env.get("DATABASE_HOST") ?? "127.0.0.1",
    service: .serviceName(env.get("DATABASE_SERVICE_NAME") ?? "FREE"),
    username: env.get("DATABASE_USERNAME") ?? "SYSTEM",
    password: env.get("DATABASE_PASSWORD") ?? "OracleIsAwesome"
  )

  /// Remote Database configuration
  /// Use Connection string: `(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.eu-frankfurt-1.oraclecloud.com))(connect_data=(service_name=gdb965aee735fa8_szabolcstothdb_low.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))`
  // let resourcePath = Bundle.module.bundleURL.path
  // let config = try OracleConnection.Configuration(
  //   host: env.get("REMOTE_DATABASE_HOST") ?? "adb.eu-frankfurt-1.oraclecloud.com",
  //   port: env.get("REMOTE_DATABASE_PORT").flatMap(Int.init(_:)) ?? 1522,
  //   service: .serviceName(env.get("REMOTE_DATABASE_SERVICE_NAME") ?? "service_low.adb.oraclecloud.com"),
  //   username: env.get("REMOTE_DATABASE_USERNAME") ?? "ADMIN",
  //   password: env.get("REMOTE_DATABASE_PASSWORD") ?? "Secr3t",
  //   tls: .require(
  //     .init(
  //       configuration: .makeOracleWalletConfiguration(
  //         wallet: "\(resourcePath)",
  //         walletPassword: env.get("REMOTE_DATABASE_WALLET_PASSWORD") ?? "$ecr3t"
  //       )
  //     )
  //   )
  // )

  let connection = try await OracleConnection.connect(configuration: config, id: 1, logger: logger)

  /// Create the table in the database using the new `IF NOT EXISTS` keyword
  do {
    try await connection.execute(
      """
          CREATE TABLE IF NOT EXISTS spatial (
            id RAW (16) DEFAULT SYS_GUID () PRIMARY KEY,
            coordinates SDO_GEOMETRY,
            details JSON
      )
      """,
      logger: logger
    )
  }
  catch {
    print(String(reflecting: error))
  }

  /// Close your connection once done
  try await connection.close()

  /// Create the Oracle client
  let client = OracleClient(configuration: config, backgroundLogger: logger)

  /// Controller
  WebpagesController(mustacheLibrary: library, client: client, logger: logger).addRoutes(to: router)

  var app = Application(
    router: router,
    configuration: .init(
      address: .hostname(arguments.hostname, port: arguments.port),
      serverName: "spatial_web"
    ),
    logger: logger
  )

  if arguments.seed {
    try await app.seedDatabase(app, config: config)
  }

  app.addServices(client)
  return app
}

/// Build router
func buildRouter() -> Router<HTMLFormRequestContext> {
  let router = Router(context: HTMLFormRequestContext.self)
  // Add middleware
  router.addMiddleware {
    // logging middleware
    LogRequestsMiddleware(.info)
    FileMiddleware()
  }

  // Add /health route
  router.get("/health") { _, _ -> HTTPResponse.Status in
    .ok
  }

  return router
}
