import Hummingbird
import HummingbirdAuth
import HummingbirdBcrypt
import Logging
import OracleNIO

struct UsersController<Context: RequestContext> {
  let client: OracleClient
  let logger: Logger

  func addRoutes(to group: RouterGroup<Context>) {
    group
      .post(use: create)
  }

  // MARK: - create
  /// Creates a new user
  @Sendable
  func create(_ request: Request, context: Context) async throws -> HTTPResponse.Status {
    let user = try await request.decode(as: User.self, context: context)
    let securePassword = Bcrypt.hash(user.password)

    let query: OracleStatement =
      "INSERT INTO users (nickname, email, password) VALUES (\(user.nickname), \(user.email), \(securePassword))"

    _ = try await client.withConnection { conn in
      try await conn.execute(query, logger: logger)
    }

    return .created
  }
}
