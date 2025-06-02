import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBcrypt
import Logging
import OracleNIO

struct UsersController {

  struct UserContext: ChildRequestContext {
    var coreContext: CoreRequestContextStorage
    var user: User

    init(context: ParksAuthRequestContext) throws {
      self.coreContext = context.coreContext
      self.user = try context.requireIdentity()
    }
  }

  let client: OracleClient
  let logger: Logger

  func addRoutes(to group: RouterGroup<ParksAuthRequestContext>) {
    group
      .post(use: create)
    group
      .add(middleware: IsAuthenticatedMiddleware())
      .group(context: UserContext.self)
      .post("login", use: login)
      .delete("logout", use: logout)
  }

  // MARK: - create
  /// Creates a new user
  @Sendable
  func create(_ request: Request, context: ParksAuthRequestContext) async throws -> HTTPResponse.Status {
    let user = try await request.decode(as: User.self, context: context)
    let securePassword = Bcrypt.hash(user.password)

    let query: OracleStatement =
      "INSERT INTO users (nickname, email, password) VALUES (\(user.nickname), \(user.email), \(securePassword))"

    _ = try await client.withConnection { conn in
      try await conn.execute(query, logger: logger)
    }

    return .created
  }

  // MARK: - login
  /// Login user
  @Sendable func login(_ request: Request, context: UserContext) async throws -> Token {
    let user = context.user
    guard let userId = context.user.id?.uuidString.replacingOccurrences(of: "-", with: "") else {
      throw HTTPError(.badRequest, message: "User does not exist")
    }

    // Check if there is token already associated with the current user
    _ = try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id
        FROM
          tokens
        WHERE user_id = HEXTORAW(\(userId))
        """
      )

      if try await stream.decode((UUID).self).first(where: { _ in true }) != nil {
        throw HTTPError(.conflict, message: "You have already logged in")
      }
    }

    let token = try Token.generate(for: user)

    let query: OracleStatement =
      "INSERT INTO tokens (token_value, user_id) VALUES (\(token.tokenValue), \(userId))"

    _ = try await client.withConnection { conn in
      try await conn.execute(query, logger: logger)
    }

    return token
  }

  // MARK: - logout
  /// Logout user
  @Sendable func logout(_ request: Request, context: UserContext) async throws -> HTTPResponse.Status {

    guard let bearer = request.headers.bearer else {
      throw HTTPError(.badRequest, message: "The request doesn't contain the token.")
    }

    return try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        DELETE from tokens
        WHERE token_value = \(bearer.token)
        """,
        logger: logger
      )
      let deletedRows = try await stream.affectedRows
      if deletedRows == 0 {
        throw HTTPError(.badRequest, message: "You are not logged in.")
      }
      return .ok
    }
  }
}
