import Foundation
import Hummingbird
import HummingbirdAuth
import HummingbirdBcrypt
import IndiePitcherSwift
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
  let indiePitcher: IndiePitcher
  let logger: Logger

  func addRoutes(to group: RouterGroup<ParksAuthRequestContext>) {
    group
      .post(use: create)
      .post("forgot-password", use: forgotPassword)
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

  // MARK: - forgot password
  /// Forgot password
  @Sendable
  func forgotPassword(_ request: Request, context: ParksAuthRequestContext) async throws -> HTTPResponse.Status {
    let userInput = try await request.decode(as: ForgotPassword.self, context: context)

    // Check if the user exists in the database
    _ = try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
          nickname,
          email,
          password,
          created_at
        FROM
          users
        WHERE email = \(userInput.email)
        """
      )

      let row = try await stream.affectedRows
      if row != 0 {
        for try await (id, nickname, email, password, created_at) in stream.decode((UUID, String, String, String, Date).self) {
          let user = User(
            id: id,
            nickname: nickname,
            email: email,
            password: password,
            createdAt: created_at
          )

          // Generate token and later save it in the forgotten_tokens TABLE
          let token = try Token.generate(for: user)

          guard let userId = user.id?.uuidString.replacingOccurrences(of: "-", with: "") else {
            throw HTTPError(.badRequest)
          }

          // Delete entry from tokens TABLE
          _ = try await client.withConnection { conn in
            let _ = try await conn.execute(
              """
              DELETE from tokens
              WHERE user_id = \(userId)
              """
            )
          }

          let query: OracleStatement =
            "INSERT INTO forgotten_tokens (token_value, user_id) VALUES (\(token.tokenValue), \(userId))"

          _ = try await client.withConnection { conn in
            try await conn.execute(query, logger: logger)
          }

          let emailBody = """
                Ahoj,

                We received a request to reset your password.

                Please, click on the [link](http://localhost:8080/api/v1/users/reset-password?token=\(token.tokenValue))

                This link is valid for **30 minutes**. If you did not request a password reset, please ignore this email—your account remains secure.

                Best regards,
            """

          try await indiePitcher.sendEmail(
            data: .init(
              to: "\(userInput.email)",
              subject: "Reset your password",
              body: emailBody,
              bodyFormat: .markdown
            )
          )
        }
      }
    }

    return .ok
  }
}
