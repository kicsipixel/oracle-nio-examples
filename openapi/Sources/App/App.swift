import ArgumentParser
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

    /// Remote Database configuration
    /// Use Connection string: `(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.eu-frankfurt-1.oraclecloud.com))(connect_data=(service_name=gdb965aee735fa8_szabolcstothdb_low.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))`
    // let resourcePath = Bundle.module.bundleURL.path
    // let config = try OracleConnection.Configuration(
    //   host: env.get("REMOTE_DATABASE_HOST") ?? "adb.eu-frankfurt-1.oraclecloud.com",
    //   port: env.get("REMOTE_DATABASE_PORT").flatMap(Int.init(_:)) ?? 1522,
    //   service: .serviceName(
    //     env.get("REMOTE_DATABASE_SERVICE_NAME") ?? "service_low.adb.oraclecloud.com"
    //   ),
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

    let connection = try await OracleConnection.connect(configuration: config, id: 1)

    do {
      try await connection.execute(
        """
            CREATE TABLE IF NOT EXISTS openapi_parks (
            id RAW (16) DEFAULT SYS_GUID () PRIMARY KEY,
            name VARCHAR2(50),
            coordinates SDO_GEOMETRY
        )
        """
      )
    }
    catch {
      print(String(reflecting: error))
    }

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
