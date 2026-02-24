import Configuration
import CSSSetup
import Foundation
import Hummingbird
import HummingbirdElementary
import Logging
import OracleNIO
import SwiftKaze

// HTMLFormRequestContext
struct HTMLFormRequestContext: RequestContext {
  var coreContext: CoreRequestContextStorage

  init(source: Source) {
    self.coreContext = .init(source: source)
  }
  var requestDecoder: URLFormRequestDecoder { .init() }
}

///  Build application
/// - Parameter reader: configuration reader
func buildApplication(reader: ConfigReader) async throws -> some ApplicationProtocol {
  let logger = {
    var logger = Logger(label: "elementary-swift")
    logger.logLevel = reader.string(forKey: "log.level", as: Logger.Level.self, default: .info)
    return logger
  }()
  let router = try buildRouter()

    // Compile CSS
    guard let inputURL = Bundle.module.url(forResource: "app", withExtension: "css") else {
          throw HTTPError(.notFound, message: "File not found.")
    }
    let outputURL = URL(fileURLWithPath: "public/styles/app.css")

    try await CSSSetup.compileCSS(
        input: inputURL,
        output: outputURL,
        skipIfNotWritable: true
    )

  // Database configuration
  let env = try await Environment.dotEnv()

  // Use `docker  run --name oracle26ai -p 1521:1521 -e ORACLE_PWD=OracleIsAwesome container-registry.oracle.com/database/free:latest-lite`
  let config = OracleConnection.Configuration(
    host: env.get("DATABASE_HOST") ?? "127.0.0.1",
    service: .serviceName(env.get("DATABASE_SERVICE_NAME") ?? "FREE"),
    username: env.get("DATABASE_USERNAME") ?? "SYSTEM",
    password: env.get("DATABASE_PASSWORD") ?? "OracleIsAwesome"
  )

  let connection = try await OracleConnection.connect(configuration: config, id: 1, logger: logger)

  /// Create the table in the database using the new `IF NOT EXISTS` keyword
  do {
    try await connection.execute(
      """
          CREATE TABLE IF NOT EXISTS parks (
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

  // Close your connection once done
  try await connection.close()

  let client: OracleClient = OracleClient(configuration: config, backgroundLogger: logger)

  PagesController(client: client, logger: logger).addRoutes(to: router.group())

  var app = Application(
    router: router,
    configuration: ApplicationConfiguration(reader: reader.scoped(to: "http")),
    logger: logger
  )

  app.addServices(client)
  return app
}

/// Build router
func buildRouter() throws -> Router<HTMLFormRequestContext> {
  let router = Router(context: HTMLFormRequestContext.self)
  // Add middleware
  router.addMiddleware {
    LogRequestsMiddleware(.info)
    FileMiddleware()
  }

  return router
}
