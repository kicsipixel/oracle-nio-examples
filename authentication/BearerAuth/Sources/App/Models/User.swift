import Foundation
import Hummingbird

struct User {
  let id: UUID?
  let nickname: String
  let email: String
  let password: String
  let createdAt: Date?
}

extension User: ResponseCodable {}
