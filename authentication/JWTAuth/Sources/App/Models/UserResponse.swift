import Foundation
import Hummingbird

struct UserResponse: ResponseCodable {
  let id: UUID?
  let name: String
  let email: String

  init(id: UUID?, name: String, email: String) {
    self.id = id
    self.name = name
    self.email = email
  }

  init(from user: User) {
    self.id = user.id
    self.name = user.name
    self.email = user.email
  }
}
