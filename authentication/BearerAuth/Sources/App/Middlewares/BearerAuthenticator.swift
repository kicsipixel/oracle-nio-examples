import Foundation
import Hummingbird
import HummingbirdAuth
import OracleNIO

struct BearerAuthenticator<Context: AuthRequestContext>: AuthenticatorMiddleware where Context.Identity == User {
  let client: OracleClient

  func authenticate(request: Request, context: Context) async throws -> User? {
    var token: Token?

    guard let bearer = request.headers.bearer else {
      return nil
    }

    // Check if the submitted token exits in the database
    _ = try await client.withConnection { conn in
      let stream = try await conn.execute(
        """
        SELECT
          id,
          token_value,
          user_id,
          created_at
        FROM
          tokens
        WHERE token_value = \(bearer.token)
        """
      )

      for try await (id, token_value, user_id, created_at) in stream.decode((UUID, String, UUID, Date).self) {
        token = Token(id: id, tokenValue: token_value, userId: user_id, createdAt: created_at)
      }
    }

    guard let tokenId = token?.userId.uuidString.replacingOccurrences(of: "-", with: "") else {
      return nil
    }

    return try await client.withConnection { conn in
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
        WHERE id = HEXTORAW(\(tokenId))
        """
      )

      for try await (id, nickname, email, password, created_at) in stream.decode((UUID, String, String, String, Date).self) {
        return User(id: id, nickname: nickname, email: email, password: password, createdAt: created_at)
      }
      return nil
    }
  }
}
