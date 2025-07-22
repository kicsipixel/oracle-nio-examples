import Foundation
import Hummingbird
import HummingbirdBcrypt
import Logging
import Mustache
import OracleNIO

struct PagesController {

  struct HTML: ResponseGenerator {
    let html: String

    public func response(from request: Request, context: some RequestContext) throws -> Response {
      let buffer = ByteBuffer(string: self.html)
      return .init(status: .ok, headers: [.contentType: "text/html"], body: .init(byteBuffer: buffer))
    }
  }

  let client: OracleClient
  let mustacheLibrary: MustacheLibrary

  func addRoutes(to group: RouterGroup<ParksAuthRequestContext>) {
    group
      .get("reset-password", use: resetPassword)
      .post("reset-password", use: resetPostPassword)
  }

  @Sendable
  func resetPassword(request: Request, context: ParksAuthRequestContext) async throws -> HTML {
    var template: String = "valid_token"
    let queryParams = request.uri.queryParameters
    guard let token = queryParams["token"] else {
      throw HTTPError(.badRequest, message: "Failed to identify your token.")
    }

    // Check is the token exists in the database
    _ = try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
          token_value,
          user_id,
          created_at
        FROM
          forgotten_tokens
        WHERE token_value = \(String(token))
        """
      )

      let row = try await stream.affectedRows
      if row != 0 {
        // Check if the token still valid
        for try await (id, token_value, user_id, created_at) in stream.decode((UUID, String, UUID, Date).self) {
          let token = Token(id: id, tokenValue: token_value, userId: user_id, createdAt: created_at)
          // Invalid token will be deleted
          if token.createdLessThanHalfAnHour == false {
            template = "invalid_token"
            _ = try await client.withConnection { conn in
              _ = try await conn.execute(
                """
                DELETE FROM forgotten_tokens
                WHERE token_value = \(token.tokenValue)
                """
              )
            }
          }
        }
      }
      // The token doesn't exist in the database. Either already deleted or fake.
      else {
        template = "invalid_token"
      }
    }

    let context = ResetPasswordContext(tokenValue: String(token))
    guard let html = self.mustacheLibrary.render(context, withTemplate: template) else {
      throw HTTPError(.internalServerError, message: "Failed to render the template.")
    }

    return HTML(html: html)
  }

  @Sendable func resetPostPassword(request: Request, context: ParksAuthRequestContext) async throws -> HTML {
    var template = "ok"

    let data = try await request.decode(as: FormData.self, context: context)

    if data.password != data.confirmPassword {
      template = "password_error"
    }

    _ = try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          user_id
        FROM
          forgotten_tokens
        WHERE token_value = \(data.tokenValue)
        """
      )

      for try await (user_id) in stream.decode((UUID).self) {
        let guid = user_id.uuidString.replacingOccurrences(of: "-", with: "")
        let securePassword = Bcrypt.hash(data.password)

        _ = try await client.withConnection { conn in
          let stream = try await conn.execute(
            """
            UPDATE users
            SET password = \(securePassword)
            WHERE id = HEXTORAW(\(guid))
            """
          )

          let updatedRows = try await stream.affectedRows
          if updatedRows == 0 {
            template = "database_error"
          }
        }
      }
    }

    guard let html = self.mustacheLibrary.render(context, withTemplate: template) else {
      throw HTTPError(.internalServerError, message: "Failed to render the template.")
    }

    return HTML(html: html)
  }
}
