import Foundation
import Hummingbird
import HummingbirdBasicAuth
import HummingbirdBcrypt
import NIOPosix

struct User: PasswordAuthenticatable, @unchecked Sendable {
  let id: UUID?
  let name: String
  let email: String
  let passwordHash: String?
  let createdAt: Date

  init(id: UUID? = nil, name: String, email: String, passwordHash: String? = nil, createdAt: Date = Date()) {
    self.id = id
    self.name = name
    self.email = email
    self.passwordHash = passwordHash
    self.createdAt = createdAt
  }

  init(from userRequest: CreateUserRequest) async throws {
    self.id = nil
    self.name = userRequest.name
    self.email = userRequest.email
    self.createdAt = Date()
    if let passwordHash = userRequest.password {
      self.passwordHash = try await NIOThreadPool.singleton.runIfActive { Bcrypt.hash(passwordHash, cost: 12) }
    }
    else {
      self.passwordHash = nil
    }
  }
}

extension User: ResponseCodable {}
