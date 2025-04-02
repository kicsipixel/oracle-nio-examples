import ArgumentParser
import Foundation
import Hummingbird
import OpenAPIHummingbird
import OpenAPIRuntime
import OracleNIO

@main
struct HummingbirdAPIService: AsyncParsableCommand {
  @Option(name: .shortAndLong)
  var hostname = "127.0.0.1"

  @Option(name: .shortAndLong)
  var port = 8080

  func run() async throws {
    let router = Router()
    router.middlewares.add(LogRequestsMiddleware(.info))

    let env = try await Environment.dotEnv()
    /// Database configuration
    /// Use `docker  run --name oracle23ai -p 1521:1521 -e ORACLE_PWD=OracleIsAwesome container-registry.oracle.com/database/free:latest-lite`
    let config = OracleConnection.Configuration(
      host: env.get("DATABASE_HOST") ?? "127.0.0.1",
      service: .serviceName(env.get("DATABASE_SERVICE_NAME") ?? "FREE"),
      username: env.get("DATABASE_USERNAME") ?? "SYSTEM",
      password: env.get("DATABASE_PASSWORD") ?? "OracleIsAwesome"
    )
    
    // Autonomous Database (ADB) configuration
    /// Use your connection String to find the relevant information
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
    //         walletPassword: env.get("REMOTE_DATABASE_WALLET_PASSWORD")
    //           ?? "$ecr3t"
    //       )
    //     )
    //   )
    // )

    let connection = try await OracleConnection.connect(configuration: config, id: 1)

    try await connection.execute(
      """
          CREATE TABLE IF NOT EXISTS pharmacies (
            id                     RAW(16) DEFAULT sys_guid() PRIMARY KEY,
            pharmacy_coordinates   SDO_GEOMETRY,
            details                JSON,
            is_open_sat            BOOLEAN,
            is_open_sun            BOOLEAN,
            is_open_public_holiday BOOLEAN
      )
      """
    )

    try await connection.close()

    let client = OracleClient(configuration: config)

    let api = APIServiceImpl(client: client)
    try api.registerHandlers(on: router)

    var app = Application(
      router: router,
      configuration: .init(address: .hostname(hostname, port: port))
    )

    app.addServices(client)
    try await app.runService()
  }
}
