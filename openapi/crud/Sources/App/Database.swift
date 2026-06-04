import Foundation
import Hummingbird
import OracleNIO

struct DatabaseService {
    var configuration: OracleConnection.Configuration?

    // MARK: - Database init
    init(isDevelopment: Bool) async throws {
        let env = (try? await Environment.dotEnv()) ?? Environment()
        if isDevelopment {
            // Local database (container) configuration
            configuration = OracleConnection.Configuration(
                host: env.get("DATABASE_HOST") ?? "127.0.0.1",
                service: .serviceName(env.get("DATABASE_SERVICE_NAME") ?? "FREE"),
                username: env.get("DATABASE_USERNAME") ?? "SYSTEM",
                password: env.get("DATABASE_PASSWORD") ?? "OracleIsAwesome"
            )
        } else {
            // Remote Database configuration
            let resourcePath = Bundle.module.bundleURL.path
            configuration = try OracleConnection.Configuration(
                host: env.get("REMOTE_DATABASE_HOST") ?? "adb.eu-frankfurt-1.oraclecloud.com",
                port: env.get("REMOTE_DATABASE_PORT").flatMap(Int.init(_:)) ?? 1522,
                service: .serviceName(env.get("REMOTE_DATABASE_SERVICE_NAME") ?? "service_low.adb.oraclecloud.com"),
                username: env.get("REMOTE_DATABASE_USERNAME") ?? "ADMIN",
                password: env.get("REMOTE_DATABASE_PASSWORD") ?? "Secr3t",
                tls: .require(
                    .init(
                        configuration: .makeOracleWalletConfiguration(
                            wallet: "\(resourcePath)",
                            walletPassword: env.get("REMOTE_DATABASE_WALLET_PASSWORD") ?? "$ecr3t"
                        )
                    )
                )
            )
        }
    }

    // MARK: - Create connection
    func createConnection() async throws -> OracleConnection? {
        guard let configuration = configuration else {
            throw HTTPError(.internalServerError, message: "Cannot initialize database configuration")
        }

        return try await OracleConnection.connect(configuration: configuration, id: 1)
    }

    // MARK: - Create client
    func createClient() async throws -> OracleClient {
        guard let configuration = configuration else {
            throw HTTPError(.internalServerError, message: "Cannot initialize database configuration")
        }

        return OracleClient(configuration: configuration)
    }
}
