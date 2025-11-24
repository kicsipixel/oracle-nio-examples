import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBasicAuth
import HummingbirdBcrypt
import Logging
import OracleNIO

struct UsersController {
  typealias Context = AppRequestContext
  let client: OracleClient
  let logger: Logger

  func addRoutes(to group: RouterGroup<Context>) {
    group
      .post(use: create)
  }

  // MARK: - create
  /// Creates a new user
  @Sendable
  func create(_ request: Request, context: Context) async throws -> EditedResponse<UserResponse> {
    let newUser = try await request.decode(as: CreateUserRequest.self, context: context)
    guard let password = newUser.password else { throw HTTPError(.internalServerError) }
    let hash = Bcrypt.hash(password)

    // Check if the user exits
    _ = try await client.withConnection { conn in
      let stream = try await conn.execute(
        "SELECT * FROM users WHERE email = \(newUser.email)",
        logger: logger
      )

      let existingUsers = try await stream.affectedRows

      if existingUsers > 0 {
        throw HTTPError(.conflict, message: "This email: \(newUser.email) has already registered.")
      }
      else {
        // Create user
        try await conn.execute(
          "INSERT INTO users (name, email, password) VALUES (\(newUser.name), \(newUser.email), \(hash))",
          logger: logger
        )
      }
    }

    let user = try await User(from: newUser)
    return .init(status: .created, response: UserResponse(from: user))
  }
}
