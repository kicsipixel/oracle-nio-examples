import ArgumentParser
import Foundation
import Hummingbird
import OpenAPIHummingbird
import OpenAPIRuntime
import OracleNIO

@main
struct HummingbirdArguments: AsyncParsableCommand {
  @Option(name: .shortAndLong)
  var hostname = "127.0.0.1"
  
  @Option(name: .shortAndLong)
  var port = 8080
  
  func run() async throws {
    let router = Router()
    router.middlewares.add(LogRequestsMiddleware(.info))
    
    let env = try await Environment.dotEnv()
    let resourcePath = Bundle.module.bundleURL.path
    
      /// Database configuration
      /// Use your connection String to find the relevant information
    let config = try OracleConnection.Configuration(
      host: env.get("DATABASE_HOST") ?? "adb.eu-frankfurt-1.oraclecloud.com",
      port: env.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? 1522,
      service: .serviceName(env.get("DATABASE_SERVICE_NAME") ?? "service_low.adb.oraclecloud.com"),
      username: env.get("DATABASE_USERNAME") ?? "ADMIN",
      password: env.get("DATABASE_PASSWORD") ?? "Secr3t",
      tls: .require(
        .init(
          configuration: .makeOracleWalletConfiguration(
            wallet: "\(resourcePath)",
            walletPassword: env.get("DATABASE_WALLET_PASSWORD")
            ?? "$ecr3t"
          )
        )
      )
    )
    
    let connection = try await OracleConnection.connect(
      configuration: config,
      id: 1
    )
    
    try await connection.execute(
      """
          CREATE TABLE IF NOT EXISTS openapi_parks (
          id RAW (16) DEFAULT SYS_GUID () PRIMARY KEY,
          name VARCHAR2(50),
          coordinates SDO_GEOMETRY
      )
      """
    )
    
    try await connection.close()
    
    let client = OracleClient(configuration: config)
    let api = APIServiceImpl(client: client)
    
    try api.registerHandlers(on: router)
    
    let app = Application(
      router: router,
      configuration: .init(address: .hostname(hostname, port: port))
    )
    
    try await withThrowingDiscardingTaskGroup { group in
      group.addTask {
        await client.run()
      }
      group.addTask {
        try await app.runService()
      }
    }
  }
}
