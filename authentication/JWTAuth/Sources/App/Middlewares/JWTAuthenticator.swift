import Foundation
import Hummingbird
import HummingbirdAuth
import JWTKit

struct JWTPayloadData: JWTPayload, Equatable {
  enum CodingKeys: String, CodingKey {
    case subject = "sub"
    case expiration = "exp"
    case name, email
  }

  var subject: SubjectClaim
  var expiration: ExpirationClaim
  // Define additional JWT Attributes here
  var name: String
  var email: String

  func verify(using algorithm: some JWTAlgorithm) async throws {
    try self.expiration.verifyNotExpired()
  }
}

struct JWTAuthenticator: AuthenticatorMiddleware, @unchecked Sendable {
  typealias Context = AppRequestContext
  let jwtKeyCollection: JWTKeyCollection

  init(jwtKeyCollection: JWTKeyCollection) {
    self.jwtKeyCollection = jwtKeyCollection
  }

  func authenticate(request: Request, context: Context) async throws -> User? {
    // Gets JWT from bearer authorisation
    guard let jwtToken = request.headers.bearer?.token else { throw HTTPError(.unauthorized) }

    // Gets payload and verify its contents
    let payload: JWTPayloadData
    do {
      payload = try await self.jwtKeyCollection.verify(jwtToken, as: JWTPayloadData.self)
    }
    catch {
      context.logger.debug("couldn't verify token")
      throw HTTPError(.unauthorized)
    }
    // Gets user id and name from payload
    guard let userUUID = UUID(uuidString: payload.subject.value) else {
      context.logger.debug("Invalid JWT subject \(payload.subject.value)")
      throw HTTPError(.unauthorized)
    }
    return User(id: userUUID, name: payload.name, email: payload.email, passwordHash: nil)
  }
}
