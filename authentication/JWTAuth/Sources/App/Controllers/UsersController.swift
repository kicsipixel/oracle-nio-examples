import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBasicAuth
import HummingbirdBcrypt
import JWTKit
import Logging
import OracleNIO

struct UsersController {
  typealias Context = AppRequestContext
  let client: OracleClient
  let logger: Logger
  let jwtKeyCollection: JWTKeyCollection
  let kid: JWKIdentifier

  func addRoutes(to group: RouterGroup<Context>) {
    group
      .post(use: create)
    group.group("login").add(
      middleware: BasicAuthenticator { username, _ in
        return try await client.withConnection { conn in
          let stream = try await conn.execute(
            "SELECT id, name, email, password FROM users WHERE email = \(username)",
            logger: logger
          )
          for try await (id, name, email, password) in stream.decode((UUID, String, String, String).self) {
            return User(id: id, name: name, email: email, passwordHash: password)
          }
          return nil
        }
      }
    )
    .post(use: login)
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

  // MARK: - login
  /// Logins user and return JWT
  @Sendable
  func login(_ request: Request, context: Context) async throws -> [String: String] {
    guard let user = context.identity else { throw HTTPError(.unauthorized, message: "Autnetication failed. Try again.") }
    guard let userId = user.id?.uuidString else { throw HTTPError(.unprocessableContent) }
    let payload = JWTPayloadData(
      subject: .init(value: userId),
      expiration: .init(value: Date(timeIntervalSinceNow: 12 * 60 * 60)),  // 12 hours
      name: user.name,
      email: user.email
    )
    return try await [
      "token": self.jwtKeyCollection.sign(payload, kid: self.kid)
    ]
  }
}
